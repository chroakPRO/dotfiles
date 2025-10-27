# If you come from bash you might have to change your $PATH.
# export PATH=$HOME/bin:$HOME/.local/bin:/usr/local/bin:$PATH

# Prioritize conda Python
export PATH="/Users/chek/miniconda/bin:$PATH"

# Path to your Oh My Zsh installation.
export ZSH="$HOME/.oh-my-zsh"

# Set name of the theme to load --- if set to "random", it will
# load a random theme each time Oh My Zsh is loaded, in which case,
# to know which specific one was loaded, run: echo $RANDOM_THEME
# See https://github.com/ohmyzsh/ohmyzsh/wiki/Themes
ZSH_THEME="robbyrussell"

# Set list of themes to pick from when loading at random
# Setting this variable when ZSH_THEME=random will cause zsh to load
# a theme from this variable instead of looking in $ZSH/themes/
# If set to an empty array, this variable will have no effect.
# ZSH_THEME_RANDOM_CANDIDATES=( "robbyrussell" "agnoster" )

# Uncomment the following line to use case-sensitive completion.
# CASE_SENSITIVE="true"

# Uncomment the following line to use hyphen-insensitive completion.
# Case-sensitive completion must be off. _ and - will be interchangeable.
# HYPHEN_INSENSITIVE="true"

# Uncomment one of the following lines to change the auto-update behavior
# zstyle ':omz:update' mode disabled  # disable automatic updates
# zstyle ':omz:update' mode auto      # update automatically without asking
# zstyle ':omz:update' mode reminder  # just remind me to update when it's time

# Uncomment the following line to change how often to auto-update (in days).
# zstyle ':omz:update' frequency 13

# Uncomment the following line if pasting URLs and other text is messed up.
# DISABLE_MAGIC_FUNCTIONS="true"

# Uncomment the following line to disable colors in ls.
# DISABLE_LS_COLORS="true"

# Uncomment the following line to disable auto-setting terminal title.
# DISABLE_AUTO_TITLE="true"

# Uncomment the following line to enable command auto-correction.
# ENABLE_CORRECTION="true"

# Uncomment the following line to display red dots whilst waiting for completion.
# You can also set it to another string to have that shown instead of the default red dots.
# e.g. COMPLETION_WAITING_DOTS="%F{yellow}waiting...%f"
# Caution: this setting can cause issues with multiline prompts in zsh < 5.7.1 (see #5765)
# COMPLETION_WAITING_DOTS="true"

# Uncomment the following line if you want to disable marking untracked files
# under VCS as dirty. This makes repository status check for large repositories
# much, much faster.
# DISABLE_UNTRACKED_FILES_DIRTY="true"

# Uncomment the following line if you want to change the command execution time
# stamp shown in the history command output.
# You can set one of the optional three formats:
# "mm/dd/yyyy"|"dd.mm.yyyy"|"yyyy-mm-dd"
# or set a custom format using the strftime function format specifications,
# see 'man strftime' for details.
# HIST_STAMPS="mm/dd/yyyy"

# Would you like to use another custom folder than $ZSH/custom?
# ZSH_CUSTOM=/path/to/new-custom-folder

# Which plugins would you like to load?
# Standard plugins can be found in $ZSH/plugins/
# Custom plugins may be added to $ZSH_CUSTOM/plugins/
# Example format: plugins=(rails git textmate ruby lighthouse)
# Add wisely, as too many plugins slow down shell startup.
plugins=(git)

source $ZSH/oh-my-zsh.sh

# User configuration

# export MANPATH="/usr/local/man:$MANPATH"

# You may need to manually set your language environment
# export LANG=en_US.UTF-8

# Preferred editor for local and remote sessions
# if [[ -n $SSH_CONNECTION ]]; then
#   export EDITOR='vim'
# else
#   export EDITOR='nvim'
# fi

# Compilation flags
# export ARCHFLAGS="-arch $(uname -m)"

# Set personal aliases, overriding those provided by Oh My Zsh libs,
# plugins, and themes. Aliases can be placed here, though Oh My Zsh
# users are encouraged to define aliases within a top-level file in
# the $ZSH_CUSTOM folder, with .zsh extension. Examples:
# - $ZSH_CUSTOM/aliases.zsh
# - $ZSH_CUSTOM/macos.zsh
# For a full list of active aliases, run `alias`.
#
# Example aliases
# alias zshconfig="mate ~/.zshrc"
# alias ohmyzsh="mate ~/.oh-my-zsh"

# >>> conda initialize >>>
# !! Contents within this block are managed by 'conda init' !!
__conda_setup="$('/Users/chek/miniconda/bin/conda' 'shell.zsh' 'hook' 2> /dev/null)"
if [ $? -eq 0 ]; then
    eval "$__conda_setup"
else
    if [ -f "/Users/chek/miniconda/etc/profile.d/conda.sh" ]; then
        . "/Users/chek/miniconda/etc/profile.d/conda.sh"
    else
        export PATH="/Users/chek/miniconda/bin:$PATH"
    fi
fi
unset __conda_setup
# <<< conda initialize <<<

eval "$(zoxide init zsh)"

[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh


zof() {
  local dir
  dir=$(zoxide query -l | fzf --height 40% --reverse --prompt="zoxide > ")
  [ -n "$dir" ] && cd "$dir"
}

export PATH="/opt/homebrew/opt/ruby/bin:$PATH"

# opencode
export PATH=/Users/chek/.opencode/bin:$PATH

# bun completions
[ -s "/Users/chek/.bun/_bun" ] && source "/Users/chek/.bun/_bun"

# bun
export BUN_INSTALL="$HOME/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"
alias sshp='ssh -o PreferredAuthentications=password'
alias scpp='scp -o PreferredAuthentications=password'

# Final PATH override - ensure conda comes first
export PATH="/Users/chek/miniconda/bin:$PATH"

# --- dnsrecon helpers (records-only, no transfers) -------------------

# Avoid alias/function name collisions
unalias dnscheck 2>/dev/null
unalias dnscheck_save 2>/dev/null

# Resolve a usable dnsrecon command:
_dnsrecon_cmd() {
  local candidates=(
    dnsrecon
    dnsrecon.py
    "$HOME/Documents/Github/dnsrecon/dnsrecon.py"
  )

  local c
  for c in "${candidates[@]}"; do
    if command -v "$c" >/dev/null 2>&1; then
      echo "$c"
      return 0
    fi
    if [ -f "$c" ]; then
      if [ -x "$c" ]; then
        echo "$c"
      else
        echo "python3 $c"
      fi
      return 0
    fi
  done
  return 1
}

# Default wordlist path (optional - used only if present)
_dns_wordlist="${HOME}/.dnsrecon/wordlists/subdomains.txt"

# -------------------------
# dnscheck: console-only, records-only (no AXFR/zonewalk)
# Usage: dnscheck example.com
# Performs: std enumeration (SOA/NS/A/AAAA/MX/SRV) + passive crt.sh, Bing, Yandex
# -------------------------
dnscheck() {
  if [ -z "$1" ]; then
    echo "Usage: dnscheck <domain>"
    return 1
  fi

  local domain="$1"
  local threads=30
  local lifetime=3.0
  local cmd
  cmd="$(_dnsrecon_cmd)" || { echo "dnsrecon not found. Put it in \$PATH or clone it under ~/Documents/Github/dnsrecon/"; return 1; }

  local extra=()
  if [ -f "$_dns_wordlist" ]; then
    # optional brute force if you want; comment out the next line to skip brute forcing
    extra=(-D "$_dns_wordlist" -f)
  fi

  echo "== DNSrecon records-only analysis (no transfers) for: $domain =="
  # Use explicit type 'std' to avoid AXFR/zonewalk and keep output concise
  eval "$cmd" -d "\"$domain\"" -t std \
    -k -b -y \
    "${extra[@]}" \
    --threads "$threads" --lifetime "$lifetime" -v
}

# -------------------------
# dnscheck_save: console + save JSON/DB/log, records-only
# Usage: dnscheck_save example.com
# -------------------------
dnscheck_save() {
  if [ -z "$1" ]; then
    echo "Usage: dnscheck_save <domain>"
    return 1
  fi

  local domain="$1"
  local base_dir="$HOME/dnscheck_logs/$domain"
  mkdir -p "$base_dir"
  local ts
  ts=$(date -u +"%Y%m%dT%H%M%SZ")
  local json_file="$base_dir/${domain}_dnsrecon_${ts}.json"
  local db_file="$base_dir/${domain}_dnsrecon_${ts}.db"
  local log_file="$base_dir/${domain}_dnsrecon_${ts}.log"

  local threads=30
  local lifetime=3.0
  local cmd
  cmd="$(_dnsrecon_cmd)" || { echo "dnsrecon not found. Put it in \$PATH or clone it under ~/Documents/Github/dnsrecon/"; return 1; }

  local extra=()
  if [ -f "$_dns_wordlist" ]; then
    # optional brute force; comment out to skip brute forcing
    extra=(-D "$_dns_wordlist" -f)
  fi

  echo "Saving JSON -> $json_file"
  echo "Saving DB   -> $db_file"
  echo "Streaming output to console..."
  eval "$cmd" -d "\"$domain\"" -t std \
    -k -b -y \
    "${extra[@]}" \
    --threads "$threads" --lifetime "$lifetime" -v \
    --db "\"$db_file\"" -j "\"$json_file\"" 2>&1 | tee "$log_file"
}

d