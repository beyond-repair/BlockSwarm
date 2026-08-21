# BlockSwarm (bksrm-chain)

**Sovereign Adaptive Guardian Framework** — A reversible, auditable, AI-native four-chain execution substrate.

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)
[![Solidity](https://img.shields.io/badge/Solidity-0.8.20-blue)](https://docs.soliditylang.org)
[![Foundry](https://img.shields.io/badge/Testing-Foundry-informational)](https://getfoundry.sh)
[![SAGF](https://img.shields.io/badge/Core-Sovereign%20Adaptive%20Guardian-8b5cf6)](docs/FORMAL_INVARIANTS.md)

---

### Blueprint of Source Truth • v0.4.1 (B1)

This repository is the **canonical technical specification** and implementation of BlockSwarm.

#### Four-Chain Architecture

| Chain | Layer | Role | Key Contracts |
|-------|--------|------|---------------|
| 1 | SAGF Trust & Governance | Binding authority & reversibility | GovernanceNFT, DAOGovernor, RevertTokenLayer |
| 2 | Communication & Oracle | Semantic transport & reality binding | OrchestrationEngine, KnowledgeLedger |
| 3 | AI Cognitive Layer | **Advisory-only** Digital Double | AIExecutor |
| 0 | Physical Execution Substrate | Attested actuation | (TEE + external agents) |

**Core Invariants** — See [`docs/FORMAL_INVARIANTS.md`](docs/FORMAL_INVARIANTS.md)

**Invariant 4.2 (locked in B1):** Chain-3 AI authority cannot execute arbitrary calls, governance actions, or rollbacks. Binding actuation stays on Chain-1 / governance-controlled paths.

#### Repository Structure

```text
contracts/     Canonical UUPS implementation (deploy targets)
docs/          Formal invariants & architecture notes
legacy/        Quarantined root sketches — do not deploy
scripts/       Deployment helpers
```

Canonical Chain-3 surface: [`contracts/AIExecutor.sol`](contracts/AIExecutor.sol)

#### Group boundary

BlockSwarm is a **satellite** on-chain experiment (Group E relative to the `beyond-repair` map). Offline sovereign control plane: [`sovereign-clean-room`](https://github.com/beyond-repair/sovereign-clean-room).
