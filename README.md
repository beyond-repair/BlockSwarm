<div align="center">

```
╔══════════════════════════════════════════════════════════════╗
║   ATOMIC DREAM LABS  ·  BEYOND-REPAIR                        ║
╚══════════════════════════════════════════════════════════════╝
```

# BlockSwarm

### AI advises. It cannot execute.

[![Lifecycle](https://img.shields.io/badge/●_ACTIVE-22c55e?style=for-the-badge&labelColor=0f0f23)](https://github.com/beyond-repair/ADL-Governance)
[![Claim](https://img.shields.io/badge/Claim_software-22c55e?style=for-the-badge&labelColor=0f0f23)](https://github.com/beyond-repair/ADL-Governance/blob/main/docs/CLAIM_VALIDATION.md)
[![Governance](https://img.shields.io/badge/ADL--Governance-7c3aed?style=for-the-badge&labelColor=0f0f23)](https://github.com/beyond-repair/ADL-Governance)

```
LIFECYCLE   ACTIVE
INVARIANT   AI advises · cannot execute
NOT CLAIMED autonomous value movement
```

</div>

---
## ▌ STATUS

Active execution substrate. Tag lineage includes `v0.5.0-sagf`. Solidity · Foundry.  
Invariant: **AI advises. It cannot execute.**

---

## ▌ PRESERVED BODY

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

## Development / runbook

Stranger clone path (Foundry evidence boundary). OpenZeppelin **v4.9.6** and forge-std **v1.9.4** are pinned as git submodules.

```bash
# 1) Install Foundry (once per machine)
curl -L https://foundry.paradigm.xyz | bash
# restart shell or: export PATH="$HOME/.foundry/bin:$PATH"
foundryup

# 2) Clone with submodules (or init after clone)
git clone --recurse-submodules https://github.com/beyond-repair/BlockSwarm.git
cd BlockSwarm
# If you cloned without --recurse-submodules:
#   git submodule update --init --recursive

# Fallback if submodules are empty (matches CI):
#   mkdir -p lib
#   git clone --depth 1 --branch v4.9.6 https://github.com/OpenZeppelin/openzeppelin-contracts-upgradeable.git lib/openzeppelin-contracts-upgradeable
#   git clone --depth 1 --branch v4.9.6 https://github.com/OpenZeppelin/openzeppelin-contracts.git lib/openzeppelin-contracts
#   git clone --depth 1 --branch v1.9.4 https://github.com/foundry-rs/forge-std.git lib/forge-std

# 3) Build and test
forge build
forge test -vv

# 4) Optional: local deploy script dry-run (no broadcast)
forge script script/DeploySAGF.s.sol:DeploySAGF -vv
```

- Tests under `test/` define what is actually claimed (advisory-only AIExecutor, one-vote SBT, role separation, inverse binding, deploy wiring, Merkle).
- No mainnet deployment claim and no formal audit claim from this README.
- `hardhat.config.js` remains for the legacy Hardhat deploy helper under `scripts/deployment/`; Foundry is the supported build/test path.
- Copy `env.example` to `.env` only if you intend a live RPC deploy; never commit secrets.

See `GOVERNANCE.md`, `SECURITY.md`, and `docs/` when present.

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

---

<div align="center">

**REWRITE · BUILD · TRANSCEND**

**William (Brian) Ware** · [Atomic Dream Labs](https://github.com/beyond-repair)  
Governing source: [ADL-Governance](https://github.com/beyond-repair/ADL-Governance) · [Claim levels 0–5](https://github.com/beyond-repair/ADL-Governance/blob/main/docs/CLAIM_VALIDATION.md)

</div>
