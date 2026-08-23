<div align="center">

# BlockSwarm

### Sovereign Adaptive Guardian Framework (SAGF)

**Reversible · Auditable · AI-native · Four-chain execution substrate**

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg?style=for-the-badge)](LICENSE)
[![Solidity](https://img.shields.io/badge/Solidity-0.8.20-363636?style=for-the-badge&logo=solidity)](https://docs.soliditylang.org)
[![Foundry](https://img.shields.io/badge/Foundry-tests-0ea5e9?style=for-the-badge)](https://getfoundry.sh)
[![Milestone](https://img.shields.io/badge/B2-Complete-22c55e?style=for-the-badge)](docs/CHANGELOG.md)
[![Governance](https://img.shields.io/badge/ADL--Governance-7c3aed?style=for-the-badge)](https://github.com/beyond-repair/ADL-Governance)

**STATUS** `ACTIVE` · **Release** `v0.5.0-sagf` · **Maturity** production candidate

</div>

---

## The idea

BlockSwarm separates **advice** from **authority**. AI can propose; only governance can bind. Rollback is cryptographically constrained. Offline attestation can feed the ledger — it cannot seize the chain.

### Four-chain architecture

```text
 Chain 1  Trust & Governance     GovernanceNFT · DAOGovernor · RevertTokenLayer
 Chain 2  Communication          OrchestrationEngine · KnowledgeLedger
 Chain 3  AI Cognitive           AIExecutor  ← advisory only
 Chain 0  Physical               TEE / external actuation
```

| Chain | Role | Key contracts |
|------:|------|---------------|
| **1** | Binding authority & reversibility | GovernanceNFT, DAOGovernor, RevertTokenLayer |
| **2** | Semantic transport | OrchestrationEngine, KnowledgeLedger |
| **3** | **Advisory-only** AI | AIExecutor |
| **0** | Attested actuation | TEE / external |

> **Invariant 4.2** — Chain-3 **cannot** execute.  
> Details: [`docs/FORMAL_INVARIANTS.md`](docs/FORMAL_INVARIANTS.md)

---

## Validate

```bash
forge test -vv
# Target: 45 tests green
```

| Track | Documentation |
|-------|----------------|
| B3b advisory boundary | [B3B_VALIDATION.md](docs/B3B_VALIDATION.md) |
| B2a inverse binding | [B2_INVERSE_BINDING_VALIDATION.md](docs/B2_INVERSE_BINDING_VALIDATION.md) |
| B2b-1 one-vote / SBT | [B2B1_ONE_VOTE_VALIDATION.md](docs/B2B1_ONE_VOTE_VALIDATION.md) |
| B2b-2 roles | [B2B2_ROLE_VALIDATION.md](docs/B2B2_ROLE_VALIDATION.md) |
| B2b-3 deploy | [B2B3_DEPLOY_VALIDATION.md](docs/B2B3_DEPLOY_VALIDATION.md) |
| Changelog | [CHANGELOG.md](docs/CHANGELOG.md) |

---

## Repository layout

```text
contracts/   Canonical UUPS implementations
test/        Foundry suites
script/      Foundry deploy (DeploySAGF.s.sol)
scripts/     Hardhat helpers
docs/        Invariants · validation · changelog
legacy/      Quarantined sketches — do not deploy
.github/     CI
```

Offline control plane: **[sovereign-clean-room](https://github.com/beyond-repair/sovereign-clean-room)**

---

<div align="center">

**Atomic Dream Labs** · [ADL-Governance](https://github.com/beyond-repair/ADL-Governance)

<sub>AI advises. Governance decides. Code proves the boundary.</sub>

</div>
