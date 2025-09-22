function! mista#filter#apply(kind, keyword) abort
  if !exists('b:mista_buffer')
    return
  endif
  
  let current_matches = b:mista_matches
  let new_matches = []
  
  let escaped = mista#_escape_special_chars(a:keyword)
  let pattern = g:mista#case_sensitive ? escaped : '\c' . escaped
  
  if a:kind ==# 'keep'
    for match in current_matches
      if match.text =~ pattern
        call add(new_matches, match)
      endif
    endfor
  elseif a:kind ==# 'reject'
    for match in current_matches
      if match.text !~ pattern
        call add(new_matches, match)
      endif
    endfor
  endif
  
  if !exists('b:mista_filter_history') || b:mista_filter_history_index < 0
    let b:mista_filter_history = [current_matches]
    let b:mista_filter_history_index = 0
  endif
  let b:mista_filter_history = b:mista_filter_history[0 : b:mista_filter_history_index]
  call add(b:mista_filter_history, new_matches)
  let b:mista_filter_history_index += 1
  
  call add(b:mista_filter_commands, {'kind': a:kind, 'keyword': a:keyword})
  
  let title_suffix = s:_build_filter_title()
  let new_title = split(b:mista_title, ' |')[0] . title_suffix
  
  call mista#render#update_matches(new_matches, new_title)
  
  echo printf('Mista: %s filter "%s" - %d matches', 
        \ (a:kind ==# 'keep' ? 'Keep' : 'Reject'),
        \ a:keyword,
        \ len(new_matches))
endfunction

function! mista#filter#history_navigate(direction) abort
  if !exists('b:mista_buffer')
    return
  endif
  
  let history_len = len(b:mista_filter_history)
  let current_index = b:mista_filter_history_index
  
  if a:direction ==# 'prev'
    if current_index > 0
      let b:mista_filter_history_index -= 1
    else
      echo 'Mista: Already at the beginning of filter history'
      return
    endif
  elseif a:direction ==# 'next'
    if current_index < history_len - 1
      let b:mista_filter_history_index += 1
    else
      echo 'Mista: Already at the latest filter state'
      return
    endif
  endif
  
  let matches = b:mista_filter_history[b:mista_filter_history_index]
  
  let title = split(b:mista_title, ' |')[0]
  if b:mista_filter_history_index > 0
    let applied_commands = b:mista_filter_commands[0:b:mista_filter_history_index-1]
    for cmd in applied_commands
      let title .= printf(' | %s:%s', 
            \ (cmd.kind ==# 'keep' ? 'K' : 'R'),
            \ cmd.keyword)
    endfor
  endif
  
  call mista#render#update_matches(matches, title)
  
  echo printf('Mista: Filter history %d/%d', 
        \ b:mista_filter_history_index + 1,
        \ history_len)
endfunction

function! mista#filter#reset() abort
  if !exists('b:mista_buffer')
    return
  endif
  
  let b:mista_matches = b:mista_original_matches
  let b:mista_filter_history = [b:mista_original_matches]
  let b:mista_filter_history_index = 0
  let b:mista_filter_commands = []
  
  let original_title = split(b:mista_title, ' |')[0]
  
  call mista#render#update_matches(b:mista_original_matches, original_title)
  
  echo 'Mista: Filters reset'
endfunction

function! s:_build_filter_title() abort
  if empty(b:mista_filter_commands)
    return ''
  endif
  
  let parts = []
  for cmd in b:mista_filter_commands
    call add(parts, printf('%s:%s',
          \ (cmd.kind ==# 'keep' ? 'K' : 'R'),
          \ cmd.keyword))
  endfor
  
  return ' | ' . join(parts, ' | ')
endfunction
