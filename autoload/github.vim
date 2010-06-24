" An interface for Github.
" Version: 0.1.0
" Author : thinca <thinca+vim@gmail.com>
" License: Creative Commons Attribution 2.1 Japan License
"          <http://creativecommons.org/licenses/by/2.1/jp/deed.en>

let s:save_cpo = &cpo
set cpo&vim

let s:domain = 'github.com'
let s:base_path = '/api/v2/json'

" JSON Utilities.  {{{1
function! s:validate_json(str)  " {{{2
  " Reference: http://mattn.kaoriya.net/software/javascript/20100324023148.htm

  let str = a:str
  let str = substitute(str, '\\\%(["\\\/bfnrt]\|u[0-9a-fA-F]{4}\)', '\@', 'g')
  let str = substitute(str, '"[^\"\\\n\r]*\"\|true\|false\|null\|-\{-}\d\+' .
  \                    '\%(\.\d*\)\{-}\%([eE][+\-]\{-}\d\+\)\{-}', ']', 'g')
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
if !exists('github#user')  " {{{2
  let github#user = system('git config --global github.user')
endif

if !exists('github#token')  " {{{2
  let github#token = system('git config --global github.token')
endif


let &cpo = s:save_cpo
unlet s:save_cpo
