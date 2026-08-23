<div align="center">

# ⛓️ BlockSwarm

## On-chain power where **AI cannot seize the wheel**

### Sovereign Adaptive Guardian Framework (SAGF)

[![MIT](https://img.shields.io/badge/License-MIT-yellow?style=for-the-badge)](LICENSE)
[![Solidity](https://img.shields.io/badge/Solidity-0.8.20-363636?style=for-the-badge&logo=solidity)](https://docs.soliditylang.org)
[![Foundry](https://img.shields.io/badge/45+_tests-Foundry-0ea5e9?style=for-the-badge)](https://getfoundry.sh)
[![B2](https://img.shields.io/badge/B2-COMPLETE-22c55e?style=for-the-badge)](docs/CHANGELOG.md)

**AI proposes. Governance binds. Math polices the rollback.**

</div>

---

## Why builders care

Most “AI + DAO” demos let a model (or a compromised key behind a model) **do things**.

BlockSwarm's rule is brutal and simple:

> **Chain-3 is advisory-only. Execution authority lives elsewhere.**

That's not a blog post — it's **Invariant 4.2**, tested at the contract boundary.

---

## Four chains. One spine.

```text
 ① GOVERNANCE     vote · role · revert   ← only place binding power lives
 ② ORACLE         transport · knowledge
 ③ AI             advice only            ← no target.call, no seize
 ⓪ PHYSICAL       attested actuation
```

| You need | Contract surface |
|----------|------------------|
| Soulbound voting discipline | GovernanceNFT / DAOGovernor |
| Rollback that matches precommitted calldata | RevertTokenLayer |
| AI that can't go rogue on-chain | AIExecutor |
| Provenance leaves | KnowledgeLedger + Merkle |

---

## Prove it

```bash
forge test -vv
```

Validation write-ups live under `docs/` (B1 → B2b-3).  
Offline attestation plane: **[sovereign-clean-room](https://github.com/beyond-repair/sovereign-clean-room)**.

---

<div align="center">

### ⭐ If you've been burned by “AI agents with keys” — this repo is for you.

**v0.5.0-sagf** · [ADL-Governance](https://github.com/beyond-repair/ADL-Governance) · Atomic Dream Labs

</div>
