" An interface for Github.
" Version: 0.1.0
" Author : thinca <thinca+vim@gmail.com>
" License: Creative Commons Attribution 2.1 Japan License
"          <http://creativecommons.org/licenses/by/2.1/jp/deed.en>

let s:save_cpo = &cpo
set cpo&vim

let s:domain = 'github.com'
let s:base_path = '/api/v2/json'


" Options.  {{{1
if !exists('github#user')  " {{{2
  let github#user = system('git config --global github.user')
endif

if !exists('github#token')  " {{{2
  let github#token = system('git config --global github.token')
endif


let &cpo = s:save_cpo
unlet s:save_cpo
