function! mista#_emit(event, stage, payload) abort
  if !has_key(g:mista#hooks, a:event) | return | endif
  let q = copy(g:mista#hooks[a:event])
  call sort(q, {a,b-> (get(a,'priority',10) > get(b,'priority',10)) ? 1 : -1})
  for h in q
    if get(h,'stage','after') ==# a:stage
      try
        if type(h.hook) == v:t_func
          call h.hook(a:payload)
        elseif type(h.hook) == v:t_string
          execute h.hook
        endif
      catch
      endtry
    endif
  endfor
endfunction

function! mista#_apply_buffer_keymaps() abort
  if !exists('b:mista_buffer') | return | endif
  let eff = deepcopy(g:mista#buffer_keymaps_default)
  for k in keys(g:mista#buffer_keymaps)
    let eff[k] = g:mista#buffer_keymaps[k]
  endfor
  for [lhs, spec] in items(eff)
    let mode = get(spec,'mode','n')
    let rhs  = get(spec,'rhs','')
    let opts = get(spec,'opts','')
    execute mode.'noremap <buffer> '.opts.' '.lhs.' '.rhs
  endfor
endfunction

function! mista#_escape_special_chars(str) abort
  return escape(a:str, '.*[]~$^\\|(){}+-?')
endfunction

function! mista#_get_mista_buffer(...) abort
  let source_filter = a:0 > 0 ? a:1 : 0
  
  for buf in range(1, bufnr('$'))
    if bufexists(buf) && getbufvar(buf, 'mista_buffer', 0)
      if source_filter > 0
        if getbufvar(buf, 'mista_source_bufnr', 0) == source_filter
          return buf
        endif
      else
        return buf
      endif
    endif
  endfor
  return -1
endfunction
function! mista#open(bang, arg) abort
  if a:bang
    call mista#toggle(a:arg)
    return
  endif

  if !empty(g:mista#filetypes) && index(g:mista#filetypes, &filetype) < 0
    echo 'Mista: only for ' . join(g:mista#filetypes, ', ')
    return
  endif

  let mode = s:_determine_mode(a:arg)
  call mista#_emit('open', 'before', {'arg': a:arg, 'mode': mode})

  let bufnr_src = bufnr('%')
  let matches = mista#_collect(bufnr_src, mode, a:arg)
  if empty(matches)
    echo 'Mista: No matches for: ' . a:arg
    return
  endif

  let g:mista#buffer_args[bufnr_src] = a:arg
  let g:mista#buffer_cursor_pos[bufnr_src] = getpos('.')
  
  if has_key(g:mista#buffer_state, bufnr_src) && 
        \ has_key(g:mista#buffer_state[bufnr_src], 'filter_history') &&
        \ g:mista#buffer_args[bufnr_src] == a:arg
    let state = g:mista#buffer_state[bufnr_src]
    let matches = state.matches
    let title = state.title
  else
    let g:mista#buffer_state[bufnr_src] = {
      \ 'matches': matches,
      \ 'original': copy(matches),
      \ 'filter_history': [matches],
      \ 'index': 0,
      \ 'title': s:_make_title(a:arg, mode),
      \ 'filter_commands': []
      \ }
    let title = s:_make_title(a:arg, mode)
  endif

  let name = mista#_make_bufname(a:arg, mode, bufnr_src)
  call mista#_open_display_buffer(name, mode, bufnr_src)

  if has_key(g:mista#buffer_state, bufnr_src) && 
        \ has_key(g:mista#buffer_state[bufnr_src], 'filter_history')
    call mista#render#restore(bufnr_src, g:mista#buffer_state[bufnr_src])
  else
    call mista#render#draw(bufnr_src, matches, title)
  endif
  call mista#_apply_buffer_keymaps()

  call mista#_emit('open', 'after', {'arg': a:arg, 'mode': mode})
endfunction

function! mista#toggle(arg) abort
  let current_bufnr = exists('b:mista_buffer') && exists('b:mista_source_bufnr') 
        \ ? b:mista_source_bufnr : bufnr('%')
  
  let mista_buf = mista#_get_mista_buffer(current_bufnr)
  
  if mista_buf > 0
    if exists('b:mista_buffer') && exists('b:mista_source_bufnr')
      let source_bufnr = b:mista_source_bufnr
      let g:mista#mista_cursor_pos[source_bufnr] = line('.')
      let g:mista#buffer_state[source_bufnr] = {
        \ 'matches': b:mista_matches,
        \ 'original': b:mista_original_matches,
        \ 'filter_history': b:mista_filter_history,
        \ 'index': b:mista_filter_history_index,
        \ 'title': b:mista_title,
        \ 'filter_commands': b:mista_filter_commands
        \ }
      execute 'bwipeout!' mista_buf
      if bufexists(source_bufnr)
        execute 'buffer' source_bufnr
      endif
    else
      execute 'buffer' mista_buf
      if exists('b:mista_source_bufnr')
        let g:mista#mista_cursor_pos[b:mista_source_bufnr] = line('.')
        let g:mista#buffer_state[b:mista_source_bufnr] = {
          \ 'matches': b:mista_matches,
          \ 'original': b:mista_original_matches,
          \ 'filter_history': b:mista_filter_history,
          \ 'index': b:mista_filter_history_index,
          \ 'title': b:mista_title,
          \ 'filter_commands': b:mista_filter_commands
          \ }
      endif
      execute 'bwipeout!' mista_buf
    endif
  else
    if !empty(g:mista#filetypes) && index(g:mista#filetypes, &filetype) < 0
      echo 'Mista: only for ' . join(g:mista#filetypes, ', ')
      return
    endif
    let bufnr_src = bufnr('%')
    let saved_arg = get(g:mista#buffer_args, bufnr_src, a:arg)
    call mista#open(0, saved_arg)
  endif
endfunction

function! mista#filter(kind, kw) abort
  if !exists('b:mista_buffer')
    echo 'Mista: Not in a Mista buffer'
    return
  endif

  call mista#_emit('filter_'.a:kind, 'before', {'kw': a:kw})
  call mista#filter#apply(a:kind, a:kw)
  call mista#_emit('filter_'.a:kind, 'after', {'kw': a:kw})
endfunction

function! mista#history(dir) abort
  if !exists('b:mista_buffer')
    echo 'Mista: Not in a Mista buffer'
    return
  endif

  call mista#_emit('history_'.a:dir, 'before', {})
  call mista#filter#history_navigate(a:dir)
  call mista#_emit('history_'.a:dir, 'after', {})
endfunction

function! mista#jump() abort
  if !exists('b:mista_buffer')
    echo 'Mista: Not in a Mista buffer'
    return
  endif

  call mista#_emit('jump', 'before', {})
  
  let line = line('.')
  if line <= 2
    return
  endif
  
  let content = getline(line)
  let match = matchstr(content, '⟨\zs\d\+\ze⟩$')
  if empty(match)
    return
  endif
  
  let target_line = str2nr(match)
  let source_bufnr = b:mista_source_bufnr
  
  let winnr = bufwinnr(source_bufnr)
  if winnr > 0
    execute winnr . 'wincmd w'
  else
    if b:mista_mode ==# 'all'
      execute 'tab sbuffer ' . source_bufnr
    else
      wincmd p
      if winnr('$') == 1
        vnew
      endif
      execute 'buffer' source_bufnr
    endif
  endif
  
  call cursor(target_line, 1)
  if g:mista#jump_center
    normal! zz
  endif
  
  call mista#_emit('jump', 'after', {'line': target_line})
endfunction

function! mista#close() abort
  if !exists('b:mista_buffer')
    echo 'Mista: Not in a Mista buffer'
    return
  endif
  
  if exists('b:mista_source_bufnr')
    let g:mista#mista_cursor_pos[b:mista_source_bufnr] = line('.')
    
    let g:mista#buffer_state[b:mista_source_bufnr] = {
      \ 'matches': b:mista_matches,
      \ 'original': b:mista_original_matches,
      \ 'filter_history': b:mista_filter_history,
      \ 'index': b:mista_filter_history_index,
      \ 'title': b:mista_title,
      \ 'filter_commands': b:mista_filter_commands
      \ }
  endif
  
  if exists('b:mista_saved_conceallevel')
    let &conceallevel = b:mista_saved_conceallevel
  endif
  if exists('b:mista_saved_concealcursor')
    let &concealcursor = b:mista_saved_concealcursor
  endif
  
  call mista#_emit('close', 'before', {})
  bwipeout
  call mista#_emit('close', 'after', {})
endfunction

function! mista#render_current() abort
  if !exists('b:mista_buffer')
    echo 'Mista: Not in a Mista buffer'
    return
  endif
  
  call mista#render#redraw()
endfunction

function! mista#debug_info() abort
  echo '=== Mista Debug Info ==='
  echo 'Current buffer:' bufnr('%')
  
  if exists('b:mista_buffer')
    echo 'Mista buffer: yes'
    echo 'Source buffer:' b:mista_source_bufnr
    echo 'Mode:' b:mista_mode
    echo 'Title:' b:mista_title
    echo 'Matches count:' len(b:mista_matches)
    echo 'Filter history depth:' len(b:mista_filter_history)
    echo 'Filter index:' b:mista_filter_history_index
  else
    echo 'Mista buffer: no'
    echo 'Saved args:' string(g:mista#buffer_args)
    echo 'Saved states:' string(keys(g:mista#buffer_state))
  endif
endfunction
function! mista#_collect(bufnr, mode, arg) abort
  let lines = getbufline(a:bufnr, 1, '$')
  let matches = []
  let line_count = len(lines)

  if line_count > g:mista#max_lines
    echo 'Mista: File too large (' . line_count . ' lines). Set g:mista#max_lines to increase limit.'
    return []
  endif

  if a:mode ==# 'all'
    for i in range(line_count)
      call add(matches, {'line': i + 1, 'text': lines[i]})
    endfor
    
  elseif a:mode ==# 'header'
    let level = len(matchstr(a:arg, '^#\+'))
    if level == 0
      return []
    endif
    if index(g:mista#header_levels, level) < 0
      echo 'Mista: Headers (level ' . level . ') is disabled by g:mista#header_levels'
      return []
    endif
    
    let pattern = '^' . repeat('#', level) . '\s\+'
    for i in range(len(lines))
      if lines[i] =~# pattern
        let text = substitute(lines[i], pattern, '', '')
        call add(matches, {'line': i + 1, 'text': text})
      endif
    endfor
    
  else
    if !exists('s:pattern_cache')
      let s:pattern_cache = {}
    endif

    let cache_key = printf('%s\t%d', a:arg, g:mista#case_sensitive)
    if !has_key(s:pattern_cache, cache_key)
      let escaped = mista#_escape_special_chars(a:arg)
      let s:pattern_cache[cache_key] = g:mista#case_sensitive ? escaped : '\c' . escaped

      if len(s:pattern_cache) > 50
        let s:pattern_cache = {}
        let s:pattern_cache[cache_key] = g:mista#case_sensitive ? escaped : '\c' . escaped
      endif
    endif
    let pattern = s:pattern_cache[cache_key]

    for i in range(line_count)
      if lines[i] =~# pattern
        call add(matches, {'line': i + 1, 'text': lines[i]})
      endif
    endfor
  endif
  
  return matches
endfunction

function! mista#_make_bufname(arg, mode, srcbuf) abort
  let base = empty(a:arg) ? '_Mista' : ('_Mista ' . a:arg)
  return base . ' [buf' . a:srcbuf . ']'
endfunction

function! mista#_open_display_buffer(name, mode, ...) abort
  let existing_bufnr = bufnr(a:name)
  
  if existing_bufnr != -1 && bufexists(existing_bufnr)
    let winnr = bufwinnr(existing_bufnr)
    if winnr > 0
      execute winnr . 'wincmd w'
    else
      if a:mode ==# 'all'
        execute 'tab sbuffer' existing_bufnr
      else
        execute g:mista#open_direction . ' ' . g:mista#sidebar_width . 'vsplit'
        execute 'buffer' existing_bufnr
      endif
    endif
  else
    if a:mode ==# 'all'
      tabnew
    else
      execute g:mista#open_direction . ' ' . g:mista#sidebar_width . 'vnew'
    endif
    
    setlocal buftype=nofile
    setlocal bufhidden=hide
    
    let saved_ei = &eventignore
    set eventignore=all
    try
      execute 'file' fnameescape(a:name)
    finally
      let &eventignore = saved_ei
    endtry
  endif
  setlocal noswapfile
  setlocal nomodifiable
  setlocal nonumber
  setlocal nowrap
  setlocal cursorline
  setlocal nobuflisted
  setlocal signcolumn=no
  setlocal foldcolumn=0
  setlocal nofoldenable
  
  if g:mista#conceal_number
    let b:mista_saved_conceallevel = &conceallevel
    let b:mista_saved_concealcursor = &concealcursor
    setlocal conceallevel=3
    setlocal concealcursor=nvic
  endif
  
  let b:mista_buffer = 1
  if a:0 >= 1
    let b:mista_source_bufnr = a:1
  else
    let b:mista_source_bufnr = bufnr('%')
  endif
  let b:mista_mode = a:mode
endfunction
function! s:_determine_mode(arg) abort
  if empty(a:arg)
    return 'all'
  elseif a:arg =~# '^#\{1,10}$'
    return 'header'
  else
    return 'keyword'
  endif
endfunction

function! s:_make_title(arg, mode) abort
  if a:mode ==# 'all'
    return 'All lines'
  elseif a:mode ==# 'header'
    let level = len(matchstr(a:arg, '^#\+'))
    return 'Headers (level ' . level . ')'
  else
    return 'Search: ' . a:arg
  endif
endfunction
