let s:basedir = expand('<sfile>:h:h:h') . '/static'

if !exists('s:handlers')
  let s:handlers = {}
endif

function! s:normalize_path(path)
  return tolower(substitute(fnamemodify(a:path, ':p'), '\\', '/', 'g'))
endfunction

function! webapp#sinatra#get(...)
  redir => names
  silent scriptnames
  redir END
  let sn = s:normalize_path(matchstr(a:1, '\zs.*\ze, line \d\+$'))
  let sl = filter(map(map(split(names, "\n"), 'matchlist(v:val, "^\\s*\\(\\d\\+\\):\\s\\+\\(.\\+\\)\\s*$")[1:2]'), '[v:val[0], s:normalize_path(v:val[1])]'), 'sn == v:val[1]')
  if len(sl) == 0
    throw "Error!"
  endif
  let f = printf('<SNR>_%dfunc%s', sl[0][0], webapi#sha1#sha1(a:1))
  let s:handlers[eval(a:2)] = f
  return printf('function! %s%s', f, a:3)
endfunction

function! webapp#sinatra#setup()
  call webapp#handle("/", function("webapp#sinatra#handle"))
  return '
  \ command! -buffer -nargs=* Get try|throw 1|catch|exe webapp#sinatra#get(v:throwpoint, <f-args>)|endtry
  \'
endfunction

function! webapp#sinatra#handle(req)
  try
    for path in reverse(sort(keys(s:handlers)))
      if stridx(a:req.path, path) == 0
        return {"body": "" . function(s:handlers[path])(a:req)}
      endif
    endfor
    let res = webapp#servefile(a:req, s:basedir)
  catch
    let res = {"header": [], "body": "Internal Server Error: " . v:exception, "status": 500}
  endtry
  return res
endfunction
