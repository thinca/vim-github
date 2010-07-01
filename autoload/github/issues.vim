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
    elseif id ==# 'new'
      call f.edit('issue')
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
  nnoremap <buffer> <silent> <Plug>(github-issues-reload)
  \        :<C-u>call b:github_issues.reload()<CR>

  silent! nmap <buffer> <unique> <CR> <Plug>(github-issues-action)
  silent! nmap <buffer> <unique> <BS> <Plug>(github-issues-issue-list)
  silent! nmap <buffer> <unique> <C-t> <Plug>(github-issues-issue-list)
  silent! nmap <buffer> <unique> R <Plug>(github-issues-reload)
  silent! nmap <buffer> <unique> <C-r> <Plug>(github-issues-reload)
endfunction



" Model.  {{{1
function! s:feature.fetch()  " {{{2
  let open = self.connect('list', 'open')
  let closed = self.connect('list', 'closed')

  let self.issues = open.issues + closed.issues
  call self.sort()
endfunction



function! s:feature.update_issue(number, title, body)  " {{{2
  let res = self.connect('edit', a:number, {'title': a:title, 'body': a:body})
  " FIXME: The order is non-definite.
  let self.issues[a:number - 1] = res.issue
endfunction



function! s:feature.create_new_issue(title, body, labels)  " {{{2
  let res = self.connect('open', {'title': a:title, 'body': a:body})
  " TODO: Update labels.
  call add(self.issues, res.issue)
endfunction



" View.  {{{1
function! s:feature.header()  " {{{2
  return printf('Github Issues - %s/%s', self.user, self.repos)
endfunction



function! s:feature.view_issue_list()  " {{{2
  return ['[[new issue]]'] + map(copy(self.issues), 'self.line_format(v:val)')
endfunction



function! s:feature.view_issue(order)  " {{{2
  let issue = self.issues[a:order]
  if type(issue.comments) == type(0)
    let issue.comments = self.connect('comments', issue.number).comments
  endif

  let self.issue = issue

  return ['[[edit]] ' . (issue.state ==# 'open' ?
  \       '[[close]]' : '[[reopen]]')] + self.issue_layout(issue)
endfunction



function! s:feature.edit_issue(...)  " {{{2
  let [title, labels, body] = a:0 ?
  \ [a:1.title, a:1.labels, a:1.body] :
  \ ['', [], "\n"]
  let text = ['[[POST]]']
  if a:0
    let text += ['number: ' . a:1.number]
  endif
  let text += ['title: ' . title]
  if !empty(labels)
    call add(text, 'labels: ' . join(labels, ', ')
  endif
  return text + ['body:'] + split(body, '\r\?\n', 1)
endfunction



function! s:feature.line_format(issue)  " {{{2
  return printf('%3d: %-6s| %s%s', a:issue.number, a:issue.state,
  \      join(map(copy(a:issue.labels), '"[".v:val."]"'), ''),
  \      substitute(a:issue.title, '\n', '', 'g'))
endfunction



function! s:feature.issue_layout(issue)  " {{{2
  let i = a:issue
  let lines = [
  \ i.number . ': ' . i.title,
  \ 'state: ' . i.state,
  \ 'user: ' . i.user,
  \ ]

  if !empty(i.labels)
    let lines += [join(i.labels, ', ')]
  endif

  let lines += ['created: ' . i.created_at]

  if i.created_at !=# i.updated_at
    let lines += ['updated: ' . i.updated_at]
  endif
  if i.closed_at != 0
    let lines += ['closed: ' . i.closed_at]
  endif

  let lines += [''] + split(i.body, '\r\?\n') + ['', '']

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
  let button = github#get_text_on_cursor('\[\[.\{-}\]\]')
  if b:github_issues_buf ==# 'view_issue_list'
    if button ==# '[[new issue]]'
      call self.edit('issue')
    else
      " FIXME: Accurate issue number.
      call self.view('issue', line('.') - 4)
    endif
  elseif b:github_issues_buf ==# 'view_issue'
    if button ==# '[[edit]]'
      call self.edit('issue', self.issue)
    elseif button ==# '[[close]]'
      let num = self.issue.number
      let self.issues[num - 1] = self.connect('close', num).issue
      call self.view('issue', num - 1)
    elseif button ==# '[[reopen]]'
      let num = self.issue.number
      let self.issues[num - 1] = self.connect('reopen', num).issue
      call self.view('issue', num - 1)
    endif
  elseif b:github_issues_buf ==# 'edit_issue'
    if button ==# '[[POST]]'
      let c = getpos('.')
      try
        1
        let bodystart = search('^\cbody:', 'n')
        if !bodystart
          throw 'github: issues: No body.'
        endif
        let body = join(getline(bodystart + 1, '$'), "\n")

        let titleline = search('^\ctitle:', 'Wn', bodystart)
        if !titleline
          throw 'github: issues: No title.'
        endif
        let title = matchstr(getline(titleline), '^\w\+:\s*\zs.\{-}\ze\s*$')
        if title == ''
          throw 'github: issues: Title is empty.'
        endif

        let numberline = search('^\cnumber:', 'Wn', bodystart)
        if numberline
          let number = matchstr(getline(numberline), '^\w\+:\s*\zs.\{-}\ze\s*$')
          call self.update_issue(number, title, body)

        else
          " TODO: Pass labels.
          call self.create_new_issue(title, body, [])
        endif

      finally
        call setpos('.', c)
      endtry
      close
    endif
  endif
endfunction



function! s:feature.reload()  " {{{2
  if b:github_issues_buf ==# 'view_issue_list'
    call self.fetch()
    call self.view('issue_list')
  elseif b:github_issues_buf ==# 'view_issue'
    let self.issue.comments = 0
    call self.view('issue', self.issue.number - 1)
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
