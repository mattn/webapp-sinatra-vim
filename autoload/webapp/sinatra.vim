let s:basedir = expand('<sfile>:h:h:h') . '/static'

if !exists('s:handlers')
  let s:handlers = {}
endif

function! s:normalize_path(path)
  return tolower(substitute(fnamemodify(a:path, ':p'), '\\', '/', 'g'))
endfunction

function! s:remove_prefix(fn)
  return substitute(a:fn, '^<SNR>\d\+_', '', '')
endfunction

function! s:to_app(pt)
  redir => names
  silent scriptnames
  redir END
  let sn = s:normalize_path(matchstr(a:pt, '\zs.*\ze, line \d\+$'))
  let sl = filter(map(map(split(names, "\n"), 'matchlist(v:val, "^\\s*\\(\\d\\+\\):\\s\\+\\(.\\+\\)\\s*$")[1:2]'), '[v:val[0], s:normalize_path(v:val[1])]'), 'sn == v:val[1]')
  if len(sl) == 0
    throw "Error!"
  endif
  return printf('<SNR>%d_func_%s', sl[0][0], webapi#sha1#sha1(a:pt))
endfunction

function! webapp#sinatra#content_type(...)
  let s:handlers[a:1]['content_type'] = eval(a:2)
endfunction

function! webapp#sinatra#view(...)
  let s:handlers[a:1]['body'] = eval(a:2)
endfunction

function! webapp#sinatra#post(...)
  let f = s:to_app(a:1)
  let p = eval(a:2)
  let s:handlers[p] = {'path': p, 'method': 'POST', 'func': f}
  return printf('function! %s%s', f, a:3)
endfunction

function! webapp#sinatra#get(...)
  let f = s:to_app(a:1)
  let p = eval(a:2)
  let s:handlers[p] = {'path': p, 'method': 'GET', 'func': f}
  return printf('function! %s%s', f, a:3)
endfunction

function! webapp#sinatra#handle(req)
  try
    for path in reverse(sort(keys(s:handlers)))
      if stridx(a:req.path, path) == 0 && s:handlers[path].method == a:req.method
        let b:vimatra = s:handlers[path]
        let ret = function(s:handlers[path].func)(a:req)
        if type(ret) == 4
          let body = webapi#json#encode(ret)
        elseif type(ret) != 1
          let body = string(ret)
        else
          let body = ret
        endif
        let header = has_key(s:handlers[path], 'content_type') ? ["Content-Type: " . s:handlers[path].content_type] : []
        return {"body": body, "header": header}
      endif
    endfor
    let res = webapp#servefile(a:req, s:basedir)
  catch
    let res = {"header": [], "body": "Internal Server Error: " . v:exception, "status": 500}
  endtry
  return res
endfunction
