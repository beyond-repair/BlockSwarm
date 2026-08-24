<div align="center">

# ⛓️ BlockSwarm · SAGF

### Four-chain substrate where **AI advises and cannot execute**

[![MIT](https://img.shields.io/badge/License-MIT-yellow?style=for-the-badge)](LICENSE)
[![Foundry](https://img.shields.io/badge/Foundry-tests-0ea5e9?style=for-the-badge)](https://getfoundry.sh)
[![B2](https://img.shields.io/badge/B2-COMPLETE-22c55e?style=for-the-badge)](docs/CHANGELOG.md)

</div>

---

## Why it is unique

Most “AI + chain” demos hand an agent a key.  
**SAGF separates authority by construction:** Chain-3 has **no** `target.call`. Governance alone binds. Rollback must match a precommitted inverse hash.

---

## Visual workflow

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

### Step-by-step — how & why

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

## How it works with the lab

```text
sovereign-clean-room ──optional one-way──► KnowledgeLedger leaf
        (offline attest)                      (on-chain receipt)

ADL-Governance ── rules for all ACTIVE repos including this one
```

---

## Prove it

```bash
forge test -vv
```

Docs: B1–B2b-3 under `docs/` · Release **v0.5.0-sagf**

---

<div align="center">

[Atomic Dream Labs](https://github.com/beyond-repair) · [sovereign-clean-room](https://github.com/beyond-repair/sovereign-clean-room)

</div>
