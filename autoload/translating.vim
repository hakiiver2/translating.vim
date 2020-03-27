let s:V = vital#vital#new()
let s:Promise = s:V.import('Async.Promise')
let s:HTTP = s:V.import('Web.HTTP')
let s:relativeCursorPosition = [0, 0] " line, cursor
let s:textCursorPosition = [0, 0] " line, cursor
let s:textLineRangeList = [0, 0]
let s:popup_window = 0
let s:target = get(g:, "translating_target", "ja")
let s:source = get(g:, "translating_source", "en")

function! s:parse_flags(flagList) abort
    let flagList = a:flagList
    let isSource = 0
    let isTarget = 0
    for flag in flagList
        if isSource == 1
            let s:source = flag
            let isSource = 0
        elseif isTarget == 1
            let s:target = flag
            let isTarget = 0
        elseif flag == "--source" || flag == "-s"
            let isSource = 1
        elseif flag == "--target" || flag == "-g"
            let isTarget = 1
        endif
    endfor
    echo s:source
    echo s:target

endfunction

function! s:read_to_buf(buf, chan) abort
  for part in ['err', 'out']
    let out = ''
    while ch_status(a:chan, {'part' : part}) ==# 'buffered'
      let out .= ch_read(a:chan, {'part' : part}) . "\n"
    endwhile
    let a:buf[part] = out
  endfor
endfunction

function! s:sh(...) abort
  let cmd = join(a:000, ' ')
  let buf = {}
  return s:Promise.new({resolve, reject -> job_start(cmd, {
              \   'close_cb' : {ch ->
              \     s:read_to_buf(buf, ch)
              \   },
              \   'exit_cb' : {ch, code ->
              \     code ? reject(buf.err) : resolve(buf.out)
              \   },
              \ })})

endfunction

function! s:setRelativeCursorPosition() abort
    let curTabNumber = tabpagenr()

    let s:relativeCursorPosition[0] = line(".") - winheight(curTabNumber) + 1
    let s:relativeCursorPosition[1] = col(".")
endfunction

function! s:setTextCursorPosition() abort
    let s:textCursorPosition[0] = line(".")
    let s:textCursorPosition[1] = col(".")
endfunction



function! translating#popupText(text) abort

    call popup_close(s:popup_window)
    let tlist = split(a:text, "\n")

    let s:popup_window = popup_create(tlist, {
                \ "pos":"topleft",
                \ "border": [1, 1, 1, 1],
                \ "line": s:relativeCursorPosition[0],
                \ "col": s:relativeCursorPosition[1],
                \ "maxwidth": 30,
                \ 'borderchars': ['-','|','-','|','+','+','+','+'],
                \ "moved": "any",
                \ })
endfunction

function! translating#replaceText(text) abort
    let tlist = split(a:text, "\n")
    let selectedTlist = split(s:selected, "\n")
    let i = 0
    let firstLine = s:textLineRangeList[0]
    let lastLine = s:textLineRangeList[1]

    echo s:textLineRangeList
    echo tlist
    echo selectedTlist

    echo len(tlist)
    echo len(selectedTlist)
    
    for line in range(firstLine, lastLine)
        call execute(":" . line . " s/" . selectedTlist[i] . "/" . tlist[i] . "/g")
        let i = i + 1
    endfor
    let s:textLineRangeList = []

endfunction


function! s:TranslateText(text) abort
    let url = 'https://script.google.com/macros/s/AKfycby4U810pYK-d2ADQis7CNXouuwtJqvnyiEYDQQ7PiXTC0TLwu-y/exec?text=+' . s:HTTP.encodeURIComponent(a:text) . '&source=' . s:source . '&target=' . s:target
    return s:sh('curl', ' -L', url).then({data -> data})
endfunction


function! s:TranslateSelectedText() range

    let tmp = @@
    silent normal gvy
    let s:selected = @@
    let @@ = tmp

    call s:setRelativeCursorPosition()
    call s:setTextCursorPosition()

    return s:TranslateText(s:selected)

    " " let url = 'https://script.google.com/macros/s/AKfycby4U810pYK-d2ADQis7CNXouuwtJqvnyiEYDQQ7PiXTC0TLwu-y/exec?text=' . s:HTTP.encodeURIComponent(s:selected) . '&source=' . s:source . '&target=' . s:target
    " let url = 'https://script.google.com/macros/s/AKfycby4U810pYK-d2ADQis7CNXouuwtJqvnyiEYDQQ7PiXTC0TLwu-y/exec?text=+' . s:HTTP.encodeURIComponent(s:selected) . '&source=' . s:source . '&target=' . s:target
    " return s:sh('curl', ' -L', url).then({data -> data})
endfunction

function! translating#Translate(text)
    call s:TranslateText(a:text)
        \.then({text -> execute('echom ' . string(text), '')})
        \.catch({err -> execute('echom ' . string('ERROR: ' . err), '')})
endfunction

function! translating#translateSelectedText(...) range
    call s:parse_flags(a:000)
    call s:TranslateSelectedText()
        \.then({text -> execute('PopupText' . text . '' , '')})
        \.catch({err -> execute('echom ' . string('ERROR: ' . err), '')})
endfunction

function! translating#translateAndReplaceSelectedText(...) range
    let s:textLineRangeList[0] = a:firstline
    let s:textLineRangeList[1] = a:lastline
    call s:parse_flags(a:000)

    call s:TranslateSelectedText()
        \.then({text -> execute('ReplaceText' . text . '' , '')})
        \.catch({err -> execute('echom ' . string('ERROR: ' . err), '')})
endfunction
