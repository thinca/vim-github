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
  call f.open('issue_list')
endfunction



function! s:feature.new(user, repos)  " {{{2
  let obj = copy(self)
  let [obj.user, obj.repos] = [a:user, a:repos]

  let open = obj.connect('list', 'open')
  let closed = obj.connect('list', 'closed')

  let obj.issues = open.issues + closed.issues
  call obj.sort()
  return obj
endfunction



function! s:feature.open(with, ...)  " {{{2
  let bufnr = 0
  for i in range(0, winnr('$'))
    let n = winbufnr(i)
    if getbufvar(n, '&filetype') =~# '^github-issues'
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
    let b:github_issues = self

    setlocal nobuflisted
    setlocal buftype=nofile noswapfile bufhidden=wipe
    setlocal nonumber nolist nowrap
    0put =printf('Github Issues - %s/%s', self.user, self.repos)

  else
    setlocal modifiable noreadonly
    silent 3,$ delete _
  endif

  call call(self[a:with], a:000, self)

  setlocal nomodifiable readonly
  1

  setlocal filetype=github-issues
endfunction



function! s:feature.issue_list()  " {{{2
  for issue in self.issues
    $put =self.line_format(issue)
  endfor

  let b:github_issues_list_changenr = changenr()

  nnoremap <buffer> <silent> <Plug>(github-issues-open-issue)
  \        :<C-u>call b:github_issues.open('open_issue', line('.') - 3)<CR>
  nnoremap <buffer> <silent> <Plug>(github-issues-issue-list)
  \        :<C-u>silent execute 'undo' b:github_issues_list_changenr<CR>


  silent! nmap <unique> <CR> <Plug>(github-issues-open-issue)
  silent! nmap <unique> <BS> <Plug>(github-issues-issue-list)
  silent! nmap <unique> <C-t> <Plug>(github-issues-issue-list)
endfunction



function! s:feature.open_issue(order)  " {{{2
  let issue = self.issues[a:order]
  if type(issue.comments) == type(0)
    let issue.comments = self.connect('comments', issue.number).comments
  endif

  silent put =self.issue_layout(issue)
endfunction



function! s:feature.line_format(issue)  " {{{2
  return printf('%3d: %-6s| %s%s', a:issue.number, a:issue.state,
  \     join(map(a:issue.labels, '"[".v:val."]"'), ''), a:issue.title)
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



function! s:feature.sort()  " {{{2
  call sort(self.issues, s:func('compare'))
endfunction



function! s:feature.connect(action, ...)  " {{{2
  let params = a:0 ? '/' . join(a:000, '/') : ''
  return github#connect(printf('/issues/%s/%s/%s%s',
  \ a:action, self.user, self.repos, params))
endfunction



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
