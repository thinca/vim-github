" An interface for Github.
" Version: 0.1.0
" Author : thinca <thinca+vim@gmail.com>
" License: Creative Commons Attribution 2.1 Japan License
"          <http://creativecommons.org/licenses/by/2.1/jp/deed.en>

let s:save_cpo = &cpo
set cpo&vim

let s:domain = 'github.com'
let s:base_path = '/api/v2/json'


" Features manager.  {{{1
let s:features = {}

function! github#register(feature)  " {{{2
  let s:features[a:feature.name] = a:feature
endfunction


" Interfaces.  {{{1
function! github#connect(path, ...)  " {{{2
  let params = {}
  let raw = 0
  for a in a:000
    if type(a) == type(0)
      raw = a
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
      let param .= printf(' -F "%s=@%s"', key, f)
    endfor

    let res = system(printf('%s -s %s %s://%s%s%s',
    \ g:github#curl_cmd, param,
    \ protocol, s:domain, s:base_path, a:path))
  finally
    for f in files
      call delete(f)
    endfor
  endtry

  return raw ? res : s:parse_json(res)
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
