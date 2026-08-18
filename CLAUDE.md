# AX Module Studio Master — Claude Code entry point

@AGENTS.md

## Claude-specific routing

- The imported `AGENTS.md` is the common normative instruction source. Do not duplicate or reinterpret
  product, Git, WBS, approval, or safety rules in this file.
- Read `docs/workspace/LLM_MODEL_INSTRUCTION_ROUTING_v0.1.md` to understand how Codex-compatible agents
  and Claude Code share the same Master context.
- When Source repositories are assembled, work from the non-Git parent workspace so the parent
  `CLAUDE.md`, Master instructions, and applicable sibling `AGENTS.md` are all reachable.
