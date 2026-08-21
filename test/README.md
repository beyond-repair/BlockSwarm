# BlockSwarm tests (Foundry)

## Prerequisites

```bash
forge install OpenZeppelin/openzeppelin-contracts-upgradeable --no-commit
forge install OpenZeppelin/openzeppelin-contracts --no-commit
forge install foundry-rs/forge-std --no-commit
```

`foundry.toml` already remaps:

- `@openzeppelin/contracts-upgradeable/`
- `@openzeppelin/contracts/`

## B3 — Invariant 4.2 execution boundary

```bash
forge test --match-contract AIExecutorAdvisoryOnlyTest -vv
```

These tests assert that a deployed `AIExecutor`:

| Capability | Expected |
|------------|----------|
| `processAdvisory` | allowed (Chain-3) |
| `registerAgent` / `revokeAgent` | allowed |
| `executeAuthorized` / `target.call` | **impossible** |
| `triggerRevert` / rollback | **impossible** |
| legacy `executeProposal` | **impossible** |
| `EXECUTOR_ROLE` on AIExecutor | **absent** |

They probe **runtime selectors** on the deployed contract, not only source text.

## Deferred

- B2: rollback calldata binding, voting, deploy role wiring
- Broader governance / OrchestrationEngine integration suites
