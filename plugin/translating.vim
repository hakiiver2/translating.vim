

command! -nargs=1 Translate call translating#Translate(<f-args>)
" command! -range TranslateSelectedText <line1>,<line2>call translating#translateSelectedText()
command! -range -nargs=* TranslateSelectedText <line1>,<line2>call translating#translateSelectedText(<f-args>)
command! -nargs=1 PopupText call translating#popupText(<f-args>)
command! -range -nargs=* TranslateAndReplaceSelectedText <line1>,<line2>call translating#translateAndReplaceSelectedText(<f-args>)
command! -nargs=1 ReplaceText call translating#replaceText(<f-args>)
