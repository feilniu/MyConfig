" Description: SQL after ftplugin for folding
" Author: Feil <feilniu AT gmail DOT com>
" Last Change: 2014-06-20 15:37:33

function! SQLFoldLevel(lineno)
  if a:lineno == 1
    return 0
  endif
  if getline(a:lineno) == 'GO'
    return 's1'
  endif
  if getline(a:lineno-1) == 'GO'
    return 'a1'
  endif
  return '='
endfunction

setl foldexpr=SQLFoldLevel(v:lnum)
setl foldmethod=expr
"setl foldminlines=2
