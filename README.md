# Unblock Labs Fleet Prompt

`UNBLOCKLABS.md` is the canonical, public operating constitution for Unblock Labs agents. Each node reconciles the latest `main` revision into its OpenClaw workspace as `.unblocklabs/AGENTS.md`.

Agent-specific `AGENTS.md`, `SOUL.md`, `IDENTITY.md`, and `TOOLS.md` files remain local and personalized.

## OpenClaw configuration

Enable the bundled `bootstrap-extra-files` hook and add the deployed file:

```json
{
  "hooks": {
    "internal": {
      "enabled": true,
      "entries": {
        "bootstrap-extra-files": {
          "enabled": true,
          "paths": [".unblocklabs/AGENTS.md"]
        }
      }
    }
  }
}
```

OpenClaw only injects recognized bootstrap basenames, which is why the canonical `UNBLOCKLABS.md` is deployed as `.unblocklabs/AGENTS.md`.

## Node reconciliation

Run the sync script with the node's workspace path:

```bash
./scripts/sync-unblocklabs-prompt.sh /path/to/.openclaw/workspace
```

The script fetches `main`, validates the document, updates the deployed copy atomically, and records the exact commit in `.unblocklabs/DEPLOYED_SHA`. It exits without writing when the node is already current.

The launchd example runs reconciliation at login and every five minutes. Replace its three placeholders with absolute paths before loading it.

## Verification

- Confirm `.unblocklabs/DEPLOYED_SHA` matches the repository's current `main` SHA.
- Run `/context detail` in an OpenClaw session and confirm `.unblocklabs/AGENTS.md` appears in injected workspace context.
