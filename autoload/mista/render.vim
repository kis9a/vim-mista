function! mista#render#draw(source_bufnr, matches, title) abort
  let b:mista_source_bufnr = a:source_bufnr
  let b:mista_matches = a:matches
  let b:mista_original_matches = copy(a:matches)
  let b:mista_title = a:title
  let b:mista_filter_history = [a:matches]
  let b:mista_filter_history_index = 0
  let b:mista_filter_commands = []
  
  call s:_render_buffer_content(a:matches, a:title)
  
  call s:_apply_syntax()
  
  if has_key(g:mista#mista_cursor_pos, a:source_bufnr)
    let saved_line = g:mista#mista_cursor_pos[a:source_bufnr]
      if saved_line > 0 && saved_line <= line('$')
      execute saved_line
    endif
  endif
endfunction

function! mista#render#restore(source_bufnr, state) abort
  let b:mista_source_bufnr = a:source_bufnr
  let b:mista_matches = a:state.matches
  let b:mista_original_matches = a:state.original
  let b:mista_title = a:state.title
  let b:mista_filter_history = a:state.filter_history
  let b:mista_filter_history_index = a:state.index
  let b:mista_filter_commands = a:state.filter_commands
  
  call s:_render_buffer_content(b:mista_matches, b:mista_title)
  
  call s:_apply_syntax()
  
  if has_key(g:mista#mista_cursor_pos, a:source_bufnr)
    let saved_line = g:mista#mista_cursor_pos[a:source_bufnr]
      if saved_line > 0 && saved_line <= line('$')
      execute saved_line
    endif
  endif
endfunction

function! mista#render#redraw() abort
  if !exists('b:mista_buffer')
    return
  endif
  
  call s:_render_buffer_content(b:mista_matches, b:mista_title)
  call s:_apply_syntax()
endfunction

function! mista#render#update_matches(matches, title) abort
  if !exists('b:mista_buffer')
    return
  endif
  
  let b:mista_matches = a:matches
  let b:mista_title = a:title
  call s:_render_buffer_content(a:matches, a:title)
  call s:_apply_syntax()
endfunction

function! s:_render_buffer_content(matches, title) abort
  setlocal modifiable

  let save_cursor = getpos('.')

  if line('$') == 1 && getline(1) == ''
    let lines = []
    call add(lines, '# ' . a:title)
    call add(lines, '')

    for match in a:matches
      let display_text = match.text
      let display_text .= ' ⟨' . match.line . '⟩'
      call add(lines, display_text)
    endfor

    call setline(1, lines)
  else
    silent! %delete _

    let lines = []
    call add(lines, '# ' . a:title)
    call add(lines, '')

    for match in a:matches
      let display_text = match.text
      let display_text .= ' ⟨' . match.line . '⟩'
      call add(lines, display_text)
    endfor

    call setline(1, lines)
  endif

  if save_cursor[1] <= line('$')
    call setpos('.', save_cursor)
  endif

  setlocal nomodifiable
endfunction

function! s:_apply_syntax() abort
  if !exists('b:mista_syntax_defined')
    syntax clear

    syntax match MistaTitle /^#.*$/
    highlight default link MistaTitle Title

    syntax match MistaLineNumber /⟨\d\+⟩$/ conceal
    highlight default link MistaLineNumber Comment

    if exists('b:mista_source_bufnr')
      let source_ft = getbufvar(b:mista_source_bufnr, '&filetype')
      if source_ft ==# 'markdown' && !exists('b:mista_markdown_syntax')
        syntax match MistaHeader1 /^#\s.*$/
        syntax match MistaHeader2 /^##\s.*$/
        syntax match MistaHeader3 /^###\s.*$/
        syntax match MistaHeader4 /^####\s.*$/
        syntax match MistaHeader5 /^#####\s.*$/
        syntax match MistaHeader6 /^######\s.*$/

        highlight default link MistaHeader1 markdownH1
        highlight default link MistaHeader2 markdownH2
        highlight default link MistaHeader3 markdownH3
        highlight default link MistaHeader4 markdownH4
        highlight default link MistaHeader5 markdownH5
        highlight default link MistaHeader6 markdownH6

        let b:mista_markdown_syntax = 1
      endif
    endif

    let b:mista_syntax_defined = 1
  endif
endfunction
