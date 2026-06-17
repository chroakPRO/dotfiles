# VIM Keybinds Documentation

## Leader Key
- **Leader**: `<Space>` (Space bar)

## File and Buffer Navigation

| Key Binding | Description |
|-------------|-------------|
| `<leader>pv` | Opens the file explorer in the current window |
| `<leader>vpp` | Opens the Packer configuration file for editing |

## Fuzzy Finder (Telescope)

| Key Binding | Description |
|-------------|-------------|
| `<leader>pf` | Find files in current working directory |
| `<C-p>` | Find files in Git repository |
| `<leader>pws` | Grep for current word under cursor |
| `<leader>pWs` | Grep for current WORD under cursor |
| `<leader>ps` | Manual search term input |

## Harpoon

| Key Binding | Description |
|-------------|-------------|
| `<leader>a` | Add current file to Harpoon |
| `<leader><C-1>` | Open Harpoon item 1 |
| `<leader><C-2>` | Open Harpoon item 2 |
| `<leader><C-3>` | Open Harpoon item 3 |
| `<leader><C-4>` | Open Harpoon item 4 |
| `<C-S-P>` | Previous Harpoon item |
| `<C-S-N>` | Next Harpoon item |
| `<leader>e` | Open Harpoon Telescope picker |

## Visual Mode Line Movement

| Key Binding | Description |
|-------------|-------------|
| `J` | Move selected block of text one line down |
| `K` | Move selected block of text one line up |

## Normal Mode Adjustments

| Key Binding | Description |
|-------------|-------------|
| `J` | Join lines without spacing, return to initial cursor position |
| `<C-d>` | Page down while centering screen on cursor |
| `<C-u>` | Page up while centering screen on cursor |
| `n` | Search next while centering screen on match |
| `N` | Search previous while centering screen on match |
| `Q` | Disabled (no Ex mode entry) |
| `<C-f>` | Trigger tmux command |
| `<leader>f` | Format current buffer using LSP formatter |
| `<C-k>` | Navigate to previous compilation error/search result |
| `<C-j>` | Navigate to next compilation error/search result |
| `<leader>k` | Navigate to previous LSP diagnostic message |
| `<leader>j` | Navigate to next LSP diagnostic message |

## Text Manipulation and Clipboard

| Key Binding | Mode | Description |
|-------------|------|-------------|
| `<leader>p` | Visual | Delete selection and paste without yanking |
| `<leader>y` | Normal/Visual | Yank selection to system clipboard |
| `<leader>Y` | Normal | Yank line to system clipboard |
| `<leader>d` | Normal/Visual | Delete without yanking |
| `<C-c>` | Insert | Maps to Escape key |

## Development Helpers

| Key Binding | Description |
|-------------|-------------|
| `<leader>s` | Search and replace template with word under cursor |
| `<leader>x` | Make current file executable |
| `<leader>ee` | Insert boilerplate error handling block |
| `<leader>mr` | Execute custom command (project-specific) |

## LSP (Language Server Protocol) Features

| Key Binding | Mode | Description |
|-------------|------|-------------|
| `gd` | Normal | Go to definition |
| `K` | Normal | Show hover information |
| `<leader>vws` | Normal | Workspace symbol search |
| `<leader>vd` | Normal | Open float diagnostic window |
| `<leader>vca` | Normal | Code action suggestions |
| `<leader>vrr` | Normal | Show all references |
| `<leader>vrn` | Normal | Rename symbol across workspace |
| `<C-h>` | Insert | Signature help |
| `[d` | Normal | Navigate to previous diagnostic |
| `]d` | Normal | Navigate to next diagnostic |

## CMP Autocomplete

| Key Binding | Mode | Description |
|-------------|------|-------------|
| `<C-k>` | Insert | Select previous suggestion |
| `<C-j>` | Insert | Select next suggestion |
| `<C-b>` | Insert | Scroll docs up |
| `<C-f>` | Insert | Scroll docs down |
| `<C-Space>` | Insert | Show completion suggestions |
| `<C-E>` | Insert | Close completion window |
| `<CR>` | Insert | Confirm selection |

## Plugin-Specific Mappings

| Key Binding | Description |
|-------------|-------------|
| `<leader>vwm` | Start "Vim With Me" plugin session |
| `<leader>svwm` | Stop "Vim With Me" plugin session |

## Miscellaneous

| Key Binding | Description |
|-------------|-------------|
| `<leader><leader>` | Execute `:source` command (reload config) |

## Auto Commands
- Trailing whitespace trimmed on save
- Enhanced yank (copy) highlight feedback

---

*Note: This configuration uses `<Space>` as the leader key. All `<leader>` bindings require pressing the Space bar first.*
