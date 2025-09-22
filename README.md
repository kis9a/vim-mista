# vim-mista

A universal file navigator for Vim with interactive filtering capabilities.

Mista provides a powerful way to navigate any text file by **extracting results into a dedicated buffer**, then **interactively filtering** and **jumping** back to the source.

## Why Mista (vs. plain `/` search)?

* `/` moves your cursor through matches, one by one.
* **Mista** shows **all matches at once** in a results buffer → you can **keep/reject** with filters, **travel history** (undo/redo of filters), and **jump** to the source lines when ready.

**TL;DR:** *Search becomes a navigable view with memory.*

## Features

* **Universal file support**: Works with any text file, not just Markdown
* **Multiple extraction modes**: View all lines, search by keyword, or extract Markdown headers
* **Interactive filtering**: Keep/Reject with full history navigation (back/forward)
* **Smart navigation**: Jump directly to source locations from the result buffer
* **Customizable keymaps**: Define buffer-local mappings via a dictionary
* **Event hooks**: Run custom functions before/after operations
* **State persistence**: Remembers filter state and cursor position when toggling
* **Markdown-aware**: Header extraction and helpful highlighting for Markdown

## Installation

Install the plugin using your preferred plugin manager:

Example with [vim-plug](https://github.com/junegunn/vim-plug):
```vim
" vim-plug
Plug 'kis9a/vim-mista'
```

## Quick Start

1. **Add key mappings** to your `.vimrc`:

```vim
nnoremap <Leader>M :Mista!<CR>              " Toggle Mista
nnoremap <Leader>m1 :Mista #<CR>            " Show level 1 headers
nnoremap <Leader>m2 :Mista ##<CR>           " Show level 2 headers
nnoremap <Leader>ms :Mista                  " Search (type keyword after)
```

2. **Open any file**:

```vim
:edit README.md     " Markdown file
:edit script.py     " Python file
:edit config.json   " JSON file
" Works with any text file!
```

3. **Try these commands**:
   - `<Leader>M` - Toggle Mista navigator (works with any file)
   - `<Leader>m1` - Show headers in sidebar (Markdown only)
   - `:Mista TODO` - Search for "TODO" items (all file types)
   - `:Mista function` - Search for "function" in code files

4. **In the Mista buffer**, use:
   - `<CR>` - Jump to source
   - `mk` - Keep filter  
   - `mr` - Reject filter
   - `mq` - Close buffer
   - `mh` - Show help

## Commands

### Main Commands

| Command | Description |
|---------|-------------|
| `:Mista[!] [arg]` | Open Mista buffer. Without arg: show all lines. With `#`/`##`/etc: show headers. With text: search. With `!`: toggle |
| `:MistaJump` | Jump to the source location of the current line |
| `:MistaClose` | Close the Mista buffer |
| `:MistaKeep {keyword}` | Keep only lines containing the keyword |
| `:MistaReject {keyword}` | Reject lines containing the keyword |
| `:MistaPrev` | Navigate to previous filter state |
| `:MistaNext` | Navigate to next filter state |
| `:MistaRedraw` | Redraw the current buffer |
| `:MistaConfig {key} [{value}]` | Get or set configuration values |
| `:MistaInfo` | Display debug information |
| `:MistaHelp` | Show help for buffer mappings in Mista buffer |

### Usage Examples

```vim
" Show all lines in a new tab (works with any file)
:Mista

" Show only level 2 headers in sidebar (Markdown only)
:Mista ##

" Search for lines containing "TODO" (all file types)
:Mista TODO

" Search for function definitions in code files
:Mista function

" Search for class definitions
:Mista class

" Toggle Mista buffer
:Mista!
```

## Configuration

Add these to your `.vimrc` to customize Mista:

```vim
" Supported filetypes (default: all)
" Empty array = all filetypes supported
let g:mista#filetypes = []

" Or restrict to specific filetypes
let g:mista#filetypes = ['markdown', 'vim', 'python', 'javascript']

" Sidebar width when opening headers/search results
let g:mista#sidebar_width = 40

" Conceal line numbers at end of lines
let g:mista#conceal_number = 1

" Case sensitivity for searches
let g:mista#case_sensitive = 0

" Center screen after jumping
let g:mista#jump_center = 1

" Recognized header levels
let g:mista#header_levels = range(1, 10)

" Direction for opening sidebar
let g:mista#open_direction = 'leftabove'
```

## Keymaps

### Default Buffer-Local Mappings

Inside a Mista buffer, these mappings are available:

| Key | Action |
|-----|--------|
| `<CR>` | Jump to source location |
| `mq` | Close Mista buffer |
| `mp` | Go to previous filter state |
| `mn` | Go to next filter state |
| `mk` | Keep filter (prompts for keyword) |
| `mr` | Reject filter (prompts for keyword) |
| `mh` | Show help for Mista buffer mappings |

### Customizing Keymaps

You can override specific mappings while keeping others:

```vim
" Override specific buffer mappings
let g:mista#buffer_keymaps = {
  \ '<CR>': {'mode': 'n', 'rhs': ':echo "preview"<CR>', 'opts': '<silent>'},
  \ 'K':    {'mode': 'n', 'rhs': ':MistaKeep ',         'opts': ''},
  \ 'R':    {'mode': 'n', 'rhs': ':MistaReject ',       'opts': ''},
  \ 'q':    {'mode': 'n', 'rhs': ':MistaClose<CR>',     'opts': '<silent>'},
  \ }

" Add your own global mapping to open Mista
nnoremap <Leader>M :Mista!<CR>
```

## Advanced Features

### Filter History

Mista maintains a history of your filters, allowing you to navigate back and forth through different filter states:

1. Apply multiple filters sequentially
2. Use `mp` to go back to previous states
3. Use `mn` to go forward in history
4. New filters from a past state create a branch (forward history is truncated)

### Event Hooks

Execute custom functions at specific stages of Mista operations:

```vim
let g:mista#hooks = {
  \ 'open': [
  \   {
  \     'hook': 'echo "Opening Mista"',
  \     'stage': 'before',
  \     'priority': 10
  \   },
  \   {
  \     'hook': function('MyOpenHandler'),
  \     'stage': 'after',
  \     'priority': 20
  \   }
  \ ],
  \ 'jump': [
  \   {
  \     'hook': function('MyJumpHandler'),
  \     'stage': 'before',
  \     'priority': 10
  \   }
  \ ]
  \ }
```

Available events:
- `open`, `close`: Buffer lifecycle
- `jump`: Navigation to source
- `filter_keep`, `filter_reject`: Filtering operations
- `history_prev`, `history_next`: History navigation

### Workflow Examples

#### Code Review Workflow

```vim
" Open any code file
:edit main.py

" Search for all TODO comments
:Mista TODO

" Further filter to specific function
:MistaKeep process_data

" Jump to each item with <CR>
" Go back to previous filter with mp
```

#### Markdown Documentation

```vim
" Open a markdown file with review notes
:edit review.md

" Show all TODO headers
:Mista ## 
:MistaKeep TODO

" Further filter to high priority items
:MistaKeep HIGH
```

#### Documentation Navigation

```vim
" Open documentation
:edit docs/api.md

" Show all level 2 headers (main sections)
:Mista ##

" Filter to configuration-related sections
:MistaKeep config

" Jump to section with <CR>
```

#### Meeting Notes Organization

```vim
" Open meeting notes
:edit meetings/2024.md

" Search for action items
:Mista action

" Filter by person
:MistaKeep @john

" Navigate through filtered results
```

## Tips and Tricks

1. **Header Overview**: Use `:Mista ##` for a quick document outline

2. **Progressive Filtering**: Start broad, then narrow down with multiple filters

3. **Case-Insensitive Search**: Searches are case-insensitive by default. Set `g:mista#case_sensitive = 1` to change this

4. **Combine with Other Plugins**: Works great with markdown preview plugins for a complete markdown workflow

## File Type Support

### Universal Features (All File Types)
- `:Mista` - View all lines
- `:Mista keyword` - Search for specific keywords
- Keep/Reject filtering
- Filter history navigation
- State persistence

### Markdown-Specific Features
- `:Mista ##` - Extract headers by level
- Markdown syntax highlighting in results
- ATX-style headers support (`#` symbols)

Note: Setext-style headers (underlined) are not yet supported

## Testing

The plugin includes a comprehensive test suite using [vim-themis](https://github.com/thinca/vim-themis):

```bash
# Install test framework
make init

# Run tests
make test
```

## Contributing

Contributions are welcome! Please ensure:
- All tests pass
- New features include tests
- Code follows the existing style
- Documentation is updated

## License

This project is licensed under the MIT License - see the LICENSE file for details.
