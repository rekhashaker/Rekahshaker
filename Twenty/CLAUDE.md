# Project: Twenty — Docker Deployment
# /mnt/user/appdata/twenty-crm/CLAUDE.md
# This file overrides ~/.claude/CLAUDE.md entirely for this project.

## Context
- Project: Twenty (open source CRM) — https://github.com/twentyhq/twenty
- Fork: GitHub public fork (track upstream; never modify upstream source files directly)
- Host: Unraid server — path: /mnt/user/appdata/twenty-crm
- Stack: Docker Compose + custom Dockerfile
- Docs: Changes documented to GitHub repository alongside this project

## Local Customisations
- Custom Dockerfile (extends upstream image — edits go here, not in upstream files)
- Config managed via .env files
- Persistent data in mounted volumes under /mnt/user/appdata/twenty-crm

## Upstream Updates
- Strategy: pull latest upstream image tag
- Before any update: backup volumes (see Hard Rules)
- After any update: verify .env and Dockerfile customisations are still compatible

## Hard Rules (never bypass)
- Never modify upstream source files directly — customisations go in Dockerfile or overrides only
- Always backup volumes before any destructive operation (down, recreate, prune, rm)
- Every local customisation must be logged in CHANGELOG.md in this repo
- Every change that could break the deployment must include rollback steps in CHANGELOG.md

## Changelog Format
File: CHANGELOG.md (in project root)
Entry format:
```
## YYYY-MM-DD — <short description>
- Change: <what was changed>
- Reason: <why>
- Rollback: <exact steps to undo>
```

## Rollback Pattern
1. Stop containers: `docker compose down`
2. Restore volumes from backup
3. Revert Dockerfile / .env to previous state (git)
4. Redeploy: `docker compose up -d`

## Deployment Reference
| Action             | Command                                  |
|--------------------|------------------------------------------|
| Start              | `docker compose up -d`                   |
| Stop               | `docker compose down`                    |
| Rebuild            | `docker compose up -d --build`           |
| Pull latest image  | `docker compose pull && docker compose up -d` |
| View logs          | `docker compose logs -f`                 |
| Backup volumes     | `tar -czf twenty-backup-$(date +%F).tar.gz /mnt/user/appdata/twenty-crm` |

## Git Workflow
- Repo tracks: Dockerfile, docker-compose.yml, .env.example, CHANGELOG.md
- Never commit .env (add to .gitignore)
- Commit message format: `[twenty] <short description>`
- Push to GitHub after every meaningful change or before any destructive operation

## Communication
- Concise responses. Skip Docker basics.
- When suggesting changes: state impact on running containers and whether a rebuild is required.
- Flag any change that touches volumes or would cause downtime before proceeding.
