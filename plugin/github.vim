" An interface for Github.
" Version: 0.1.0
" Author : thinca <thinca+vim@gmail.com>
" License: Creative Commons Attribution 2.1 Japan License
"          <http://creativecommons.org/licenses/by/2.1/jp/deed.en>

if exists('g:loaded_github')
  finish
endif
let g:loaded_github = 1

let s:save_cpo = &cpo
set cpo&vim

function! s:github_complete(lead, cmd, pos)
  silent! let keys = github#complete(a:lead, a:cmd, a:pos)
  return keys
endfunction


command! -nargs=+ -complete=customlist,s:github_complete
\        Github call github#invoke(<q-args>)



let &cpo = s:save_cpo
unlet s:save_cpo
