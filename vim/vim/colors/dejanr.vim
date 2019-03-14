set background=dark

hi clear

if exists("syntax_on")
	syntax reset
endif

let colors_name = "dejanr"

if has("gui_running") || &t_Co == 88 || &t_Co == 256
	let s:low_color = 0
else
	let s:low_color = 1
endif

" dejan.vim by Dejan Ranisavljevic

" returns an approximate grey index for the given grey level
fun! s:grey_number(x)
	if &t_Co == 88
		if a:x < 23
			return 0
		elseif a:x < 69
			return 1
		elseif a:x < 103
			return 2
		elseif a:x < 127
			return 3
		elseif a:x < 150
			return 4
		elseif a:x < 173
			return 5
		elseif a:x < 196
			return 6
		elseif a:x < 219
			return 7
		elseif a:x < 243
			return 8
		else
			return 9
		endif
	else
		if a:x < 14
			return 0
		else
			let l:n = (a:x - 8) / 10
			let l:m = (a:x - 8) % 10
			if l:m < 5
				return l:n
			else
				return l:n + 1
			endif
		endif
	endif
endfun

" returns the actual grey level represented by the grey index
fun! s:grey_level(n)
	if &t_Co == 88
		if a:n == 0
			return 0
		elseif a:n == 1
			return 46
		elseif a:n == 2
			return 92
		elseif a:n == 3
			return 115
		elseif a:n == 4
			return 139
		elseif a:n == 5
			return 162
		elseif a:n == 6
			return 185
		elseif a:n == 7
			return 208
		elseif a:n == 8
			return 231
		else
			return 255
		endif
	else
		if a:n == 0
			return 0
		else
			return 8 + (a:n * 10)
		endif
	endif
endfun

" returns the palette index for the given grey index
fun! s:grey_color(n)
	if &t_Co == 88
		if a:n == 0
			return 16
		elseif a:n == 9
			return 79
		else
			return 79 + a:n
		endif
	else
		if a:n == 0
			return 16
		elseif a:n == 25
			return 231
		else
			return 231 + a:n
		endif
	endif
endfun

" returns an approximate color index for the given color level
fun! s:rgb_number(x)
	if &t_Co == 88
		if a:x < 69
			return 0
		elseif a:x < 172
			return 1
		elseif a:x < 230
			return 2
		else
			return 3
		endif
	else
		if a:x < 75
			return 0
		else
			let l:n = (a:x - 55) / 40
			let l:m = (a:x - 55) % 40
			if l:m < 20
				return l:n
			else
				return l:n + 1
			endif
		endif
	endif
endfun

" returns the actual color level for the given color index
fun! s:rgb_level(n)
	if &t_Co == 88
		if a:n == 0
			return 0
		elseif a:n == 1
			return 139
		elseif a:n == 2
			return 205
		else
			return 255
		endif
	else
		if a:n == 0
			return 0
		else
			return 55 + (a:n * 40)
		endif
	endif
endfun

" returns the palette index for the given R/G/B color indices
fun! s:rgb_color(x, y, z)
	if &t_Co == 88
		return 16 + (a:x * 16) + (a:y * 4) + a:z
	else
		return 16 + (a:x * 36) + (a:y * 6) + a:z
	endif
endfun

" returns the palette index to approximate the given R/G/B color levels
fun! s:color(r, g, b)
	" get the closest grey
	let l:gx = s:grey_number(a:r)
	let l:gy = s:grey_number(a:g)
	let l:gz = s:grey_number(a:b)

	" get the closest color
	let l:x = s:rgb_number(a:r)
	let l:y = s:rgb_number(a:g)
	let l:z = s:rgb_number(a:b)

	if l:gx == l:gy && l:gy == l:gz
		" there are two possibilities
		let l:dgr = s:grey_level(l:gx) - a:r
		let l:dgg = s:grey_level(l:gy) - a:g
		let l:dgb = s:grey_level(l:gz) - a:b
		let l:dgrey = (l:dgr * l:dgr) + (l:dgg * l:dgg) + (l:dgb * l:dgb)
		let l:dr = s:rgb_level(l:gx) - a:r
		let l:dg = s:rgb_level(l:gy) - a:g
		let l:db = s:rgb_level(l:gz) - a:b
		let l:drgb = (l:dr * l:dr) + (l:dg * l:dg) + (l:db * l:db)
		if l:dgrey < l:drgb
			" use the grey
			return s:grey_color(l:gx)
		else
			" use the color
			return s:rgb_color(l:x, l:y, l:z)
		endif
	else
		" only one possibility
		return s:rgb_color(l:x, l:y, l:z)
	endif
endfun

" returns the palette index to approximate the 'rrggbb' hex string
fun! s:rgb(rgb)
	let l:r = ("0x" . strpart(a:rgb, 0, 2)) + 0
	let l:g = ("0x" . strpart(a:rgb, 2, 2)) + 0
	let l:b = ("0x" . strpart(a:rgb, 4, 2)) + 0
	return s:color(l:r, l:g, l:b)
endfun

" sets the highlighting for the given group
fun! s:X(group, fg, bg, attr, lcfg, lcbg)
	if s:low_color
		let l:fge = empty(a:lcfg)
		let l:bge = empty(a:lcbg)

		if !l:fge && !l:bge
			exec "hi ".a:group." ctermfg=".a:lcfg." ctermbg=".a:lcbg
		elseif !l:fge && l:bge
			exec "hi ".a:group." ctermfg=".a:lcfg." ctermbg=NONE"
		elseif l:fge && !l:bge
			exec "hi ".a:group." ctermfg=NONE ctermbg=".a:lcbg
		endif
	else
		let l:fge = empty(a:fg)
		let l:bge = empty(a:bg)

		if !l:fge && !l:bge
			exec "hi ".a:group." guifg=#".a:fg." guibg=#".a:bg." ctermfg=".s:rgb(a:fg)." ctermbg=".s:rgb(a:bg)
		elseif !l:fge && l:bge
			exec "hi ".a:group." guifg=#".a:fg." guibg=NONE ctermfg=".s:rgb(a:fg)
		elseif l:fge && !l:bge
			exec "hi ".a:group." guifg=NONE guibg=#".a:bg." ctermbg=".s:rgb(a:bg)
		endif
	endif

	if a:attr == ""
		exec "hi ".a:group." gui=none cterm=none"
	else
		if a:attr == 'italic'
			exec "hi ".a:group." gui=".a:attr." cterm=none"
		else
			exec "hi ".a:group." gui=".a:attr." cterm=".a:attr
		endif
	endif
endfun
" }}}

if version >= 700
  call s:X("CursorLine","","2d2d2d","","","")
  call s:X("CursorColumn","","2d2d2d","","","")
  call s:X("MatchParen","000000","fad07a","","","")

  call s:X("TabLine","000000","b0b8c0","italic","","Black")
  call s:X("TabLineFill","9098a0","","","","")
  call s:X("TabLineSel","000000","f0f0f0","italic,bold","","")

  " Auto-completion
  call s:X("Pmenu","f6f3e8","444444","","","")
  call s:X("PmenuSel","000000","cae682","","","")
endif

call s:X("Cursor","","656565","","","")
call s:X("Visual","f6f3e8","444444","","black","gray")

call s:X("Normal","f6f3e8","000000","","White","")
call s:X("LineNr","857b6f","000000","","Black","")
call s:X("Comment","99968b","","italic","","")
call s:X("Todo","8f8f8f","","italic","","")

call s:X("StatusLine","f6f3e8","242424","italic","","")
call s:X("StatusLineNC","857b6f","242424","","","")
call s:X("VertSplit","808080","242424","","","")

call s:X("Folded","a0a8b0","242424","italic","black","")
call s:X("FoldColumn","a0a8b0","242424","","","")
call s:X("SignColumn","a0a8b0","000000","italic","Black","Black")

" Syntatic sign colors
call s:X("SignColumnError","B20000","000000","","","")
call s:X("SignColumnWarning","FCE74A","000000","","","")

call s:X("Title","f6f3e8","","bold","","")

call s:X("Constant","cf6a4c","","","Red","")
call s:X("Special","799d6a","","","Green","")
call s:X("Delimiter","668799","","","Grey","")

call s:X("String","99ad6a","","","Green","")
call s:X("StringDelimiter","556633","","","DarkGreen","")

call s:X("Identifier","8197bf","","","LightCyan","")
call s:X("Structure","8fbfdc","","","LightCyan","")
call s:X("Function","ffffff","","","White","")
call s:X("Statement","fad07a","","","DarkBlue","")
call s:X("PreProc","fad07a","","","LightBlue","")

hi link Operator Normal

call s:X("Type","fad07a","","","Yellow","")
call s:X("NonText","808080","151515","","","")

call s:X("SpecialKey","808080","343434","","","")

call s:X("Search","f0a0c0","302028","underline","Magenta","")

call s:X("Directory","dad085","","","","")
call s:X("ErrorMsg","","902020","","","")
hi link Error ErrorMsg

" Diff

call s:X("DiffAdd","","006600","","","")
call s:X("DiffChange","","333333","","","")
call s:X("DiffDelete","cc0033","cc0033","","","")
call s:X("DiffText","","006600","","","")

call s:X("diffAdded","","006600","","","")
call s:X("diffRemoved","","cc0033","","","")


" PHP

hi link phpFunctions Function
hi link phpSuperglobal Identifier
hi link phpQuoteSingle String
hi link phpQuoteDouble String
hi link phpStringSingle String
hi link phpStringDouble String
hi link phpBoolean Constant
hi link phpNull Constant
hi link phpArrayPair Operator
hi link phpParent Operator
hi link phpVarSelector Identifier
hi link phpMemberSelector Operator
hi link phpSpecial Type
hi link phpStatement Type

" Ruby

hi link rubySharpBang Comment
call s:X("rubyClass","447799","","","DarkBlue","")
call s:X("rubyIdentifier","c6b6fe","","","","")

call s:X("rubyInstanceVariable","c6b6fe","","","Cyan","")
call s:X("rubySymbol","7697d6","","","Blue","")
hi link rubyGlobalVariable rubyInstanceVariable
hi link rubyModule rubyClass
call s:X("rubyControl","7597c6","","","","")

hi link rubyString String
hi link rubyStringDelimiter StringDelimiter
hi link rubyInterpolationDelimiter Identifier

call s:X("rubyRegexpDelimiter","540063","","","Magenta","")
call s:X("rubyRegexp","dd0093","","","DarkMagenta","")
call s:X("rubyRegexpSpecial","a40073","","","Magenta","")

call s:X("rubyPredefinedIdentifier","de5577","","","Red","")

" CSS
hi link cssIdentifier rubySymbol

" HTML
hi link htmlEndTag htmlTagName
hi link htmlTag htmlTagName
hi link javaScript javaScriptFuncBlock
hi link htmlError Normal
hi link HtmlHiLink Normal
hi link HtmlLink Normal

" Twig
call s:X("twigStatement","dde5f5","","","Blue","")
call s:X("twigTagDelim","dde5f5","","","Blue","")
hi link twigVarDelim twigTagDelim
hi link twigString String

" JavaScript
hi link javaScriptFuncKeyword Statement
hi link javaScriptFuncDef Operator
hi link javaScriptFunction Statement
hi link javaScriptValue Constant
hi link javaScriptOperator Operator
hi link javaScriptRegexpString rubyRegexp
hi link javaScriptEndColons Normal
hi link javaScriptLabel Identifier
hi link javascriptIdentifier Normal
hi link javascriptBOMWindowProp Normal
hi link javascriptFuncArg Normal
hi link javascriptResponseProp Normal
hi link javascriptXHRMethod Normal
hi link javascriptCacheMethod Normal
hi link javascriptDOMDocProp Normal

" Tag list
hi link TagListFileName Directory

" delete functions {{{
delf s:X
delf s:rgb
delf s:color
delf s:rgb_color
delf s:rgb_level
delf s:rgb_number
delf s:grey_color
delf s:grey_level
delf s:grey_number
" }}}
