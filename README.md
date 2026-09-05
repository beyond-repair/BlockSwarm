# BlockSwarm — SAGF Execution Substrate

**Status:** Active (P2) · tag lineage includes `v0.5.0-sagf`  
**Lab:** [Atomic Dream Labs / beyond-repair](https://github.com/beyond-repair)  
**Stack:** Solidity · Foundry  
**License:** MIT

---

## One-line purpose

BlockSwarm is a **governed multi-agent coordination substrate**: AI may advise; it must not unilaterally execute value-moving actions.

Invariant:

> **AI advises. It cannot execute.**

---

## Why it exists

Decentralized coordination and multi-agent systems are converging. Most “agent + chain” demos let models trigger irreversible actions too early. BlockSwarm separates:

| Layer | Responsibility |
|-------|----------------|
| Advice | Models, planners, Digital Double workers |
| Authority | Explicit human / constitutional gates |
| Settlement | Chain-backed records, cryptographic rollback paths |

Strategic fit inside the lab:

```
Digital Double (workforce agents)
        ↓
Agent marketplace / task graph
        ↓
BlockSwarm (proof of work performed + authority)
        ↓
Sovereign-OS style governance semantics
```

---

## Operator tools (conceptual surface)

| Tool | Role |
|------|------|
| **SCAN** | Ledger / state inspection |
| **FORK** | Proposals |
| **SPIKE** | Advice only (non-executing) |
| **ANCHOR** | Integrity / inverse-hash style commitments |
| **ESCAPE** | Revert path |

These names align with lab-wide SCAN / FORK / ANCHOR vocabulary used in portfolio census work.

---

## Development

```bash
# Foundry tests are the evidence boundary
forge test -vv
```

- Tests under `test/` define what is actually claimed.  
- No mainnet deployment claim and no formal audit claim from this README.  

See `GOVERNANCE.md` and `SECURITY.md` when present.

---

## Scope (claim-capped)

**In scope**

- Protocol experiments for advice vs execution separation  
- Foundry-tested invariants  
- Integration narrative with Digital Double and lab governance  

**Out of scope**

- Guaranteed mainnet security  
- Token price or fundraising claims  
- Unbounded autonomous treasuries  

---

## Related repositories

| Repo | Relationship |
|------|----------------|
| [Digital_Double_virtual_workforce](https://github.com/beyond-repair/Digital_Double_virtual_workforce) | Agent workforce |
| [Sovereign-OS](https://github.com/beyond-repair/Sovereign-OS) | Constitutional governance concepts |
| [ADL-Governance](https://github.com/beyond-repair/ADL-Governance) | Lab-level claim and lifecycle rules |

---

## Contributing

PRs must preserve the **non-execution of AI advice** invariant or explicitly document a gated exception with tests.

---

*Atomic Dream Labs — authority by construction*
