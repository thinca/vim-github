if exists("b:did_ftplugin") || !exists('b:github')
  finish
endif

let b:did_ftplugin = 1

let s:cpo_save = &cpo
set cpo&vim


setlocal buftype=nofile noswapfile nobuflisted bufhidden=unload

nnoremap <buffer> <silent> <Plug>(github-dashboard-action)
\        :<C-u>call b:github.action()<CR>

silent! nmap <buffer> <unique> <CR> <Plug>(github-dashboard-action)

augroup ftplugin-github-dashboard
  autocmd! * <buffer>
  autocmd BufEnter <buffer> call b:github.read()
augroup END

let &cpo = s:cpo_save
unlet s:cpo_save
