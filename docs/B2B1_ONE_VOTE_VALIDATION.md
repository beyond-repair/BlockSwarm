# B2b-1 — One Vote Per SBT Validation

**Scope only:** At most one vote per address per proposal for soulbound holders.

**Not in this commit:** role redesign, deploy wiring, quorum thresholds, inverse calldata (already B2a).

## Implementation

`contracts/DAOGovernor.sol`:

```solidity
mapping(uint256 => mapping(address => bool)) public hasVoted;

require(!hasVoted[proposalId][msg.sender], "Already voted");
// … SBT + NFC checks …
hasVoted[proposalId][msg.sender] = true;
proposal.forVotes += 1; // or againstVotes
```

## Tests

```bash
forge test --match-contract OneVotePerSBTTest -vv
```

```
[PASS] test_firstVote_countsOnce()
[PASS] test_secondVote_revertsAlreadyVoted()
[PASS] test_twoHolders_eachOneVote()
[PASS] test_withoutSbt_cannotVote()
Suite result: ok. 4 passed
```

## Track

```
B1    CLOSED
B3a/b CLOSED
B2a   CLOSED  inverse calldata binding
B2b-1 CLOSED  one-vote-per-SBT
B2b-2 PENDING role wiring (sole surface)
B2b-3 PENDING deploy init wiring (sole surface)
```
