function! mista#command#open(bang, arg) abort
  let l:arg = trim(a:arg)
  call mista#open(a:bang, l:arg)
endfunction

function! mista#command#jump() abort
  call mista#jump()
endfunction

function! mista#command#close() abort
  call mista#close()
endfunction

function! mista#command#filter_keep(arg) abort
  call mista#filter('keep', a:arg)
endfunction

function! mista#command#filter_reject(arg) abort
  call mista#filter('reject', a:arg)
endfunction

function! mista#command#filter_undo() abort
  call mista#history('prev')
endfunction

function! mista#command#filter_redo() abort
  call mista#history('next')
endfunction

" Deprecated functions with warnings
function! mista#command#history_prev_deprecated() abort
  echohl WarningMsg
  echo 'MistaPrev is deprecated. Use MistaFilterUndo instead.'
  echohl None
  call mista#history('prev')
endfunction

function! mista#command#history_next_deprecated() abort
  echohl WarningMsg
  echo 'MistaNext is deprecated. Use MistaFilterRedo instead.'
  echohl None
  call mista#history('next')
endfunction

function! mista#command#redraw() abort
  call mista#render_current()
endfunction

function! mista#command#config(...) abort
  if a:0 >= 2
    execute 'let g:mista#'.a:1.' = ' . string(a:2)
    echo 'Mista: Set g:mista#'.a:1.' to '.string(a:2)
  elseif a:0 == 1
    if exists('g:mista#'.a:1)
      echo 'g:mista#'.a:1.' = '.string(eval('g:mista#'.a:1))
    else
      echo 'Mista: Unknown configuration: g:mista#'.a:1
    endif
  else
    echo 'Usage: :MistaConfig {key} [{value}]'
  endif
endfunction

function! mista#command#info() abort
  call mista#debug_info()
endfunction

function! mista#command#help() abort
  if !exists('b:mista_buffer')
    echo 'Mista: Not in a Mista buffer'
    return
  endif
  let eff = deepcopy(g:mista#buffer_keymaps_default)
  for k in keys(g:mista#buffer_keymaps) | let eff[k] = g:mista#buffer_keymaps[k] | endfor
  let labels = {
        \ ':MistaJump'      : 'Jump to source location',
        \ ':MistaClose'     : 'Close Mista buffer',
        \ ':MistaFilterUndo': 'Undo filter operation',
        \ ':MistaFilterRedo': 'Redo filter operation',
        \ ':MistaKeep'      : 'Keep lines with keyword',
        \ ':MistaReject'    : 'Reject lines with keyword',
        \ ':MistaHelp'      : 'Show this help',
        \ }
  echo '=== Mista Buffer Mappings (effective) ==='
  echo ''
  echo printf('%-10s %s', 'Key', 'Action')
  echo printf('%-10s %s', '----------', '------')
  for [lhs, spec] in items(eff)
    let rhs = get(spec, 'rhs', '')
    let cmd = matchstr(rhs, ':\w\+')
    let desc = get(labels, cmd, rhs)
    echo printf('%-10s %s', lhs, desc)
  endfor
  echo ''
  echo 'Press any key to continue...'
  call getchar()
endfunction

function! mista#command#go_next() abort
  call mista#navigate_match('next')
endfunction

function! mista#command#go_prev() abort
  call mista#navigate_match('prev')
endfunction

" Deprecated navigation functions
function! mista#command#next_match_deprecated() abort
  echohl WarningMsg
  echo 'MistaNextMatch is deprecated. Use MistaGoNext instead.'
  echohl None
  call mista#navigate_match('next')
endfunction

function! mista#command#prev_match_deprecated() abort
  echohl WarningMsg
  echo 'MistaPrevMatch is deprecated. Use MistaGoPrev instead.'
  echohl None
  call mista#navigate_match('prev')
endfunction
