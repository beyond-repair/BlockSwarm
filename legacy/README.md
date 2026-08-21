# Legacy sketches (quarantined)

These files are **historical / non-canonical**. They predate the UUPS `contracts/` package and must not be used as deploy targets.

Canonical Chain-3 surface: [`contracts/AIExecutor.sol`](../contracts/AIExecutor.sol) (advisory-only per Invariant 4.2).

| Legacy path | Notes |
|-------------|--------|
| `AIExecutor.sol` (root) | Unrestricted `target.call` — **unsafe**; superseded |
| `DAOGovernor.sol` (root) | Early non-upgradeable sketch |
| `GovernanceNFT.sol` (root) | Early sketch |
| `BlockSwarmDAO` | Extensionless draft |
| `Deployment Script`, `Gnosis Safe`, `Tests` | Informal notes / fragments |

See [`docs/FORMAL_INVARIANTS.md`](../docs/FORMAL_INVARIANTS.md).
