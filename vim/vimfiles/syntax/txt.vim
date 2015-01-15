" File: txt.vim
" Description: plain text syntax file
" Language: text/plain :)
" Author: Feil <feilniu AT gmail DOT com>
" Last Change: 2014-11-23 18:28:45

scriptencoding utf-8

if exists("b:current_syntax")
  finish
endif

syn case match

syn keyword txtTodo   TODO FIXME NOTE DEBUG COMMENT NOTICE
syn keyword txtError  ERROR BUG CAUTION WARNING FATAL HOT IMPORTANT
syn keyword txtDone   DONE OK

" English Punctuation Marks
syn match txtEPM '[~\-_+*<>\[\]{}=|#@$%&\\/:&\^\.,!?'"]'
" Chinese Punctuation Marks
syn match txtCPM '[，。；：！？、《》【】“”‘’（）『』「」〖〗﹝﹞〔〕〈〉…￥·■◆▲●★□◇△○☆＄‰￥℃※±⑴⑵⑶⑷⑸⑹⑺⑻⑼⑽⑾⑿⒀⒁⒂⒃⒄⒅⒆⒇⒈⒉⒊⒋⒌⒍⒎⒏⒐⒑⒒⒓⒔⒕⒖⒗⒘⒙⒚⒛①②③④⑤⑥⑦⑧⑨⑩㈠㈡㈢㈣㈤㈥㈦㈧㈨㈩→←↑↓§№◎ⅠⅡⅢⅣⅤⅥⅦⅧⅨⅩⅪⅫ≈≡≠＝≤≥＜＞≮≯∷±＋－×÷／∫∮∝∞∧∨∑∏∪∩∈∵∴⊥∥∠⌒⊙≌∽√°¤￠〇]'

syn match txtNumber '\d\+\(\.\d\+\)\='
syn match txtLink '\<\w\+://\(\w\|[-&=,?:./]\)\+'

syn cluster txtTagsContains contains=txtNumber,txtEPM,txtCPM,txtLink
syn match txtTags '<[^>]*>'   contains=@txtTagsContains
syn match txtTags '{[^}]*}'   contains=@txtTagsContains
syn match txtTags '\[[^]]*\]' contains=@txtTagsContains
syn match txtTags '【[^】]*】' contains=@txtTagsContains
syn match txtTags '〖[^〗]*〗' contains=@txtTagsContains

syn cluster txtCommentContains contains=txtTodo,txtError,txtLink
syn match  txtComment '\(^\| \)\@<=#.*$'      contains=@txtCommentContains
syn match  txtComment '\(^\| \)\@<=\/\/.*$'   contains=@txtCommentContains
syn region txtComment start='\/\*' end='\*\/' contains=@txtCommentContains

syn match txtTitle '^\(\d\+\.\)*\d\+ \+.\+$'
syn match txtTitle '^[一二三四五六七八九十]\+[、. ] *.\+$'
syn match txtTitle '^[=■◆▲●★□◇△○☆] \+.\+$'
" syn match txtSubTitle '^\d\+\. .\+$'

syn match txtList '^\s*\zs[-+*]\ze [^ ]'
syn match txtList '^\s*\zs[A-Za-z]\+\.\ze [^ ]'
syn match txtList '^\s*\zs[0-9A-Za-z]\+)\ze [^ ]'

syn cluster txtQuotedContains contains=txtNumber,txtEPM,txtCPM,txtLink,txtQuoted,txtBracketed
syn match  txtQuoted    '"[^"]\+"'hs=s+1,he=e-1                      contains=@txtQuotedContains
syn match  txtQuoted    "\(\w\)\@<!'[^']\+'"hs=s+1,he=e-1            contains=@txtQuotedContains
syn region txtQuoted    matchgroup=txtCPM  start='[《]'  end='[》]'  contains=@txtQuotedContains
syn region txtQuoted    matchgroup=txtCPM  start='[“]'  end='[”]'  contains=@txtQuotedContains
syn region txtQuoted    matchgroup=txtCPM  start='[『]'  end='[』]'  contains=@txtQuotedContains
syn region txtQuoted    matchgroup=txtCPM  start='[﹝]'  end='[﹞]'  contains=@txtQuotedContains
syn region txtQuoted    matchgroup=txtCPM  start='[〔]'  end='[〕]'  contains=@txtQuotedContains
syn region txtQuoted    matchgroup=txtCPM  start='[〈]'  end='[〉]'  contains=@txtQuotedContains
syn region txtQuoted    matchgroup=txtCPM  start='[「]'  end='[」]'  contains=@txtQuotedContains
syn region txtQuoted    matchgroup=txtCPM  start='[‘]'  end='[’]'  contains=@txtQuotedContains
syn region txtBracketed matchgroup=txtCPM  start='[(（]' end='[）)]' contains=@txtQuotedContains

hi link txtTodo       Todo
hi link txtError      Error
hi def txtDone ctermbg=Blue ctermfg=Black guibg=#6666FF guifg=Black
hi link txtEPM        Special
hi link txtCPM        Constant
hi link txtNumber     Constant
hi link txtLink       Underlined
hi link txtTags       Identifier
hi link txtComment    Comment
hi link txtTitle      Title
hi link txtSubTitle   Type
hi link txtList       Statement
hi link txtQuoted     Statement
hi link txtBracketed  Special

let b:current_syntax = 'txt'
" vim:tw=0:et:
