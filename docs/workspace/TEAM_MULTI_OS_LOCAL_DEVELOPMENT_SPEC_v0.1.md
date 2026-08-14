# AX Module Studio team multi-OS local development specification v0.1

> Updated: 2026-08-14 (Asia/Seoul)
> Applies to: Windows, macOS, and the implemented Linux/WSL path
> Runtime owner: Backend; workspace coordination owner: Master

## 1. Verified source evidence

| Evidence | Result |
|---|---|
| [Backend PR #4](https://github.com/urizo-final-org/urizo-final-backend/pull/4), merge `6fcc0c726e19126a392efddedba03b7a013ee1f0` | macOS/PowerShell Core Docker discovery, path handling, certificate trust, Unix secret permissions, and executable-bit compatibility merged to `dev` |
| Backend commit `289291385577064510b7f4b0684bd87fddd93778` in [PR #7](https://github.com/urizo-final-org/urizo-final-backend/pull/7) | Windows PowerShell 5.1 no longer fails under StrictMode when `$IsWindows` is undefined; migration verification passed |
| Team-lead report | the team members' individual PCs completed the applicable local flow without an outstanding OS-specific blocker |

Backend PR #4 changed Backend-owned runtime scripts. This Master revision additionally removes
Windows-only path separators from Master-owned bootstrap/health/validation paths and makes the parent
Claude routing block updateable on already-configured PCs.

## 2. Support matrix

| Host | Required shell for Repository scripts | Support state | Notes |
|---|---|---|---|
| Windows 10/11 | Windows PowerShell 5.1 or PowerShell 7 | verified | Docker CLI is resolved from `PATH` first, then approved Docker Desktop paths; PR #7 preserves 5.1 StrictMode compatibility |
| macOS | PowerShell 7 (`pwsh`) | verified by PR #4/team PC | Docker CLI must be on `PATH`; certificate trust may use System/login keychains; Unix permission modes apply |
| Linux/WSL2 | PowerShell 7 (`pwsh`) | implemented path | Docker CLI must be on `PATH`; CA bundles use standard Linux locations; report a fresh full acceptance result before calling a new host verified |

The LLM detects the host and current PowerShell runtime. It must not ask a macOS/Linux teammate to run
`powershell.exe`, and it must not assume Windows paths, `icacls`, or Windows certificate stores outside
the Windows branch.

## 3. Container-first and host-native boundaries

The canonical full environment is Docker Compose owned by Backend. A teammate needs Git, PowerShell,
Docker Engine with Compose v2, and enough local resources. JDK, Maven, Node/pnpm, Python/uv are built
inside pinned images for the full stack.

Host-native development or verification uses the exact versions in
[`CURRENT_LOCAL_INFRASTRUCTURE_BASELINE_v0.1.md`](../architecture/CURRENT_LOCAL_INFRASTRUCTURE_BASELINE_v0.1.md).
Do not silently use a different major version because a teammate's OS package manager selected it.

## 4. Portable script rules

- Construct Repository paths with `Join-Path` or forward-slash Repository-relative paths; do not embed
  Windows separators in cross-platform paths.
- Resolve `docker` from `PATH` first. Windows-only Docker Desktop fallbacks run only on Windows.
- Use `[System.IO.Path]::PathSeparator` for `PATH` changes.
- Use Windows ACLs only on Windows and `chmod 700/600` for local secret directories/files on Unix.
- Never print or commit Secret contents, generated trust bundles, or host-specific absolute paths.
- Preserve executable bits for mounted `.sh` and `.pl` helpers.
- Do not introduce symlink-dependent project instructions. `CLAUDE.md` imports are portable and avoid
  the Windows administrator/developer-mode requirement for symlink creation.

## 5. Per-PC acceptance

Existing team verification proves the current reviewed PCs, not every future machine. On a new or
reinstalled PC, the local LLM must:

1. report host OS, architecture, PowerShell version, Git, Docker CLI/Engine, and Compose availability;
2. preserve dirty branches, Secrets, databases, and Volumes;
3. obtain approval before installation, login, network download, administrator elevation, or reboot;
4. run the Master preflight and Backend-owned full bootstrap/health through the versioned wrappers;
5. report `SETUP PASS` only after the services, Flyway, and HTTP health gates pass.

The teammate should not manually translate commands between operating systems; the local LLM selects
the correct executable and reports any unavoidable human boundary.
