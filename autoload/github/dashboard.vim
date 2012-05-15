" Access to the Github Dashboard.
" Version: 0.1.0
" Author : thinca <thinca+vim@gmail.com>
" License: Creative Commons Attribution 2.1 Japan License
"          <http://creativecommons.org/licenses/by/2.1/jp/deed.en>

let s:save_cpo = &cpo
set cpo&vim

let s:V = vital#of('github')
let s:http = s:V.import('Web.Http')
let s:xml = s:V.import('Web.Xml')

let s:UI = {'name': 'dashboard'}

function! s:UI.invoke(args)
  let opener = &l:filetype !=# 'github-dashboard' ? 'new' : 'edit'
  execute opener 'github://dashboard/'
endfunction

function! s:UI.read()
  if get(b:, 'github_dashboard', 0) && line('$') > 1
    return
  endif

  let url = printf('https://github.com/%s.private.atom?token=%s',
  \ g:github#user, g:github#token)
  let res = s:http.get(url)
  let dom = s:xml.parse(res.content)

  setlocal modifiable noreadonly
  silent % delete _
  silent 0put ='Github Dashboard'
  silent $put ='[[update]]'
  for entry in dom.childNodes('entry')
    let title = entry.childNode('title').value()
    let url = entry.childNode('link').attr['href']
    let title = substitute(title, ' \(pull request \d\+ on \S\+\)$', ' [[\1]] ', 'g')
    let title = substitute(title, ' \(issue \d\+ on \S\+\)$', ' [[\1]] ', 'g')
    if exists(':Gist')
      let title = substitute(title, ' \(gist: \d\+\)$', ' [[\1]] ', 'g')
    endif
    let content = printf("%s\n  [[%s]]\n\n", title, url)
    silent $put =content
  endfor
  setlocal nomodifiable readonly
  silent! normal! gg
  let b:github_dashboard = 1
endfunction

function! s:UI.action()
  try
    let button = github#get_text_on_cursor('\[\[.\{-}\]\]')
    if len(button) == 0
      return
    endif
    let button = button[2:-3]
    if button == 'update'
      let b:github_dashboard = 0
      call self.read()
    elseif button =~ '^gist: '
      exe "Gist" button[6:]
    elseif button =~ '^issue '
      let [_, id, repo; __] = matchlist(button, 'issue \(\d\+\) on \(\S\+\)$')
      exe "split" printf('github://issues/%s/%d', repo, id)
    elseif button =~ '^pull '
      let [_, id, repo; __] = matchlist(button, 'pull request \(\d\+\) on \(\S\+\)$')
      exe "split" printf('github://issues/%s/%d', repo, id)
    elseif button =~ '^http' && exists(':OpenBrowser')
      exe "OpenBrowser" button
    endif
  catch /^github:/
    echohl ErrorMsg
    echomsg v:exception
    echohl None
  endtry
endfunction

function! s:func(name)
  return function(matchstr(expand('<sfile>'), '<SNR>\d\+_\zefunc$') . a:name)
endfunction

function! github#dashboard#new()
  return copy(s:UI)
endfunction

function! github#dashboard#complete(lead, cmd, pos)
  return []
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo
