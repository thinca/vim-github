" An interface for Github.
" Version: 0.1.0
" Author : thinca <thinca+vim@gmail.com>
" License: Creative Commons Attribution 2.1 Japan License
"          <http://creativecommons.org/licenses/by/2.1/jp/deed.en>

let s:save_cpo = &cpo
set cpo&vim

let s:domain = 'github.com'
let s:base_path = '/api/v2/json'



let s:prototype = {}  " {{{1
function! s:prototype.new(...)  " {{{2
  let obj = copy(self)
  call call(obj.initialize, a:000, obj)
  return obj
endfunction
function! s:prototype.initialize()  " {{{2
endfunction
function! s:prototype.opened()  " {{{2
endfunction
function! s:prototype.header()  " {{{2
  return ''
endfunction
function! s:prototype.view(with, ...)  " {{{2
  let ft = 'github-' . self.name
  let bufnr = 0
  for i in range(0, winnr('$'))
    let n = winbufnr(i)
    if getbufvar(n, '&filetype') ==# ft
      if i != 0
        execute i 'wincmd w'
      endif
      let bufnr = n
      break
    endif
  endfor

  if bufnr == 0
    " TODO: Opener is made customizable.
    new
    let b:github_{self.name} = self

    setlocal nobuflisted
    setlocal buftype=nofile noswapfile bufhidden=wipe
    setlocal nonumber nolist nowrap
    let &l:filetype = ft

    call self.opened()
  else
    setlocal modifiable noreadonly
    silent % delete _
  endif

  let b:github_{self.name}_view = a:with
  silent 0put =self.header()
  silent $put =call(self['view_' . a:with], a:000, self)

  setlocal nomodifiable readonly
  1
endfunction



" Features manager.  {{{1
let s:features = {}

function! github#register(feature)  " {{{2
  let feature = extend(copy(s:prototype), a:feature)
  let s:features[feature.name] = feature
endfunction


" Interfaces.  {{{1
function! github#connect(path, ...)  " {{{2
  let params = {}
  let path = a:path
  let raw = 0
  for a in a:000
    if type(a) == type(0)
      raw = a
    elseif type(a) == type('')
      let path .= '/' . a
    elseif type(a) == type({})
      call extend(params, a)
    endif
  endfor

  let protocol = g:github#use_https ? 'https' : 'http'

  let files = []

  try
    let param = printf('-F "login=%s" -F "token=%s"',
    \                  g:github#user, g:github#token)

    for [key, val] in items(params)
      let f = tempname()
      call add(files, f)
      call writefile(split(val, "\n"), f)
      let param .= printf(' -F "%s=<%s"', key, f)
    endfor

    let res = system(printf('%s -s %s %s://%s%s%s',
    \ g:github#curl_cmd, param,
    \ protocol, s:domain, s:base_path, path))
  finally
    for f in files
      call delete(f)
    endfor
  endtry

  let r = iconv(res, 'utf-8', &encoding)
  if r != ''
    let res = r
  endif

  return raw ? res : s:parse_json(res)
endfunction



function! github#button()  " {{{2
  return github#get_text_on_cursor('\[\[.\{-}\]\]')
endfunction



function! github#get_text_on_cursor(pat)  " {{{2
  let line = getline('.')
  let pos = col('.')
  let s = 0
  while s < pos
    let [s, e] = [match(line, a:pat, s), matchend(line, a:pat, s)]
    if s < 0
      break
    elseif s < pos && pos <= e
      return line[s : e - 1]
    endif
    let s += 1
  endwhile
  return ''
endfunction



" Main commands.  {{{1
function! github#invoke(argline)  " {{{2
  " The simplest implementation.
  let [feat; args] = split(a:argline, '\s\+')
  if !has_key(s:features, feat)
    echohl ErrorMsg
    echomsg 'github: Specified feature is not registered: ' . feat
    echohl None
    return
  endif
  call s:features[feat].invoke(args)
endfunction



function! github#complete(lead, cmd, pos)  " {{{2
  return keys(s:features)
endfunction



" JSON Utilities.  {{{1
function! s:validate_json(str)  " {{{2
  " Reference: http://mattn.kaoriya.net/software/javascript/20100324023148.htm

  let str = a:str
  let str = substitute(str, '\\\%(["\\/bfnrt]\|u[0-9a-fA-F]\{4}\)', '\@', 'g')
  let str = substitute(str, '"[^\"\\\n\r]*\"\|true\|false\|null\|-\?\d\+' .
  \                    '\%(\.\d*\)\?\%([eE][+\-]\{-}\d\+\)\?', ']', 'g')
  let str = substitute(str, '\%(^\|:\|,\)\%(\s*\[\)\+', '', 'g')
  return str =~ '^[\],:{} \t\n]*$'
endfunction



function! s:parse_json(json)  " {{{2
  if !s:validate_json(a:json)
    throw 'github: Invalid json.'
  endif
  let l:true = 1
  let l:false = 0
  let l:null = 0
  return eval(a:json)
endfunction



" Options.  {{{1
if !exists('g:github#user')  " {{{2
  let g:github#user =
  \   matchstr(system('git config --global github.user'), '\w*')
endif

if !exists('g:github#token')  " {{{2
  let g:github#token =
  \   matchstr(system('git config --global github.token'), '\w*')
endif

if !exists('g:github#curl_cmd')  " {{{2
  let g:github#curl_cmd = 'curl'
endif

if !exists('g:github#use_https')  " {{{2
  let g:github#use_https = 0
endif



" Register the default features. {{{1
function! s:register_defaults()  " {{{2
  let list = split(globpath(&runtimepath, 'autoload/github/*.vim'), "\n")
  for name in map(list, 'fnamemodify(v:val, ":t:r")')
    try
      call github#register(github#{name}#new())
    catch /:E\%(117\|716\):/
    endtry
  endfor
endfunction

call s:register_defaults()



let &cpo = s:save_cpo
unlet s:save_cpo
