" File: MyConfig.vim
" Description: My Config
" Author: Feil <feilniu AT gmail DOT com>
" Last Change: 2014-07-29 23:07:50

" My Commands {{{
command! Etxt :e $VIM/vimfiles/syntax/txt.vim
command! EMyConfig :e $VIM/vimfiles/plugin/MyConfig.vim
command! EMyConfigAfter :e $VIM/vimfiles/after/plugin/MyConfigAfter.vim
" }}}

" Unescape URL {{{
command UnescapeURL :call s:UnescapeURL(0)
command UnescapeURLSplit :call s:UnescapeURL(1)
nmap <unique> <Leader>ue :call <SID>UnescapeURL(0)<CR>
nmap <unique> <Leader>uE :call <SID>UnescapeURL(1)<CR>
function s:UnescapeURL(IsSplitParams)
  if a:IsSplitParams == 1
    %s/[?&]/\r/ge
  endif
  %s/%\(\x\x\)/\=nr2char('0x'.submatch(1))/ge
  %s/%u\(\x\x\x\x\)/\=nr2char('0x'.submatch(1))/ge
endfunction
" }}}

" 全半角转换 {{{
command -range=% Full2Half :<line1>,<line2>s/[！-～]/\=nr2char(char2nr(submatch(0))-65248)/ge
command -range=% Half2Full :<line1>,<line2>s/[!-~]/\=nr2char(char2nr(submatch(0))+65248)/ge
" }}}

" vim:fdm=marker:
