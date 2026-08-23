# B2 Inverse Calldata Binding — Validation Record

**Scope:** Sole change — `keccak256(inverseCalldata) == inverseActionHash` before `address(this).call`.

**Not included:** voting, roles, Chain-3, attestation, Hardhat, legacy cleanup.

## Implementation

`contracts/RevertTokenLayer.sol` → `requestRollback`:

```solidity
require(
    keccak256(inverseCalldata) == rt.inverseActionHash,
    "Inverse calldata hash mismatch"
);
(bool success, ) = address(this).call(inverseCalldata);
```

## Tests

```bash
forge test --match-contract RevertTokenInverseBindingTest -vv
forge test --match-contract AIExecutorAdvisoryOnlyTest -vv
```

### RevertTokenInverseBindingTest — 5/5 PASS

```
[PASS] test_matchingCalldata_allowsRollback()
[PASS] test_mismatchedCalldata_reverts()
[PASS] test_hashIsOverExactSuppliedBytes()
[PASS] test_checkOccursBeforeCall_mismatchLeavesNoSideEffect()
[PASS] test_emptyCalldata_onlyIfPrecommitted()
```

### AIExecutorAdvisoryOnlyTest (B3 regression) — 8/8 PASS

Chain-3 advisory boundary unchanged.

## Track status

```
B1   CLOSED
B3a  CLOSED
B3b  CLOSED
B2a  CLOSED  ← inverse calldata binding
B2b  PENDING — voting / roles / deploy wiring (separate commits)
```
