" An interface for Github.
" Version: 0.1.0
" Author : thinca <thinca+vim@gmail.com>
" License: Creative Commons Attribution 2.1 Japan License
"          <http://creativecommons.org/licenses/by/2.1/jp/deed.en>

let s:save_cpo = &cpo
set cpo&vim

let s:domain = 'github.com'
let s:base_path = '/api/v2/json'
let s:is_win = has('win16') || has('win32') || has('win64')

let s:V = vital#of('github')
let s:http = s:V.import('Web.Http')
let s:json = s:V.import('Web.Json')

let s:Base = {}  " {{{1
function! s:Base.new(...)
  let obj = copy(self)
  if has_key(obj, 'initialize')
    call call(obj.initialize, a:000, obj)
  endif
  return obj
endfunction


" API  {{{1
let s:Github = s:Base.new()
function! s:Github.initialize(user, token)
  let [self.user, self.token] = [a:user, a:token]

  let self.curl_cmd = g:github#curl_cmd
endfunction

function! s:Github.connect(path, ...)
  let params = {}
  let path = a:path
  let raw = 0
  for a in github#flatten(a:000)
    if type(a) == type(0)
      raw = a
    elseif type(a) == type('')
      let path .= '/' . a
    elseif type(a) == type({})
      call extend(params, a)
    endif
    unlet a
  endfor

  try
    let postdata = {'login': self.user, 'token': self.token}
    let postdata = extend(postdata, params)

    let url = printf('https://%s%s%s', s:domain, s:base_path, path)
    let res = s:http.post(url, postdata).content
  catch
    let res = ''
  endtry

  return raw ? s:iconv(res, 'utf-8', &encoding) : s:json.decode(res)
endfunction


" UI  {{{1
let s:UI = s:Base.new()


" Features manager.  {{{1
let s:features = {}

function! github#register(feature)
  let feature = extend(copy(s:UI), a:feature)
  let s:features[feature.name] = feature
endfunction


" Interfaces.  {{{1
function! github#base()
  return s:Base.new()
endfunction

function! github#connect(path, ...)
  return s:Github.new(g:github#user, g:github#token).connect(a:path, a:000)
endfunction

function! github#flatten(list)
  let list = []
  for i in a:list
    if type(i) == type([])
      let list += github#flatten(i)
    else
      call add(list, i)
    endif
    unlet! i
  endfor
  return list
endfunction

function! github#get_text_on_cursor(pat)
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

" /path/*/to/*  => splat: [first, second]
" /:feature/:user/:repos/#id
function! github#parse_path(path, pattern)
  let placefolder_pattern = '\v%((::?|#)\w+|\*\*?)'
  let regexp = substitute(a:pattern, placefolder_pattern,
  \                       '\=s:convert_placefolder(submatch(0))', 'g')
  let matched = matchlist(a:path, '^' . regexp . '\m$')
  if empty(matched)
    return {}
  endif
  call remove(matched, 0)
  let ret = {}
  let splat = []
  for folder in s:scan_string(a:pattern, placefolder_pattern)
    let name = matchstr(folder, '\v^(::?|#)\zs\w+')
    if !empty(name)
      let ret[name] = remove(matched, 0)
    else
      call add(splat, remove(matched, 0))
    endif
  endfor
  if !empty(splat)
    let ret.splat = splat
  endif
  return ret
endfunction

function! s:convert_placefolder(placefolder)
  if a:placefolder ==# '**' || a:placefolder =~# '^::'
    let pat = '.*'
  elseif a:placefolder =~# '^#'
    let pat = '\d*'
  else
    let pat = '[^/]*'
  endif
  return '\(' . pat . '\)'
endfunction

function! s:scan_string(str, pattern)
  let list = []
  let pos = 0
  while 0 <= pos
    let matched = matchstr(a:str, a:pattern, pos)
    let pos = matchend(a:str, a:pattern, pos)
    if !empty(matched)
      call add(list, matched)
    endif
  endwhile
  return list
endfunction


" pseudo buffer. {{{1
function! github#read(path)
  try
    let uri = github#parse_path(a:path, 'github://:feature/::param')
    if !exists('b:github')
      if empty(uri)
        throw 'github: Invalid path: ' . a:path
      endif
      if !has_key(s:features, uri.feature)
        throw 'github: Specified feature is not registered: ' . uri.feature
      endif
      let b:github = s:features[uri.feature].new('/' . uri.param)
    endif
    let &l:filetype = 'github-' . uri.feature
    call b:github.read()
  catch /^github:/
    setlocal bufhidden=wipe
    echoerr v:exception
  endtry
endfunction

" Main commands.  {{{1
function! github#invoke(argline)
  " The simplest implementation.
  try
    let [feat; args] = split(a:argline, '\s\+')
    if !has_key(s:features, feat)
      throw 'github: Specified feature is not registered: ' . feat
    endif
    call s:features[feat].invoke(args)
  catch /^github:/
    echohl ErrorMsg
    echomsg v:exception
    echohl None
  endtry
endfunction

function! github#complete(lead, cmd, pos)
  let token = split(a:cmd, '\s\+', 1)
  let ntoken = len(token)
  if ntoken == 1
    return keys(s:features)
  elseif ntoken == 2
    return filter(keys(s:features), 'stridx(v:val, token[1]) == 0')
  elseif ntoken == 3
    return github#{token[1]}#complete(a:lead, a:cmd, a:pos)
  else
    return []
  endif
endfunction

function! s:iconv(expr, from, to)
  if a:from ==# a:to || a:from == '' || a:to == ''
    return a:expr
  endif
  let result = iconv(a:expr, a:from, a:to)
  return result != '' ? result : a:expr
endfunction

function! s:system(args)
  let type = type(a:args)
  let args = type == type([]) ? a:args :
  \          type == type('') ? split(a:args) : []

  if g:github#use_vimproc
    call github#debug_log(args)
    return vimproc#system(args)
  endif

  if s:is_win
    let args[0] = s:cmdpath(args[0])
    let q = '"'
    let cmd = join(map(args,
    \   'q . substitute(escape(v:val, q), "[<>^|&]", "^\\0", "g") . q'),
    \   ' ')
  else
    let cmd = join(map(args, 'shellescape(v:val)'), ' ')
  endif
  call github#debug_log(cmd)
  return system(cmd)
endfunction

function! s:cmdpath(cmd)
  " Search the fullpath of command for MS Windows.
  let full = glob(a:cmd)
  if a:cmd ==? full
    " Already fullpath.
    return a:cmd
  endif

  let extlist = split($PATHEXT, ';')
  if a:cmd =~? '\V\%(' . substitute($PATHEXT, ';', '\\|', 'g') . '\)\$'
    call insert(extlist, '', 0)
  endif
  for dir in split($PATH, ';')
    for ext in extlist
      let full = glob(dir . '\' . a:cmd . ext)
      if full != ''
        return full
      endif
    endfor
  endfor
  return ''
endfunction


" Debug.  {{{1
function! github#debug_log(mes, ...)
  if !g:github#debug
    return
  endif
  let mes = a:0 ? call('printf', [a:mes] + a:000) : a:mes
  if g:github#debug_file == ''
    for m in split(mes, "\n")
      echomsg 'github: ' . m
    endfor
  else
    let file = strftime(g:github#debug_file)
    let dir = fnamemodify(file, ':h')
    if !isdirectory(dir)
      call mkdir(dir, 'p')
    endif
    execute 'redir >>' file
    silent! echo strftime('%c:') mes
    redir END
  endif
endfunction


" Options.  {{{1
if !exists('g:github#curl_cmd')  " {{{2
  let g:github#curl_cmd = 'curl'
endif

if !exists('g:github#use_vimproc')  " {{{2
  let g:github#use_vimproc =
  \   globpath(&runtimepath, 'autoload/vimproc.vim') != ''
endif

if !exists('g:github#debug')  " {{{2
  let g:github#debug = 0
endif

if !exists('g:github#debug_file')  " {{{2
  let g:github#debug_file = ''
endif

if !exists('g:github#user')  " {{{2
  let g:github#user =
  \   matchstr(s:system('git config --global github.user'), '\w*')
endif

if !exists('g:github#token')  " {{{2
  let g:github#token =
  \   matchstr(s:system('git config --global github.token'), '\w*')
endif


" Register the default features. {{{1
function! s:register_defaults()
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
