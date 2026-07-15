---
name: connect-chrome-devtools
description: Connect directly to the user's existing, normal Google Chrome session on macOS through the Chrome DevTools MCP server. Use when the user asks to open or use Google Chrome, their usual or default Chrome, a current Chrome tab, an existing signed-in Chrome session, Chrome remote debugging, `chrome-devtools-mcp`, or `--autoConnect`; also use to inspect, control, test, debug, or troubleshoot that live Chrome session. Prefer this skill over starting an in-app, isolated, temporary-profile, Chrome for Testing, or second browser instance when the user's existing Chrome state matters.
---

# Connect Chrome DevTools

Connect to the user's normal Google Chrome session directly and preserve its existing tabs and login state.

## Connect

1. Find the `chrome_devtools` MCP tool family. Load deferred MCP tools if it is not already visible. If the MCP server is unavailable, report that prerequisite; do not substitute another browser.
2. Run `scripts/ensure-chrome.sh` from this skill directory. It starts normal Google Chrome only when absent and never passes profile or debugging flags.
3. Call the discovered `list_pages` tool as the first MCP probe. Its common Codex name is `mcp__chrome_devtools__list_pages`, but use the actual discovered prefix. Do not initialize another browser surface first.
4. When the call returns pages, continue the whole task with the discovered Chrome DevTools MCP tool family and reuse the established MCP session.

Do not restart the MCP server during a working session. A new MCP connection can trigger a new Chrome permission prompt.

## Handle startup and permission

- If normal Chrome returns an immediate connection-refused, browser-not-ready, or missing-target error, wait 2 seconds and retry `list_pages` once. Keep this readiness retry separate from authorization.
- If Chrome shows "Allow remote debugging?" or the MCP call waits for approval, ask the user to click Allow and tell you when it is ready, then end the current turn. Retry `list_pages` once only after the user confirms.
- If the user denies the request, stop. Do not retry repeatedly or bypass the choice.
- Never use accessibility scripting, Computer Use, AppleScript, or synthetic clicks to dismiss the permission dialog unless the user separately and explicitly asks for that security-sensitive workaround.

Chrome 144+ intentionally requires approval for each new `--autoConnect` debugging connection to the user's regular profile. There is currently no supported persistent approval or silent-allow setting. Keep connections long-lived to minimize prompts.

## Diagnose safely

If the bounded attempts fail, check only these prerequisites:

1. Google Chrome 144 or later is running.
2. `chrome://inspect/#remote-debugging` has Remote Debugging enabled.
3. The MCP client has an enabled `chrome-devtools` server configured with `--autoConnect` and the correct channel.
4. No competing MCP server or debugging client is repeatedly reconnecting.

Report the failing prerequisite and stop. Do not silently switch to the in-app browser, the Chrome extension browser client, standalone Playwright, or Computer Use.

Never launch Chrome for Testing, an isolated or temporary profile, a non-default `--user-data-dir`, or a second Chrome instance with `--remote-debugging-port`, `--remote-debugging-pipe`, `--browser-url`, or `--ws-endpoint`. Do not close or restart the user's Chrome to troubleshoot without explicit permission.
