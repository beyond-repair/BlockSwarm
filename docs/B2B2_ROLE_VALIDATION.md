# B2b-2 — DAOGovernor Role Wiring Validation

**Scope only:** PROPOSER / EXECUTOR / DEFAULT_ADMIN role boundaries on `DAOGovernor`.

**Not in this commit:** deploy wiring (B2b-3), SBT vote changes (B2b-1 locked), Chain-3.

## Role model

| Role | Capability |
|------|------------|
| `DEFAULT_ADMIN_ROLE` | `grantProposer` / `revokeProposer` / `grantExecutor` / `revokeExecutor`; upgrades |
| `PROPOSER_ROLE` | `propose` only |
| `EXECUTOR_ROLE` | `executeProposal` only |

Bootstrap on `initialize(governance)`: admin receives all three.

`castVote` remains **role-free** (SBT + NFC identity only).

## Helpers

```solidity
grantProposer / revokeProposer   // onlyRole(DEFAULT_ADMIN_ROLE)
grantExecutor / revokeExecutor   // onlyRole(DEFAULT_ADMIN_ROLE)
propose                          // onlyRole(PROPOSER_ROLE)
executeProposal                  // onlyRole(EXECUTOR_ROLE)
```

## Tests

```bash
forge test --match-contract DAOGovernorRolesTest -vv
```

```
[PASS] test_admin_hasBootstrapRoles()
[PASS] test_nonProposer_cannotPropose()
[PASS] test_proposer_canPropose()
[PASS] test_admin_canGrantAndRevokeProposer()
[PASS] test_nonAdmin_cannotGrantProposer()
[PASS] test_nonExecutor_cannotExecute()
[PASS] test_admin_canGrantExecutor()
[PASS] test_proposer_withoutExecutor_cannotExecute()
[PASS] test_executor_canExecuteAfterYesVotes()  // role ok; tally gate still applies
Suite: 9 passed
```

## Regressions

```
OneVotePerSBTTest            4 passed
AIExecutorAdvisoryOnlyTest   8 passed
```

## Track

```
B1     CLOSED
B3a/b  CLOSED
B2a    CLOSED
B2b-1  CLOSED
B2b-2  CLOSED  ← this artifact
B2b-3  PENDING deploy / init wiring only
```
