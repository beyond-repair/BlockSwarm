# BlockSwarm DAO Architecture

**Blueprint:** v0.4.1 · **B1:** Chain-3 advisory isolation locked

## Canonical components (`contracts/`)

| Contract | Chain | Role |
|----------|-------|------|
| `GovernanceNFT` | 1 | Soulbound NFC governance identity |
| `DAOGovernor` | 1 | Propose / vote / execute under governance |
| `RevertTokenLayer` | 1 | Reversibility tokens |
| `OrchestrationEngine` | 2 | Advisory intake + proposal authorization |
| `KnowledgeLedger` | 2 | On-chain provenance entries |
| `AIExecutor` | 3 | **Advisory only** — no `target.call`, no revert, no binding actuation |

## Authority rule (Invariant 4.2)

AI / Digital Double output is advisory data. Binding state transitions require Chain-1 governance (or an explicitly non-AI execution boundary). Do not place execution primitives on `AIExecutor`.

Full text: [`docs/FORMAL_INVARIANTS.md`](docs/FORMAL_INVARIANTS.md)

## Legacy

Root-level Solidity sketches and informal notes live under [`legacy/`](legacy/) and are not deploy targets.
