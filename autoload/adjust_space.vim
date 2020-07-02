let s:textLineRangeList = [0, 0]

function! adjust_space#adjustEqual(...) range

    let s:textLineRangeList[0] = a:firstline
    let s:textLineRangeList[1] = a:lastline

    let tmp = @@
    silent normal gvy
    let s:selected = @@
    let @@ = tmp

    let s:selectedTlist = split(s:selected, "\n")
    let s:maxSpaceCount = 0
    let s:spaceCountList = []
    
    " = までの長さ
    for selectedTextLine in s:selectedTlist
        let s:spaceCount = 0
        let s:matchedIdx = match(selectedTextLine, "=") 
        if s:matchedIdx == -1
            let s:spaceCountList = add(s:spaceCountList, 0)
        else
            let s:spaceCountList = add(s:spaceCountList, s:matchedIdx)
        endif
    endfor
    let s:maxSpaceCount = max(s:spaceCountList)

    let s:addSpace = []

    for spaceN in s:spaceCountList
        let s:sp = ""
        for s_i in range(0, (s:maxSpaceCount - spaceN) - 1)
            let s:sp = s:sp . " "
        endfor
        let s:addSpace = add(s:addSpace, s:sp)
    endfor

    let i = 0
    for lineNumber in range(s:textLineRangeList[0], s:textLineRangeList[1])
        let s:matchedIdx = match(s:selectedTlist[i], "=") 
        if s:matchedIdx != -1
            call setpos('.', [lineNumber, s:spaceCountList[i]])
            execute ':' . lineNumber " s/=/" . s:addSpace[i] . "=" 
        endif

        let i = i + 1
    endfor

endfunction
