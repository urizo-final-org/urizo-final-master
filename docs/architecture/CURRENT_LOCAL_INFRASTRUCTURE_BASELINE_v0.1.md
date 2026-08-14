# AX Module Studio current local infrastructure baseline v0.1

> Observed: 2026-08-14 (Asia/Seoul) from fetched canonical `origin/dev` refs
> Backend: `e0a702dbfaf6f1c46d9ba21e88a08c013047e2fb`
> Frontend: `0ba4295cf55e4b33c4fbacce6d8f75c4df837817`
> Orchestrator: `eaeb3a380035e8ddb13e42fb1877baabd9f57549`

This is a descriptive snapshot for teammates and their LLMs. The pinned Source files at the refs above
remain authoritative. Backend owns integrated Compose and the local-full scripts.

## 1. Toolchain and image versions

| Area | Current baseline | Source authority |
|---|---|---|
| Spring Backend build host/container | JDK 21 required by Maven Enforcer; Maven `3.9.9` wrapper; build image `maven:3.9.9-eclipse-temurin-21` | Backend `pom.xml`, `.mvn/wrapper/maven-wrapper.properties`, `Dockerfile` |
| Backend bytecode compatibility | Java release 17 (`java.version` and `maven.compiler.release`) while build/runtime JDK is 21 | Backend `pom.xml` |
| Backend framework parent | eGovFrame Boot starter parent `5.0.0`; Spring Boot version is inherited, not hand-pinned in Master | Backend `pom.xml` |
| Backend runtime | `eclipse-temurin:21.0.11_10-jre-jammy` | Backend `Dockerfile` |
| Spring AI | Product lane `1.1.8`; Control lane `1.0.1` | Backend `pom.xml` profiles |
| Frontend | Node `24.14.0`, pnpm `11.9.0`, React `19.2.x`, Vite `8.2.x`, TypeScript `7.0.x` | Frontend `package.json`, `Dockerfile` |
| Coding Orchestrator | Python `3.12.13`, uv `0.8.13`, LangGraph `>=1.1,<1.2` | Orchestrator `.python-version`, `pyproject.toml`, `Dockerfile` |
| Core/checkpoint database image | PostgreSQL 16 Bookworm with pgvector `0.8.5`, digest-pinned base | Backend Postgres `Dockerfile`, `compose.dev.yaml` |
| Redis-compatible queue/cache | Valkey `8.1.3-alpine`; Spring Data Redis and Python `redis>=6.4,<7` clients | Backend `compose.dev.yaml`, `pom.xml`; Orchestrator `pyproject.toml` |
| Ingress | Nginx `1.28.0-alpine` | Backend `compose.dev.yaml` |

`Redis` in planning language refers to the Redis protocol/client boundary. The actual local server is
Valkey; do not add a second Redis container.

## 2. Integrated service topology

| Service | Role | Profile | Exposure/persistence |
|---|---|---|---|
| `nginx` | single browser ingress and same-origin proxy | `spring-core`, `full` | host `127.0.0.1:18080` → container `80`; no persistent data |
| `frontend` | React/Vite administrator UI | `spring-core`, `full` | internal `5173`; only Nginx reaches it |
| `spring-app` | Spring API, Batch, Auth/RBAC, Product/Tool authority | `spring-core`, `coding-agent`, `full` | internal `8080`; only Compose networks/Nginx reach it |
| `database` | Core PostgreSQL/Flyway application state | always | internal `5432`; volume `axms-spring-dev-core-db` |
| `database_gateway` | loopback-only DBeaver/read-only relay | always | host `127.0.0.1:15432`; no public bind |
| `valkey` | Product/Coding queues and transient coordination | `spring-core`, `coding-agent`, `full` | internal `6379`; append-only volume `axms-spring-dev-valkey` |
| `coding-runtime` | Python LangGraph checkpoint/interrupt/resume consumer | `coding-agent`, `full` | internal health `8090`; not host-published |
| `checkpoint_database` | encrypted LangGraph checkpoint persistence | `coding-agent`, `full` | internal `5432`; separate volume `axms-spring-dev-checkpoint-db` |
| `flyway-migration` | forward-only Core DB migration/validation | `spring-core`, `coding-agent`, `full` | one-shot; must exit 0 before Spring starts |
| `coding_credential_registrar` | registers the internal Coding service credential | `ops` | explicit one-shot; never a long-running product service |

The `full` profile is the canonical team integration environment. `spring-core` omits the Coding
runtime/checkpoint pair. `coding-agent` omits browser ingress/Frontend. `ops` is only for the explicit
credential registrar operation.

## 3. Ingress and trust boundaries

```text
Browser
  → 127.0.0.1:18080 Nginx
      → /                       Frontend:5173
      → /api/**                 Spring:8080
      → /internal/dev/**        allowlisted Spring local-development adapters
      × /internal/**            404 by default
      × /actuator/**            404 by default

DBeaver read-only
  → 127.0.0.1:15432 database_gateway
      → Core PostgreSQL:5432
```

Core DB, checkpoint DB, Valkey, Spring, and Coding Runtime are not published on all host interfaces.
Nginx and the database gateway bind only to loopback. Schema changes remain Flyway-only; DBeaver DML
and DDL are forbidden.

## 4. Secrets and data

- Compose Secrets are sourced from ignored Backend `.local/secrets` files and are never recorded in
  Master documentation.
- Core DB, checkpoint DB, and Valkey use distinct named Volumes. No reset or deletion is implied by
  setup, update, test, or documentation work.
- The local demo login values in Compose are non-deployment demo fixtures. They must be replaced before
  any exposure beyond the internal local environment and must not be treated as production credentials.
- LLM/provider and public-data credentials are entered through their designated CMS/platform forms,
  not chat, command arguments, Git, or Master Markdown.

## 5. Local resource planning

The long-running `full` services declare approximately 5.7 GiB of combined memory limits and 7.25 CPU
shares. Builds and one-shot migration work add temporary demand. As an operational recommendation
derived from those limits, allocate at least 8 GiB to Docker and prefer a host with 16 GiB RAM. This is
a planning recommendation, not a substitute for the per-PC preflight and health checks.

## 6. Change control

- Version changes are made in their owning Source Repository first and reach `dev` through a Slice PR.
- The team lead then refreshes this Master snapshot from fetched `origin/dev` evidence.
- Teammates must not edit version numbers only in Master to make an unsupported local combination appear
  approved.
- A stale baseline is reported when a fetched Source `origin/dev` differs from the SHAs at the top.
