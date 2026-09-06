#!/data/data/com.termux/files/usr/bin/bash
set -euo pipefail

ACTION="${1:-status}"
DISPLAY_ID="${HYDRA_X11_DISPLAY:-:1}"
STATE_DIR="${HYDRA_X11_STATE_DIR:-$HOME/.local/state/hydra-sm-x400-x11}"
PID_FILE="$STATE_DIR/termux-x11.pid"
LOG_FILE="$STATE_DIR/termux-x11.log"

have() { command -v "$1" >/dev/null 2>&1; }

owned_pid() {
  [ -f "$PID_FILE" ] || return 1
  local pid
  pid="$(cat "$PID_FILE" 2>/dev/null || true)"
  [[ "$pid" =~ ^[0-9]+$ ]] || return 1
  [ -r "/proc/$pid/cmdline" ] || return 1
  tr '\0' ' ' < "/proc/$pid/cmdline" | grep -q 'termux-x11' || return 1
  printf '%s\n' "$pid"
}

status() {
  local pid=""
  if pid="$(owned_pid)"; then
    printf '{"display":"%s","running":true,"owned":true,"pid":%s}\n' "$DISPLAY_ID" "$pid"
  else
    printf '{"display":"%s","running":false,"owned":false}\n' "$DISPLAY_ID"
  fi
}

start_x11() {
  if ! have termux-x11; then
    printf '%s\n' 'termux-x11 command is not installed.' >&2
    exit 2
  fi
  if owned_pid >/dev/null 2>&1; then
    status
    exit 0
  fi

  mkdir -p "$STATE_DIR"
  chmod 700 "$STATE_DIR"

  args=("$DISPLAY_ID")
  if [ "${HYDRA_X11_LEGACY:-0}" = "1" ]; then
    args+=("-legacy-drawing")
  fi
  if [ "${HYDRA_X11_FORCE_BGRA:-0}" = "1" ]; then
    args+=("-force-bgra")
  fi

  nohup termux-x11 "${args[@]}" >>"$LOG_FILE" 2>&1 &
  pid=$!
  printf '%s\n' "$pid" > "$PID_FILE"
  chmod 600 "$PID_FILE"
  sleep 1
  status
}

stop_x11() {
  local pid=""
  if ! pid="$(owned_pid)"; then
    rm -f "$PID_FILE"
    printf '{"display":"%s","stopped":false,"reason":"not-owned-or-stale"}\n' "$DISPLAY_ID"
    exit 0
  fi
  kill -TERM "$pid" 2>/dev/null || true
  for _ in 1 2 3 4 5 6 7 8 9 10; do
    [ ! -r "/proc/$pid/cmdline" ] && break
    sleep 0.2
  done
  rm -f "$PID_FILE"
  printf '{"display":"%s","stopped":true,"pid":%s}\n' "$DISPLAY_ID" "$pid"
}

open_activity() {
  if have am; then
    exec am start --user 0 -n com.termux.x11/com.termux.x11.MainActivity
  fi
  printf '%s\n' 'Android activity manager command is unavailable.' >&2
  exit 2
}

case "$ACTION" in
  status) status ;;
  start) start_x11 ;;
  stop) stop_x11 ;;
  open) open_activity ;;
  *)
    printf 'Usage: %s {status|start|stop|open}\n' "$0" >&2
    exit 2
    ;;
esac
