" Access to the Github Issues.
" Version: 0.1.0
" Author : thinca <thinca+vim@gmail.com>
" License: Creative Commons Attribution 2.1 Japan License
"          <http://creativecommons.org/licenses/by/2.1/jp/deed.en>

let s:save_cpo = &cpo
set cpo&vim


let s:feature = {'name': 'issues'}


function! s:feature.invoke(args)  " {{{2
  let [user, repos] = 2 == len(a:args) ? a:args : [g:github#user, a:args[0]]
  let f = self.new(user, repos)
  call f.start()
endfunction



function! s:feature.new(user, repos)  " {{{2
  let obj = copy(self)
  let [obj.user, obj.repos] = [a:user, a:repos]

  let open = obj.connect('list', 'open')
  let closed = obj.connect('list', 'closed')

  let obj.issues = open.issues + closed.issues
  return obj
endfunction



function! s:feature.start()  " {{{2
  " TODO: Opener is made customizable.
  new
  let b:github_issues = self

  setlocal nobuflisted
  setlocal buftype=nofile noswapfile bufhidden=wipe
  setlocal nonumber nolist nowrap
  0put =printf('Github Issues - %s/%s', self.user, self.repos)
  for issue in self.issues
    $put =self.line_format(issue)
  endfor

  setlocal nomodifiable readonly

  let b:github_issues_list_changenr = changenr()

  nnoremap <buffer> <silent> <Plug>(github-issues-open-issue)
  \        :<C-u>call b:github_issues.open_issue(line('.') - 3)<CR>
  nnoremap <buffer> <silent> <Plug>(github-issues-issue-list)
  \        :<C-u>silent execute 'undo' b:github_issues_list_changenr<CR>


  silent! nmap <unique> <CR> <Plug>(github-issues-open-issue)
  silent! nmap <unique> <BS> <Plug>(github-issues-issue-list)
  silent! nmap <unique> <C-t> <Plug>(github-issues-issue-list)


  setlocal filetype=github-issues
endfunction



function! s:feature.open_issue(order)  " {{{2
  let issue = self.issues[a:order]
  if type(issue.comments) == type(0)
    let issue.comments = self.connect('comments', issue.number).comments
  endif

  setlocal modifiable noreadonly

  silent 3,$ delete _
  silent put =self.issue_layout(issue)

  setlocal nomodifiable readonly
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



function! s:feature.connect(action, ...)  " {{{2
  let params = a:0 ? '/' . join(a:000, '/') : ''
  return github#connect(printf('/issues/%s/%s/%s%s',
  \ a:action, self.user, self.repos, params))
endfunction



function! github#issues#new()  " {{{2
  return copy(s:feature)
endfunction



let &cpo = s:save_cpo
unlet s:save_cpo
