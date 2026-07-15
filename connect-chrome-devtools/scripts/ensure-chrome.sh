#!/bin/sh

set -eu

if [ "$#" -gt 1 ]; then
  echo "Usage: ensure-chrome.sh [timeout-seconds]" >&2
  exit 2
fi

timeout_seconds="${1:-15}"
case "$timeout_seconds" in
  ''|*[!0-9]*|0)
    echo "timeout-seconds must be a positive integer" >&2
    exit 2
    ;;
esac

if [ "$(/usr/bin/uname -s)" != "Darwin" ]; then
  echo "ensure-chrome.sh currently supports macOS only" >&2
  exit 3
fi

user_id="$(/usr/bin/id -u)"

chrome_is_running() {
  /usr/bin/pgrep -u "$user_id" -x "Google Chrome" >/dev/null 2>&1
}

chrome_has_disallowed_flags() {
  for process_id in $(/usr/bin/pgrep -u "$user_id" -x "Google Chrome"); do
    command_line="$(/bin/ps -p "$process_id" -o command= 2>/dev/null || true)"
    if [ -z "$command_line" ]; then
      continue
    fi

    case "$command_line" in
      *--user-data-dir*|*--remote-debugging-port*|*--remote-debugging-pipe*)
        return 0
        ;;
    esac
  done

  return 1
}

if chrome_is_running; then
  if chrome_has_disallowed_flags; then
    echo "Google Chrome is running with a custom profile or remote-debugging flag; refusing to treat it as the normal session" >&2
    exit 6
  fi

  if chrome_is_running; then
    echo "Google Chrome is already running"
    exit 0
  fi
fi

if ! /usr/bin/open -Rb "com.google.Chrome"; then
  echo "Google Chrome is not installed as a macOS application" >&2
  exit 4
fi

echo "Starting Google Chrome"
/usr/bin/open -b "com.google.Chrome"

elapsed=0
while [ "$elapsed" -lt "$timeout_seconds" ]; do
  if chrome_is_running; then
    if chrome_has_disallowed_flags; then
      echo "Google Chrome started with a custom profile or remote-debugging flag; refusing to treat it as the normal session" >&2
      exit 6
    fi

    # Let Chrome finish its cold-start initialization before the MCP probe.
    /bin/sleep 3
    echo "Google Chrome is running"
    exit 0
  fi

  /bin/sleep 1
  elapsed=$((elapsed + 1))
done

if chrome_is_running; then
  if chrome_has_disallowed_flags; then
    echo "Google Chrome started with a custom profile or remote-debugging flag; refusing to treat it as the normal session" >&2
    exit 6
  fi

  /bin/sleep 3
  echo "Google Chrome is running"
  exit 0
fi

echo "Google Chrome did not start within ${timeout_seconds} seconds" >&2
exit 5
