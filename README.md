# BlockSwarm (bksrm-chain)

**Sovereign Adaptive Guardian Framework** — A reversible, auditable, AI-native four-chain execution substrate.

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)
[![Solidity](https://img.shields.io/badge/Solidity-0.8.20-blue)](https://docs.soliditylang.org)
[![Foundry](https://img.shields.io/badge/Testing-Foundry-informational)](https://getfoundry.sh)
[![Governance](https://img.shields.io/badge/Governance-ADL--Governance-8b5cf6)](https://github.com/beyond-repair/ADL-Governance)

**Status:** ACTIVE · **Maturity:** 4 (production candidate) · **Tracks B1–B2b-3:** CLOSED

Governed by [ADL-Governance](https://github.com/beyond-repair/ADL-Governance).

---

### Blueprint v0.4.1+

#### Four-Chain Architecture

| Chain | Layer | Role | Key Contracts |
|-------|--------|------|---------------|
| 1 | Trust & Governance | Binding authority & reversibility | GovernanceNFT, DAOGovernor, RevertTokenLayer |
| 2 | Communication & Oracle | Semantic transport | OrchestrationEngine, KnowledgeLedger |
| 3 | AI Cognitive | **Advisory-only** | AIExecutor |
| 0 | Physical | Attested actuation | TEE / external |

**Invariant 4.2:** Chain-3 cannot execute. See [`docs/FORMAL_INVARIANTS.md`](docs/FORMAL_INVARIANTS.md).

#### Validation artifacts

| Track | Doc |
|-------|-----|
| B3b | [B3B_VALIDATION.md](docs/B3B_VALIDATION.md) |
| B2a | [B2_INVERSE_BINDING_VALIDATION.md](docs/B2_INVERSE_BINDING_VALIDATION.md) |
| B2b-1 | [B2B1_ONE_VOTE_VALIDATION.md](docs/B2B1_ONE_VOTE_VALIDATION.md) |
| B2b-2 | [B2B2_ROLE_VALIDATION.md](docs/B2B2_ROLE_VALIDATION.md) |
| B2b-3 | [B2B3_DEPLOY_VALIDATION.md](docs/B2B3_DEPLOY_VALIDATION.md) |

```bash
forge test -vv
```

#### Structure

```text
contracts/   Canonical UUPS implementations
test/        Foundry tests
script/      Foundry deploy
scripts/     Hardhat deploy helpers
docs/        Invariants & validation records
legacy/      Quarantined sketches — do not deploy
```

Offline control plane: [sovereign-clean-room](https://github.com/beyond-repair/sovereign-clean-room).
