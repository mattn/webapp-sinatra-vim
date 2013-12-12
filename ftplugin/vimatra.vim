call webapp#handle("/", function("webapp#sinatra#handle"))
command! -buffer -nargs=1 ContentType call webapp#sinatra#content_type(b:vimatra.path, <f-args>)
command! -buffer -nargs=* Get try|throw 1|catch|exe webapp#sinatra#get(v:throwpoint, <f-args>)|endtry
command! -buffer -nargs=* Post try|throw 1|catch|exe webapp#sinatra#post(v:throwpoint, <f-args>)|endtry
command! -buffer -nargs=* View call webapp#sinatra#view(v:vimatra.path, <f-args>)
command! -buffer -nargs=* Configure exec <q-args>
