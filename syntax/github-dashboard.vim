" Syntax file for github-issues of github.vim.
" Version: 0.1.0
" Author : thinca <thinca+vim@gmail.com>
" License: Creative Commons Attribution 2.1 Japan License
"          <http://creativecommons.org/licenses/by/2.1/jp/deed.en>

if exists('b:current_syntax')
  finish
endif

syntax match githubIssuesButton "\[\[.\{-}\]\]"

highlight default link githubIssuesButton Underlined

let b:current_syntax = 'github-dashboard'
