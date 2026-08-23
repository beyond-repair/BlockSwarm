# B3b Validation Record

**Date:** 2026-08-23  
**Environment:** Foundry forge 1.7.1 · solc 0.8.20 · OZ contracts v4.9.6

## Command

```bash
forge test --match-contract AIExecutorAdvisoryOnlyTest -vv
forge test --match-contract MerkleProofTest -vv
```

## Result — AIExecutorAdvisoryOnlyTest

```
Ran 8 tests for test/AIExecutorAdvisoryOnly.t.sol:AIExecutorAdvisoryOnlyTest
[PASS] test_aiAgent_cannotArbitraryCallViaAIExecutor()
[PASS] test_attacker_withoutRole_cannotProcessAdvisory()
[PASS] test_executeAuthorized_selectorReverts()
[PASS] test_legacyExecuteProposal_selectorReverts()
[PASS] test_noExecutorRoleConstant()
[PASS] test_processAdvisory_emitsAndForwards()
[PASS] test_registerAndRevokeAgent()
[PASS] test_triggerRevert_selectorReverts()
Suite result: ok. 8 passed; 0 failed; 0 skipped
```

## Result — MerkleProofTest

```
Ran 10 tests for test/MerkleProof.t.sol:MerkleProofTest
[PASS] (all unit + fuzz)
Suite result: ok. 10 passed; 0 failed; 0 skipped
```

## Notes

- Upgradeable contracts exercised via **ERC1967Proxy** (matches production `_disableInitializers` path).
- Victim.hits unchanged under AI agent `executeAuthorized` probe.
- Python attestation tests remain a separate offline layer; they do not substitute for this record.

## Track status after this record

```
B1  CLOSED
B3a CLOSED
B3b CLOSED  ← this artifact
B2  UNBLOCKED for inverse calldata binding only
```
