# AX Module Studio implementation/team handoff v0.8

> Date: 2026-08-12 (Asia/Seoul)
> Status: four canonical repositories published; teammate onboarding baseline ready
> Supersedes operational status in v0.7 without overwriting its historical record

## 1. Outcome

`urizo-final-master` is the workspace control/handoff repository for three independent Source repositories. The parent `AX-Module-Studio-Workspace` remains a non-Git directory.

The publication blocker recorded in v0.7 is resolved:

- Master governance and safe workspace wrappers are published.
- Frontend, Backend, and Orchestrator preserved implementations were reviewed through repository-specific PRs and published to `dev` and `main`.
- All four repositories expose protected `main` and `dev` branches.
- The Bootstrap manifest targets Source `dev` branches.
- No Source copy, Secret, database, Docker Volume, or runtime data is stored in Master.

The v0.7 AS-IS/TO-BE product analysis remains valid. Publication completion does not mean the full administrator CMS product is complete.

## 2. Published remote baseline

Observed 2026-08-12 after Backend `dev` recovery:

| Repository | `dev` | `main` | Protection | Open PR |
|---|---|---|---|---:|
| Master | `6189b715a58867c36ef57289db3303fc098d992a` before v0.8 publication | same before v0.8 publication | protected | 0 |
| Frontend | `4579800b0319180f4c1cbe77a7435f57d9a71d6a` | `b503f2e7a4808c5776c36091a3d540ded0eb5b61` | protected | 0 |
| Backend | `1687b3cce51532c2e54723383af2a50518a5fdd8` | `1687b3cce51532c2e54723383af2a50518a5fdd8` | protected | 0 |
| Orchestrator | `eaeb3a380035e8ddb13e42fb1877baabd9f57549` | `a55e62a0d5be972dbaf8f44dee17652487dc7470` | protected | 0 |

Frontend and Orchestrator `main` contain release merge commits while `dev` remains the integration branch. Backend `dev` was accidentally deleted after release and was safely restored from the identical final `main` SHA under the documented Repository Admin emergency-recovery exception.

The exact Source integration SHAs are also recorded in `repository-manifest.json`. Master publication SHAs are intentionally not self-recorded because publishing this document changes them.

## 3. Confirmed implementation AS-IS

- Local-full infrastructure: Nginx, Frontend, Spring App, Core PostgreSQL/pgvector, Valkey, Python Coding Runtime, checkpoint PostgreSQL, auxiliary database gateway, Flyway one-shot, and credential registrar one-shot.
- Technical product slice: Project → deterministic fixture Connector → Knowledge build/version/activate/rollback → RAG citation/refusal → Product Job.
- Coding foundation: Core DB outbox → Valkey, claim/lease/heartbeat/retry/outcome, Spring Model Turn, Spring Tool Gateway, encrypted checkpoint, interrupt/resume.
- Local Provider Credential CMS exists.
- Frontend remains an acceptance console, not the planned administrator CMS product.
- The only real Coding Tool remains fixture `README.md` `read_file`.
- Production authentication, user/role membership, and Project RBAC remain absent.

## 4. Product TO-BE remains unchanged

The following remain product work:

1. real public-data Connector and domain replacement;
2. production login, users, roles, and Project RBAC;
3. manual member, menu, content/page, board, and site design/template CMS;
4. typed specs, immutable versions, Preview, Approval, Site Release, Publish, Rollback;
5. end-user Renderer;
6. natural-language CMS on the manual CMS model;
7. RAG Dataset/Metric/Threshold/tuning;
8. task-level Provider/Model Mapping;
9. real repository Coding Tools;
10. versioned PathPolicy and fixed denylist;
11. approval-gated LLM DevOps;
12. unified Approval/Audit/Job history.

See the v0.1 traceability matrix for layer evidence. Its former remote-publication warning is superseded only by this v0.8 operational update; feature statuses are unchanged.

## 5. Teammate onboarding contract

Each teammate supplies only their name, confirmed GitHub ID, and preferred parent installation path to their LLM. The LLM then:

1. clones/opens Master;
2. reads Master `AGENTS.md` and required documents;
3. runs read-only Preflight;
4. explains network, authentication, Docker/WSL, administrator, reboot, local mutation, and Secret boundaries;
5. obtains the applicable approvals;
6. runs the Master bootstrap wrapper itself;
7. delegates local-full startup to Backend;
8. runs workspace health verification;
9. reports `SETUP PASS` only when the setup contract is satisfied.

Routine Git, PowerShell, Docker, Maven, Node, and Python commands should be executed by the LLM, not copied manually by the teammate. Human action remains required for login/MFA, administrator/reboot boundaries, and Secret entry.

The copy-ready setup prompt is `docs/onboarding/TEAMMATE_LLM_LOCAL_SETUP_PROMPT_v0.1.md`.

## 6. Work-start contract

Do not send a broad workstream request immediately after setup. The Integration/Contract owner assigns exactly one current Slice ID with its dependencies and PR order. The teammate then uses `docs/onboarding/TEAMMATE_LLM_WORK_START_PROMPT_v0.1.md`.

Initial execution window:

| Order | Lead | Slice | Rule |
|---:|---|---|---|
| 1-A | 민승준 | `AXMS-FND-01` | Backend behavior-preserving domain seam |
| 1-B | 이재욱 | `AXMS-FND-02` | Frontend route/client/style seam; parallel with FND-01 |
| 2 | 정차윤 | `AXMS-FND-03` | starts after FND-01 and FND-02 merge |
| 3 | 민승준 | `AXMS-FND-04` | starts after FND-03 |
| 4 | 정차윤·이재욱·민은지·윤서 | `AXMS-CMS-01` through `04` | parallel only after FND-04, in disjoint feature packages |

Shared OpenAPI/Schema, Flyway allocation, App shell, common Auth/Error/Approval/Audit, Compose/bootstrap, and Master manifest/handoff remain serialized through the Integration/Contract owner.

## 7. Setup acceptance

`SETUP PASS` requires:

- four exact canonical origins;
- Source repositories on clean `dev` worktrees;
- no parent `.git`;
- expected workspace file and routing rules;
- required local-full services healthy;
- Flyway successful with pending zero;
- service URL and warnings reported;
- no Secret value or full digest printed.

The scripts and remote branches are ready for this flow. The first actual teammate machine remains the clean-workstation acceptance run; any host-specific Docker/WSL/login boundary must be reported rather than bypassed.

## 8. Preservation and Git rules

- Team-member changes use latest `origin/dev` → one assigned feature branch → PR to `dev`, with the `tmdwns0531` Master/Admin integration account as the approval and merge gate.
- Repository changes remain separate and use the same Slice ID with cross-links.
- Team members cannot directly push `dev/main`. The `tmdwns0531` Master/Admin account is the intentional Ruleset bypass actor and may directly update `dev/main`, merge its own validated governance changes without a teammate approval, and approve team-member PRs. Each bypass operation retains validation evidence and the resulting SHA; force-push remains prohibited.
- Do not reset, clean, stash, overwrite existing non-empty folders, initialize databases, delete Volumes, reveal Secrets, or perform Prod/Cloud/SSH operations without matching authorization.
- Natural-language CMS follows manual CMS completion; LLM DevOps follows real Coding and PathPolicy completion.
