" ==============================================================================
" Name:          showpairs
" Description:   Highlights the pair surrounding the current cursor location.
" Author:        Anthony Kruize <trandor@labyrinth.net.au>
"                Szymon M. Kielbasa <s.kielbasa@itb.biologie.hu-berlin.de>
" Version:       1.1a
" Modified:      28 August 2003
" ChangeLog:     1.2 - If on a brace higlights it and it's counterpart.
"                      Otherwise, surrounding braces are highlighted.
"                1.1a - Automatic determination of the current brace;
"                      A mistake releated to '[' brace removed.
"                1.1 - Fixed the fileformat so it doesn't include ^M's.
"                      Fixed the highlighting so it works when 'fg' and 'bg'
"                      aren't yet defined.
"                1.0 - First release.
"
" Usage:         Copy this file into the plugin directory so it will be
"                automatically sourced.
"
" Configuration: ShowPairs uses the 'matchpairs' global option to determine
"                which pairs to highlight. To make ShowPairs highlight a
"                specific pair, simply add it to the 'matchpairs' option.
"                For more information see  :help matchpairs
"
"                ShowPairs uses the 'cursorhold' autocommand to trigger it's
"                highlight check. This is triggered every 'updatetime'
"                milliseconds(default 4000).  If this is too slow, set
"                'updatetime' to a lower value.
"                For more information see  :help updatetime
" ==============================================================================

" Check if we should continue loading
if exists( "loaded_showpairs" )
	finish
endif
let loaded_showpairs = 1

" Highlighting: By default we'll simply bold the pairs to make them stand out.
"hi default ShowPairsHL ctermfg=fg ctermbg=bg cterm=bold guifg=fg guibg=bg gui=bold
hi default ShowPairsHL cterm=bold gui=bold
hi default ShowPairsHLPair cterm=bold gui=bold

" .vimrc: when user wants his own colors (put these to .vimrc)
"hi ShowPairsHL cterm=bold gui=bold guibg=#ffa000
"hi ShowPairsHLPair cterm=bold gui=bold guibg=#ffa000 guifg=#ff0000

" AutoCommands
aug ShowPairs
	au!
	autocmd CursorHold * call s:ShowPairs()
aug END




fun! s:ShowPairsCursorChr()
  let str = getline(".")
  let idx = col(".") - 1
  let ch = str[idx]
  if char2nr(ch) >= 128
    return strpart(str, idx, 2)
  else
    return ch
  endif
endfunction




fun! s:ShowPairsGoto( xln, xcol )
	exe "normal! ".a:xln."G".a:xcol."|"
endf



" Function: ShowPairsSearch
" Description: Builds up a string describing matching braces
"              positions (searching them first till the requested
"              depth).
fun! s:ShowPairsSearch( ps, pe, depth, dir, str )
	let loop = 0
	let str = a:str
	while loop < a:depth
		let xln = searchpair( a:ps, "", a:pe, a:dir )
		let xcol = virtcol(".")
		if xln > 0
			if str != ''
				let str = str . '\|\%'.xln.'l\%'.xcol.'v'
			else
				let str = '\%'.xln.'l\%'.xcol.'v'
			endif
		endif
		let loop = loop + 1
	endwhile
	return str
endf



" Function: ShowPairsMaS( ps, pe )
" Description: Higlights the current position and a matchng brace searched
"              upstream.
fun! s:ShowPairsMaS( ps, pe, depth )
	let xln = line(".")
	let xcol = virtcol(".")
	
	let str = '\%'.xln.'l\%'.xcol.'v'
	let str = s:ShowPairsSearch( a:ps, a:pe, a:depth, "bW", str )
	call s:ShowPairsGoto( xln, xcol )
	
	if str != ''
		exe 'match ShowPairsHLPair /'. str . '/'
	endif
endf



" Function: ShowPairsMaE( ps, pe )
" Description: Higlights the current position and a matchng brace searched
"              downstream.
fun! s:ShowPairsMaE( ps, pe, depth )
	let xln = line(".")
	let xcol = virtcol(".")
	
	let str = '\%'.xln.'l\%'.xcol.'v'
	let str = s:ShowPairsSearch( a:ps, a:pe, a:depth, "W", str )
	call s:ShowPairsGoto( xln, xcol )
	
	if str != ''
		exe 'match ShowPairsHLPair /'. str . '/'
	endif
endf



" Function: ShowPairsMatch( ps, pe )
" Description: Higlights a pair of braces, searching for an opening one
"              upstream and for a closing one downstream.
fun! s:ShowPairsMatch( ps, pe, depth )
	let xln = line(".")
	let xcol = virtcol(".")
	
	let str = s:ShowPairsSearch( a:ps, a:pe, a:depth, "bW", "" )
	call s:ShowPairsGoto( xln, xcol )

	let str = s:ShowPairsSearch( a:ps, a:pe, a:depth, "W", str )
	call s:ShowPairsGoto( xln, xcol )
	
	if str != ''
		exe 'match ShowPairsHL /'. str . '/'
	endif
endf




" Function: ShowPairs()
" Description: This function highlights the pair that the cursor is
fun! s:ShowPairs()
	let cln = line(".")
	let ccol = virtcol(".")
	norm! H
	let fln = line(".")
	call s:ShowPairsGoto( cln, ccol )

	let xmpss = substitute( &mps, ':.\|,', '', 'g' )
	let xmpse = substitute( &mps, '.:\|,', '', 'g' )
	let xesc = "[]$^.*~\\/?"
	let xmpsse = escape( xmpss, xesc )
	let xmpsee = escape( xmpse, xesc )

	let xchr = s:ShowPairsCursorChr()

	" check, whether the cursor on an opening brace
	let loop = 0
	while loop < strlen( xmpss )
		if xchr == xmpss[ loop ]
			call s:ShowPairsMaE( escape(xmpss[loop],xesc), escape(xmpse[loop],xesc), 1 )
			let loop = 1000
		elseif xchr == xmpse[ loop ]
			call s:ShowPairsMaS( escape(xmpss[loop],xesc), escape(xmpse[loop],xesc), 1 )
			let loop = 1000
		endif
		let loop = loop + 1
	endwhile
	
	if loop < 1000
		let xln = searchpair( "[" . xmpsse . "]", '', "[" . xmpsee ."]", 'bW' )
		let xchr = s:ShowPairsCursorChr()
		call s:ShowPairsGoto( cln, ccol )

		let loop = 0
		while loop < strlen( xmpss )
			if xchr == xmpss[ loop ]
				call s:ShowPairsMatch( escape(xmpss[loop],xesc), escape(xmpse[loop],xesc) , 3 )
				let loop = 1000
			endif
			let loop = loop + 1
		endwhile
	endif
	
	exe "norm! ".fln."G"
	norm! zt
	call s:ShowPairsGoto( cln, ccol )
endf

" vim:ts=4:sw=4:noet
