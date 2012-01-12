if exists("b:did_ftplugin") || !exists('b:github')
  finish
endif

let b:did_ftplugin = 1

let s:cpo_save = &cpo
set cpo&vim


setlocal buftype=nofile noswapfile nobuflisted bufhidden=unload

nnoremap <buffer> <silent> <Plug>(github-issues-action)
\        :<C-u>call b:github.action()<CR>

silent! nmap <buffer> <unique> <CR> <Plug>(github-issues-action)

if b:github.type ==# 'view'
  setlocal nonumber nolist
  if b:github.mode ==# 'list'
    setlocal nowrap
  endif
  nnoremap <buffer> <silent> <Plug>(github-issues-issue-list)
  \        :<C-u>call b:github.open()<CR>
  nnoremap <buffer> <silent> <Plug>(github-issues-redraw)
  \        :<C-u>call b:github.read()<CR>
  nnoremap <buffer> <silent> <Plug>(github-issues-reload)
  \        :<C-u>call b:github.reload()<CR>
  nnoremap <buffer> <silent> <Plug>(github-issues-next)
  \        :<C-u>call b:github.move(v:count1)<CR>
  nnoremap <buffer> <silent> <Plug>(github-issues-prev)
  \        :<C-u>call b:github.move(-v:count1)<CR>

  nmap <buffer> <BS> <Plug>(github-issues-issue-list)
  nmap <buffer> <C-t> <Plug>(github-issues-issue-list)
  nmap <buffer> r <Plug>(github-issues-redraw)
  nmap <buffer> R <Plug>(github-issues-reload)
  nmap <buffer> <C-r> <Plug>(github-issues-reload)
  nmap <buffer> <C-j> <Plug>(github-issues-next)
  nmap <buffer> <C-k> <Plug>(github-issues-prev)

  augroup ftplugin-github-issues
    autocmd! * <buffer>
    autocmd BufEnter <buffer> call b:github.read()
  augroup END
endif


let &cpo = s:cpo_save
unlet s:cpo_save
