<div align="center">

```
╔══════════════════════════════════════════════════════════════╗
║                                                              ║
║   ██████╗ ██╗      ██████╗  ██████╗██╗  ██╗                  ║
║   ██╔══██╗██║     ██╔═══██╗██╔════╝██║ ██╔╝                  ║
║   ██████╔╝██║     ██║   ██║██║     █████╔╝                   ║
║   ██╔══██╗██║     ██║   ██║██║     ██╔═██╗                   ║
║   ██████╔╝███████╗╚██████╔╝╚██████╗██║  ██╗                  ║
║   ╚═════╝ ╚══════╝ ╚═════╝  ╚═════╝╚═╝  ╚═╝                  ║
║                                                              ║
║              ＳＷＡＲＭ  ·  ＳＡＧＦ  ｖ０．５                 ║
╚══════════════════════════════════════════════════════════════╝
```

# BLOCKSWARM · SAGF

### Four-chain substrate where **AI advises and cannot execute**

**THE CITY WRITES ITS OWN REALITY.**  
**YOU JUST GOVERN IT.**

[![MIT](https://img.shields.io/badge/License-MIT-a855f7?style=for-the-badge&labelColor=0f0f23)](LICENSE)
[![Foundry](https://img.shields.io/badge/Foundry-tests-22d3ee?style=for-the-badge&labelColor=0f0f23)](https://getfoundry.sh)
[![B2 COMPLETE](https://img.shields.io/badge/B2-COMPLETE-22c55e?style=for-the-badge&labelColor=0f0f23)](docs/CHANGELOG.md)
[![Invariant](https://img.shields.io/badge/AI_cannot_execute-ef4444?style=for-the-badge&labelColor=0f0f23)](#)

```
STABILITY  ████████████████████░░░░  82%
ALERT      ░░░░░░░░░░░░░░░░░░░░░░░░  18%
```

</div>

---

## ▌ MAIN OBJECTIVE

**REACH THE CORE TOWER** — Separate authority by construction.  
Chain-3 has **no** `target.call`. Governance alone binds. Rollback must match a precommitted inverse hash.

| Status | Item |
|:------:|------|
| ☑ | Four-chain SAGF architecture |
| ☑ | AIExecutor advice-only path |
| ☑ | RevertTokenLayer hash-bound undo |
| ☑ | Formal invariants documented |
| ☐ | Tag + Release v0.5.0-sagf |

---

## ▌ WHY THIS SURFACE EXISTS

Most “AI + chain” demos hand an agent a key.  
**SAGF separates authority by construction.**

---

## ▌ VISUAL WORKFLOW — VERSION FORK

```text
                 ┌─────────────────────────────────────┐
                 │         CHAIN 1 — GOVERNANCE          │
                 │  SBT vote · roles · propose · execute │
                 │  RevertTokenLayer (hash-bound undo)   │
                 └──────────────▲────────────────────────┘
                                │ binding only
┌──────────────┐    ┌───────────┴───────────┐    ┌──────────────┐
│ CHAIN 3 · AI │───►│ CHAIN 2 · ORACLE      │───►│ CHAIN 0      │
│ AIExecutor   │    │ OrchestrationEngine   │    │ Physical /   │
│ processAdv.  │    │ KnowledgeLedger       │    │ TEE agents   │
│ advice ONLY  │    │ Merkle leaves         │    │ attested act │
└──────────────┘    └───────────────────────┘    └──────────────┘
        │
        X  no arbitrary external calls
```

### Step-by-step

| Step | Component | How | Why |
|-----:|-----------|-----|-----|
| **1** | Register AI agent | `registerAgent` on AIExecutor | Identity without power |
| **2** | Emit advice | `processAdvisory` | Structured recommendation only |
| **3** | Transport | OrchestrationEngine / ledger | Advice becomes data, not a call |
| **4** | Human/gov path | DAOGovernor + roles + SBT one-vote | Binding requires Chain-1 authority |
| **5** | Execute | Executor role only | AI path cannot reach this |
| **6** | Undo | `inverseCalldata` must hash-match | Rollback is cryptographic, not vibes |
| **7** | Provenance | Merkle / KnowledgeLedger | Optional offline attest from Clean-Room |

**Invariant 4.2:** Chain-3 **cannot** execute. See `docs/FORMAL_INVARIANTS.md`.

---

## ▌ TOOLS

| # | Tool | Function |
|:-:|------|----------|
| 1 | **SCAN** | Inspect ledger + Merkle roots |
| 2 | **FORK** | Parallel governance proposals |
| 3 | **SPIKE** | Inject advisory (advice only) |
| 4 | **ANCHOR** | Bind inverse hash for rollback |
| 5 | **ESCAPE** | RevertTokenLayer emergency path |

---

## ▌ HOW IT FITS THE LAB

```text
sovereign-clean-room ──optional one-way──► KnowledgeLedger leaf
        (offline attest)                      (on-chain receipt)

ADL-Governance ── rules for all ACTIVE repos including this one
```

---

## ▌ PROVE IT

```bash
forge test -vv
```

Docs: B1–B2b-3 under `docs/` · Release target **v0.5.0-sagf**

---

<div align="center">

```
YOU WERE HERE BEFORE.
VERSION 17 FAILED.
DO NOT TRUST SABLE.
THE CITY REMEMBERS.
```

**REWRITE · BUILD · TRANSCEND**

[Atomic Dream Labs](https://github.com/beyond-repair) · [sovereign-clean-room](https://github.com/beyond-repair/sovereign-clean-room)

</div>
