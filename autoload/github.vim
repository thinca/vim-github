" An interface for Github.
" Version: 0.1.0
" Author : thinca <thinca+vim@gmail.com>
" License: Creative Commons Attribution 2.1 Japan License
"          <http://creativecommons.org/licenses/by/2.1/jp/deed.en>

let s:save_cpo = &cpo
set cpo&vim

let s:domain = 'github.com'
let s:base_path = '/api/v2/json'


" Interfaces.  {{{1
function! github#connect(path)  " {{{2
  return s:parse_json(system(
  \ printf('curl -s -F "login=%s" -F "token=%s" http://%s%s%s',
  \ g:github#user, g:github#token, s:domain, s:base_path, a:path)))
endfunction



" JSON Utilities.  {{{1
function! s:validate_json(str)  " {{{2
  " Reference: http://mattn.kaoriya.net/software/javascript/20100324023148.htm

  let str = a:str
  let str = substitute(str, '\\\%(["\\\/bfnrt]\|u[0-9a-fA-F]{4}\)', '\@', 'g')
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


let &cpo = s:save_cpo
unlet s:save_cpo
