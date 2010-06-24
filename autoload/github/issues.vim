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
  let open = s:connect('list', user, repos, 'open')
  let closed = s:connect('list', user, repos, 'closed')

  let [self.user, self.repos] = [user, repos]
  let self.issues = open.issues + closed.issues
  call self.open()
endfunction



function! s:feature.open()  " {{{2
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
endfunction



function! s:feature.line_format(issue)  " {{{2
  return printf('%3d: %-6s| %s%s', a:issue.number, a:issue.state,
  \     join(map(a:issue.labels, '"[".v:val."]"'), ''), a:issue.title)
endfunction



function! s:connect(action, user, repos, ...)  " {{{2
  let params = a:0 ? '/' . join(a:000, '/') : ''
  return github#connect(printf('/issues/%s/%s/%s%s',
  \ a:action, a:user, a:repos, params))
endfunction



function! github#issues#new()  " {{{2
  return copy(s:feature)
endfunction



let &cpo = s:save_cpo
unlet s:save_cpo
