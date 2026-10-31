#!/bin/zsh
# MCP entry point for Claude: starts FilmCraft with its control port (if needed), then serves the
# built-in filmcraft-cli MCP bridge on stdio. Logs go to stderr; stdout belongs to MCP.
set -e
DIR="${0:A:h}"
PORT="${FILMCRAFT_CONTROL_PORT:-9876}"
TOKEN_FILE="$DIR/.token"

# The app and the bridge must share one token; keep it in a file only this user can read.
if [[ ! -s "$TOKEN_FILE" ]]; then
  (umask 077; python3 -c 'import secrets; print(secrets.token_hex(32))' > "$TOKEN_FILE")
fi
export FILMCRAFT_CONTROL_TOKEN="$(<"$TOKEN_FILE")"

if ! nc -z 127.0.0.1 "$PORT" 2>/dev/null; then
  if pgrep -xq FilmCraft; then
    echo "filmcraft-mcp: FilmCraft is running without its control port; quit it and retry" >&2
  else
    nohup /Applications/FilmCraft.app/Contents/MacOS/FilmCraft --control "$PORT" >/dev/null 2>&1 &
    for _ in {1..60}; do nc -z 127.0.0.1 "$PORT" 2>/dev/null && break; sleep 0.5; done
  fi
fi

exec "$DIR/src/target/release/filmcraft-cli" mcp --bridge "127.0.0.1:$PORT"
