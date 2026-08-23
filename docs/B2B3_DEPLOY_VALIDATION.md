# B2b-3 — Deploy / Init Wiring Validation

**Scope only:** Proxy deployment, `initialize` args, and cross-contract role grants.

**Not modified:** SBT voting (B2b-1), role *semantics* (B2b-2), Chain-3 execution surface.

## Wiring matrix

| From | Role granted | To |
|------|--------------|-----|
| RevertTokenLayer | `ORCHESTRATOR_ROLE` | OrchestrationEngine |
| OrchestrationEngine | `ADVISOR_ROLE` | AIExecutor |
| OrchestrationEngine | `EXECUTOR_ROLE` | DAOGovernor |
| DAOGovernor (init) | `DEFAULT_ADMIN` / `PROPOSER` / `EXECUTOR` | admin |
| AIExecutor (init) | `DEFAULT_ADMIN` / `ADVISOR` | admin |

All upgradeable contracts deploy behind **ERC1967Proxy** with encoded `initialize` (implements `_disableInitializers` on implementations).

## Artifacts

| Path | Purpose |
|------|---------|
| `scripts/deployment/deploy_sagf.js` | Hardhat/ethers deploy + wiring + `deployments/sagf-<network>.json` |
| `script/DeploySAGF.s.sol` | Foundry `forge script` equivalent |
| `test/SAGFDeployWiring.t.sol` | Post-deploy assertions |

## Tests

```bash
forge test --match-contract SAGFDeployWiringTest -vv
```

```
[PASS] test_dao_admin_bootstrap_roles()
[PASS] test_dao_wired_to_dependencies()
[PASS] test_revertLayer_orchestrator_role()
[PASS] test_orch_advisor_is_aiExecutor()
[PASS] test_orch_executor_includes_dao()
[PASS] test_ai_points_at_orchestrator()
[PASS] test_ai_has_no_executor_role_constant()
[PASS] test_stranger_cannot_grant_dao_roles()
[PASS] test_merkle_deployed()
Suite: 9 passed
```

## Regressions (same run)

```
DAOGovernorRolesTest         9
OneVotePerSBTTest            4
AIExecutorAdvisoryOnlyTest   8
SAGFDeployWiringTest         9
Total                       30 passed
```

## Track status — B2 complete

```
B1     CLOSED
B3a/b  CLOSED
B2a    CLOSED  inverse calldata binding
B2b-1  CLOSED  one-vote-per-SBT
B2b-2  CLOSED  role wiring
B2b-3  CLOSED  deploy/init wiring  ← this artifact
```

Next non-B2 work is optional: hygiene (`legacy/` root), SEEM banners, or Clean-Room CLI attestation.
