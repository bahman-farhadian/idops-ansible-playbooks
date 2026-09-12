" gruvbox.vim — lightline colorscheme, the exact hex values as
" colors/gruvbox.vim elsewhere in this repository, hand-written the same
" way that file is, not picked from lightline's own bundled set (none of
" which match this project's own palette).

let s:bg0  = '#282828'
let s:bg1  = '#3c3836'
let s:bg2  = '#504945'
let s:fg1  = '#ebdbb2'
let s:fg2  = '#d5c4a1'
let s:grey = '#928374'
let s:red    = '#fb4934'
let s:green  = '#b8bb26'
let s:yellow = '#fabd2f'
let s:blue   = '#83a598'
let s:purple = '#d3869b'

let s:p = {'normal': {}, 'inactive': {}, 'insert': {}, 'replace': {}, 'visual': {}, 'tabline': {}}

" Mode segment (far left/right) — dark text on the mode's accent colour,
" the same "dark text on a bright fill" pairing CursorLineNr already uses
" for the same reason: bg0 reads clearly against any of these.
let s:p.normal.left    = [ [ s:bg0, s:green, 'bold' ], [ s:fg1, s:bg2 ] ]
let s:p.normal.right   = [ [ s:bg0, s:green, 'bold' ], [ s:fg1, s:bg2 ] ]
let s:p.insert.left    = [ [ s:bg0, s:blue, 'bold' ], [ s:fg1, s:bg2 ] ]
let s:p.insert.right   = copy(s:p.insert.left)
let s:p.replace.left   = [ [ s:bg0, s:red, 'bold' ], [ s:fg1, s:bg2 ] ]
let s:p.replace.right  = copy(s:p.replace.left)
let s:p.visual.left    = [ [ s:bg0, s:purple, 'bold' ], [ s:fg1, s:bg2 ] ]
let s:p.visual.right   = copy(s:p.visual.left)
let s:p.normal.middle  = [ [ s:fg2, s:bg1 ] ]
let s:p.insert.middle  = copy(s:p.normal.middle)
let s:p.replace.middle = copy(s:p.normal.middle)
let s:p.visual.middle  = copy(s:p.normal.middle)
let s:p.normal.error   = [ [ s:bg0, s:red ] ]
let s:p.normal.warning = [ [ s:bg0, s:yellow ] ]

let s:p.inactive.left   = [ [ s:grey, s:bg1 ], [ s:grey, s:bg1 ] ]
let s:p.inactive.middle = [ [ s:grey, s:bg1 ] ]
let s:p.inactive.right  = [ [ s:grey, s:bg1 ] ]

" Same colours TabLine/TabLineSel already use in colors/gruvbox.vim.
let s:p.tabline.left   = [ [ s:grey, s:bg1 ] ]
let s:p.tabline.tabsel = [ [ s:bg0, s:yellow, 'bold' ] ]
let s:p.tabline.middle = [ [ s:grey, s:bg1 ] ]
let s:p.tabline.right  = copy(s:p.tabline.left)

let g:lightline#colorscheme#gruvbox#palette = lightline#colorscheme#fill(s:p)
