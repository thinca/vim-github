" Access to the Github Issues.
" Version: 0.1.0
" Author : thinca <thinca+vim@gmail.com>
" License: Creative Commons Attribution 2.1 Japan License
"          <http://creativecommons.org/licenses/by/2.1/jp/deed.en>

let s:save_cpo = &cpo
set cpo&vim


let s:feature = {'name': 'issues'}


function! s:feature.invoke(args)  " {{{2
  let repos = a:args[0]
  let [user, repos] = repos =~ '/' ? split(repos, '/')[0 : 1]
  \                                    : [g:github#user, repos]

  let f = self.new(user, repos)

  if len(a:args) == 1
    call f.view('issue_list')
  else
    let id = a:args[1]
    if id =~ '^\d\+$'
      call f.view('issue', id - 1)
    endif
  endif
endfunction



function! s:feature.initialize(user, repos)  " {{{2
  let [self.user, self.repos] = [a:user, a:repos]

  call self.fetch()
endfunction



function! s:feature.opened()  " {{{2
  nnoremap <buffer> <silent> <Plug>(github-issues-action)
  \        :<C-u>call b:github_issues.action()<CR>
  nnoremap <buffer> <silent> <Plug>(github-issues-issue-list)
  \        :<C-u>call b:github_issues.view('issue_list')<CR>

  silent! nmap <unique> <CR> <Plug>(github-issues-action)
  silent! nmap <unique> <BS> <Plug>(github-issues-issue-list)
  silent! nmap <unique> <C-t> <Plug>(github-issues-issue-list)
endfunction



" Model.  {{{1
function! s:feature.fetch()  " {{{2
  let open = self.connect('list', 'open')
  let closed = self.connect('list', 'closed')

  let self.issues = open.issues + closed.issues
  call self.sort()
endfunction



" View.  {{{1
function! s:feature.header()  " {{{2
  return printf('Github Issues - %s/%s', self.user, self.repos)
endfunction



function! s:feature.view_issue_list()  " {{{2
  return map(copy(self.issues), 'self.line_format(v:val)')
endfunction



function! s:feature.view_issue(order)  " {{{2
  let issue = self.issues[a:order]
  if type(issue.comments) == type(0)
    let issue.comments = self.connect('comments', issue.number).comments
  endif

  return self.issue_layout(issue)
endfunction



function! s:feature.line_format(issue)  " {{{2
  return printf('%3d: %-6s| %s%s', a:issue.number, a:issue.state,
  \     join(map(copy(a:issue.labels), '"[".v:val."]"'), ''), a:issue.title)
endfunction



function! s:feature.issue_layout(issue)  " {{{2
  let i = a:issue
  let lines = [
  \ i.number . ': ' . i.title,
  \ 'state: ' . i.state,
  \ 'user: ' . i.user,
  \ 'created: ' . i.created_at,
  \ 'updated: ' . i.updated_at,
  \ '',
  \ ]
  let lines += split(i.body, '\r\?\n') + ['', '']

  for c in i.comments
    let lines += [
    \ '------------------------------------------------------------',
    \ '  ' . c.user . ' ' . c.created_at,
    \ '',
    \ ]
    let lines += map(split(c.body, '\r\?\n'), '"  " . v:val')
  endfor

  return lines
endfunction



" Control.  {{{1
function! s:feature.sort()  " {{{2
  call sort(self.issues, s:func('compare'))
endfunction



function! s:feature.action()  " {{{2
  if b:github_issues_view ==# 'issue_list'
    call self.view('issue', line('.') - 3)
  endif
endfunction



function! s:feature.connect(action, ...)  " {{{2
  return github#connect('/issues', a:action, self.user, self.repos,
  \      map(copy(a:000), 'type(v:val) == type(0) ? v:val . "" : v:val'))
endfunction



" Misc.  {{{1
function! s:compare(a, b)  " {{{2
  " TODO: Be made customizable.
  return a:a.number - a:b.number
endfunction



function! s:func(name)  "{{{2
  return function(matchstr(expand('<sfile>'), '<SNR>\d\+_\zefunc$') . a:name)
endfunction



function! github#issues#new()  " {{{2
  return copy(s:feature)
endfunction



let &cpo = s:save_cpo
unlet s:save_cpo
