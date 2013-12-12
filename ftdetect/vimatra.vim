function! s:vimatra_setup()
  setlocal filetype=vim
  return webapp#sinatra#setup()
endfunction

au BufNewFile,BufRead *.vimatra exe s:vimatra_setup()
