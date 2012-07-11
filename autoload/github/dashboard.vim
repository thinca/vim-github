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
let s:json = s:V.import('Web.Json')
let s:prelude = s:V.import('Prelude')

let s:use_icon = has('signs') && has('gui_running') && executable('curl') && executable('convert') && executable('animate')
let s:icon_dir = substitute(fnamemodify(expand('~/.cache/vim-github'), ':p:8'), '\\', '/', 'g')
let s:icon_dir = substitute(s:icon_dir, '/$', '', '')
let s:icon_ext = (has('win32')||has('win64')) ? 'bmp' : 'xpm'
if !isdirectory(s:icon_dir)
  call mkdir(s:icon_dir, 'p')
endif

let s:UI = {'name': 'dashboard'}

function! s:UI.invoke(args)
  let opener = &l:filetype !=# 'github-dashboard' ? 'new' : 'edit'
  execute opener 'github://dashboard/'
endfunction

function! s:get_icon(user)
  let url = printf('https://api.github.com/users/%s', a:user)
  let res = s:http.get(url)
  let json = s:json.decode(res.content)
  call s:prelude.system(printf("curl -L -o %s %s",
  \  shellescape(printf("%s/%s.png", s:icon_dir, a:user)),
  \  shellescape(json.avatar_url)))
  call s:prelude.system(printf("convert %s %s",
  \  shellescape(printf("%s/%s.png", s:icon_dir, a:user)),
  \  shellescape(printf("%s/%s.%s", s:icon_dir, a:user, s:icon_ext))))
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
    if s:use_icon
      let author = entry.childNode("author").childNode("name").value()
      let fname = fnamemodify(s:icon_dir . '/' . author . '.' . s:icon_ext, ':p:8')
      if !filereadable(fname)
        call s:get_icon(author)
      endif
      if filereadable(fname)
        silent! exe "sign unplace ".author." *"
        silent! exe "sign undefine ".author."
        silent! exe "sign define ".author." icon=".fnameescape(fname)
        silent! exe "sign place ".line('.')." line=".(line('.')-2)." name=".author." file=".fnameescape(expand('%:p'))
      else
        echomsg author
      endif
    endif
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
