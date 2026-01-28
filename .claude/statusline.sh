#!/bin/bash
input=$(cat)
model=$(echo "$input" | jq -r '.model.display_name // "Claude"')
cwd=$(echo "$input" | jq -r '.workspace.current_dir // empty')
dir=$(basename "$cwd" 2>/dev/null || echo "$cwd")

# Context usage
usage=$(echo "$input" | jq '.context_window.current_usage')
ctx=""
if [ "$usage" != "null" ] && [ -n "$usage" ]; then
  current=$(echo "$usage" | jq '.input_tokens + .cache_creation_input_tokens + .cache_read_input_tokens')
  size=$(echo "$input" | jq '.context_window.context_window_size')
  if [ "$size" -gt 0 ] 2>/dev/null; then
    pct=$((current * 100 / size))
    ctx=" ${pct}%"
  fi
fi

printf '\033[32m%s\033[0m:\033[34m%s\033[0m %s%s' "$(whoami)@$(hostname -s)" "$dir" "$model" "$ctx"
