# Security Evaluation: Paperclip + Supabase on Unraid

## Context
Marc wants to test-deploy Paperclip (AI agent orchestration) on his Unraid server and is evaluating whether self-hosted Supabase could replace Paperclip's bundled PostgreSQL. Both projects need a security evaluation before deployment.

---

## 1. Paperclip Evaluation

**Project:** [paperclipai/paperclip](https://github.com/paperclipai/paperclip) — AI agent orchestration platform
**Stack:** Node.js, React, PostgreSQL 17, TypeScript
**Reputation:** 43.9k stars, 57 contributors, actively maintained (last release March 25, 2026), MIT licence

### Positive Findings
- No telemetry or phone-home behaviour
- Runs as non-root (proper privilege de-escalation via `gosu`)
- API keys hashed before storage
- PII redaction in logs
- Frozen lockfile (`pnpm install --frozen-lockfile`)
- No suspicious dependencies
- Company-level data isolation enforced

### Issues to Address

| Severity | Issue | Fix |
|----------|-------|-----|
| **CRITICAL** | Default DB credentials `paperclip:paperclip` | Use strong random password |
| **CRITICAL** | `BETTER_AUTH_SECRET` must be set | `openssl rand -base64 32` |
| **CRITICAL** | DB port 5432 exposed to host | Remove mapping or bind to `127.0.0.1` |
| **HIGH** | Unpinned `@latest` global npm packages in Dockerfile | Pin specific versions on rebuild |
| **HIGH** | No TLS built-in | Deploy behind reverse proxy |
| **MEDIUM** | Auto-migrations enabled by default | Disable after initial setup |

**Verdict:** Safe to deploy for testing with configuration fixes. No code-level vulnerabilities found.

---

## 2. Supabase Evaluation

**Project:** [supabase/supabase](https://github.com/supabase/supabase) — open-source Firebase alternative
**Stack:** PostgreSQL 15/17, Kong API gateway, GoTrue auth, PostgREST, Realtime (Erlang), Deno edge functions
**Reputation:** Massive community, well-established, professionally maintained

### Architecture (14 containers)
| Service | Purpose | Port |
|---------|---------|------|
| PostgreSQL | Main database | 5432 |
| Kong | API gateway | 8000/8443 |
| GoTrue (Auth) | Authentication | 9999 |
| PostgREST | REST API | 3000 |
| Realtime | WebSocket subscriptions | 4000 |
| Storage | File storage API | 5000 |
| Studio | Web dashboard | 3000 |
| Supavisor | Connection pooling | 5432/6543 |
| Edge Functions | Deno runtime | dynamic |
| Logflare | Analytics/logging | 4000 |
| Meta | DB admin API | 8080 |
| ImgProxy | Image transforms | 5001 |
| Vector | Log collection | 9001 |
| Mail | SMTP (optional) | 2500 |

### Positive Findings
- No telemetry or phone-home in self-hosted mode
- Comprehensive auth system (JWT, OAuth, MFA support)
- Row-Level Security available at PostgreSQL level
- Kong API gateway provides routing/rate-limiting
- Well-documented security hardening options
- Includes `generate-keys.sh` script for credential generation

### Issues to Address

| Severity | Issue | Fix |
|----------|-------|-----|
| **CRITICAL** | All default credentials are demo values | Run `generate-keys.sh` before first start |
| **CRITICAL** | Dashboard uses `supabase:this_password_is_insecure...` | Strong credentials required |
| **CRITICAL** | DB port 5432 exposed on `0.0.0.0` | Firewall or bind to localhost |
| **CRITICAL** | No TLS by default (HTTP only) | Configure Kong SSL certs or use reverse proxy |
| **CRITICAL** | All DB service roles share one password | Use strong password (not configurable separately) |
| **HIGH** | RLS disabled by default on all tables | Enable per table with policies |
| **HIGH** | No automated backups included | Set up `pg_dump` cron job |
| **MEDIUM** | No inter-container encryption | Acceptable for single-host |

### Resource Requirements
- **RAM:** 2-4 GB minimum idle, 8-16 GB recommended
- **CPU:** 4 cores minimum
- **Disk:** Varies by data volume

### Known CVEs
- **Email link poisoning** — strip `X-Forwarded-Host` headers
- **CVE-2024-24213** — SQL injection in pg_meta (vendor considers it intended dashboard feature)
- **Auth UUID validation** — fixed in auth-js 2.69.1+

**Verdict:** Safe to deploy for testing with significant configuration hardening. More complex than Paperclip (14 vs 2 containers), but well-engineered.

---

## 3. Can Supabase Replace Paperclip's PostgreSQL?

**Short answer: Yes, technically feasible but probably not worth the complexity for a test deployment.**

### Compatibility
| Concern | Status |
|---------|--------|
| Standard `DATABASE_URL` connection | Works — standard postgres:// protocol |
| PostgreSQL version | Compatible — Supabase supports PG 17 |
| RLS interference | No issue — RLS is disabled by default on new tables |
| Port access | Standard 5432 via Supavisor |
| Custom database creation | Possible via SQL, but won't appear in Studio dashboard |
| Performance | Equivalent to standalone PostgreSQL |

### Why You Probably Shouldn't (for test deployment)

1. **Massive overhead** — Supabase runs 14 containers consuming 2-8 GB RAM just to provide a PostgreSQL instance that Paperclip's bundled PG 17 Alpine already provides in one lightweight container
2. **Added attack surface** — 14 services vs 1 means 14x the potential vulnerabilities
3. **Configuration complexity** — Supabase requires significant hardening; Paperclip's bundled PG just needs a password change
4. **No benefit for Paperclip** — Paperclip doesn't use Supabase's Auth, Storage, Realtime, or REST API features. You'd be running 13 unused services.

### When Supabase WOULD Make Sense
- You're already running Supabase for other projects and want to consolidate databases
- You plan to build additional apps that leverage Supabase's Auth/Storage/Realtime features
- You want the Studio dashboard for visual database management

---

## Recommended Deployment Approach

### Option A: Paperclip Standalone (Recommended for Test)
- Deploy Paperclip with its bundled PostgreSQL
- Fix the 3 critical config issues (DB password, auth secret, port binding)
- Put behind Nginx Proxy Manager for HTTPS
- Simplest path, lowest resource usage (~1-2 GB RAM)

### Option B: Paperclip + Supabase (If You Want Both)
- Deploy Supabase separately with full hardening
- Point Paperclip's `DATABASE_URL` at Supabase's PostgreSQL
- Remove Paperclip's `db` service from its docker-compose
- Higher resource usage (~4-10 GB RAM total)
- Only worthwhile if you have other uses for Supabase

### Option C: Supabase Only (No Paperclip)
- If the goal is a general-purpose backend platform rather than AI agent orchestration

---

## Verification Steps (Post-Deployment)
1. Confirm no services are exposed on WAN (port scan from external)
2. Verify HTTPS is working via reverse proxy
3. Test authentication — ensure default credentials are rejected
4. Confirm database is not accessible from LAN without credentials
5. Check container logs for unexpected outbound connections
6. Run `docker exec` into PostgreSQL and verify password was changed
