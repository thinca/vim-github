" Syntax file for github-issues of github.vim.
" Version: 0.1.0
" Author : thinca <thinca+vim@gmail.com>
" License: zlib License

if exists('b:current_syntax')
  finish
endif

syntax match githubIssuesButton "\[\[.\{-}\]\]"

highlight default link githubIssuesButton Underlined

let b:current_syntax = 'github-issues'
