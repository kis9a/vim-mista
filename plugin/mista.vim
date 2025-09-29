
if exists('g:loaded_mista') | finish | endif
let g:loaded_mista = 1

if !exists('g:mista#filetypes')      | let g:mista#filetypes      = [] | endif
if !exists('g:mista#sidebar_width')  | let g:mista#sidebar_width  = 40           | endif
if !exists('g:mista#conceal_number') | let g:mista#conceal_number = 1            | endif
if !exists('g:mista#case_sensitive') | let g:mista#case_sensitive = 0            | endif
if !exists('g:mista#jump_center')    | let g:mista#jump_center    = 1            | endif
if !exists('g:mista#header_levels')  | let g:mista#header_levels  = range(1,10)  | endif
if !exists('g:mista#open_direction') | let g:mista#open_direction = 'leftabove'  | endif
if !exists('g:mista#max_lines')      | let g:mista#max_lines      = 100000       | endif

if !exists('g:mista#buffer_keymaps_default')
  let g:mista#buffer_keymaps_default = {
  \ '<CR>':   {'mode': 'n', 'rhs': ':MistaJump<CR>',   'opts': '<silent>'},
  \ 'mq':     {'mode': 'n', 'rhs': ':MistaClose<CR>',  'opts': '<silent>'},
  \ 'mp':     {'mode': 'n', 'rhs': ':MistaPrev<CR>',   'opts': '<silent>'},
  \ 'mn':     {'mode': 'n', 'rhs': ':MistaNext<CR>',   'opts': '<silent>'},
  \ 'mk':     {'mode': 'n', 'rhs': ':MistaKeep ',      'opts': ''},
  \ 'mr':     {'mode': 'n', 'rhs': ':MistaReject ',    'opts': ''},
  \ 'mh':     {'mode': 'n', 'rhs': ':MistaHelp<CR>',   'opts': '<silent>'},
  \ }
endif

if !exists('g:mista#buffer_keymaps')
  let g:mista#buffer_keymaps = {}
endif

if !exists('g:mista#hooks') | let g:mista#hooks = {} | endif
if !exists('g:mista#stages_enum') | let g:mista#stages_enum = {'before': 0, 'after': 1} | endif

if !exists('g:mista#buffer_args') | let g:mista#buffer_args = {} | endif
if !exists('g:mista#buffer_cursor_pos') | let g:mista#buffer_cursor_pos = {} | endif
if !exists('g:mista#buffer_state') | let g:mista#buffer_state = {} | endif
if !exists('g:mista#mista_cursor_pos') | let g:mista#mista_cursor_pos = {} | endif
if !exists('g:mista#max_cache_size') | let g:mista#max_cache_size = 20 | endif
if !exists('g:mista#gc_interval') | let g:mista#gc_interval = 10 | endif

let s:gc_counter = 0

augroup mista_gc
  autocmd!
  autocmd BufDelete * call s:mista_gc_lazy(expand('<abuf>'))
augroup END

function! s:mista_gc_lazy(bufstr) abort
  let buf = str2nr(a:bufstr)

  " Always clean up the specific buffer being deleted
  if has_key(g:mista#buffer_state, buf) || has_key(g:mista#buffer_args, buf)
    call s:mista_gc_buffer(buf)
  endif

  " Periodically do a full cleanup
  let s:gc_counter += 1
  if s:gc_counter >= g:mista#gc_interval
    let s:gc_counter = 0
    call s:mista_gc_all()
  endif
endfunction

function! s:mista_gc_buffer(buf) abort
  if has_key(g:mista#buffer_args, a:buf) | call remove(g:mista#buffer_args, a:buf) | endif
  if has_key(g:mista#buffer_cursor_pos, a:buf) | call remove(g:mista#buffer_cursor_pos, a:buf) | endif
  if has_key(g:mista#buffer_state, a:buf) | call remove(g:mista#buffer_state, a:buf) | endif
  if has_key(g:mista#mista_cursor_pos, a:buf) | call remove(g:mista#mista_cursor_pos, a:buf) | endif
endfunction

function! s:mista_gc_all() abort
  for buf in keys(g:mista#buffer_state)
    if !bufexists(str2nr(buf))
      call s:mista_gc_buffer(str2nr(buf))
    endif
  endfor

  if len(g:mista#buffer_state) > g:mista#max_cache_size
    let items = items(g:mista#buffer_state)
    " Safe sort with error handling for missing buffers
    call sort(items, function('s:compare_buffer_lastused'))
    for i in range(g:mista#max_cache_size, len(items) - 1)
      call s:mista_gc_buffer(str2nr(items[i][0]))
    endfor
  endif
endfunction

function! s:compare_buffer_lastused(a, b) abort
  let info_a = getbufinfo(str2nr(a:a[0]))
  let info_b = getbufinfo(str2nr(a:b[0]))
  let lastused_a = empty(info_a) ? 0 : get(info_a[0], 'lastused', 0)
  let lastused_b = empty(info_b) ? 0 : get(info_b[0], 'lastused', 0)
  return lastused_a < lastused_b ? -1 : lastused_a > lastused_b ? 1 : 0
endfunction

command! -bang -nargs=?  Mista       call mista#command#open(<bang>0, <q-args>)
command! -nargs=0        MistaJump   call mista#command#jump()
command! -nargs=0        MistaClose  call mista#command#close()
command! -nargs=1        MistaKeep   call mista#command#filter_keep(<q-args>)
command! -nargs=1        MistaReject call mista#command#filter_reject(<q-args>)
command! -nargs=0        MistaPrev   call mista#command#history_prev()
command! -nargs=0        MistaNext   call mista#command#history_next()
command! -nargs=0        MistaRedraw call mista#command#redraw()
command! -nargs=*        MistaConfig call mista#command#config(<f-args>)
command! -nargs=0        MistaInfo   call mista#command#info()
command! -nargs=0        MistaHelp   call mista#command#help()
