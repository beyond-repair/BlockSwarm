# Merkle Proof Verification (BlockSwarm)

## Purpose

Pure inclusion proofs for:

- KnowledgeLedger-oriented leaves under a published root
- Advisory DAG leaves under an advisory root
- Future one-way Clean-Room → BlockSwarm attestation roots

**Does not** implement or unlock B2 rollback (`inverseCalldata` binding). Track B gates unchanged:

```text
B1 CLOSED → B3a CLOSED → B3b PENDING (forge green) → B2 BLOCKED
```

## Components

| Path | Role |
|------|------|
| `contracts/libraries/MerkleProof.sol` | Sorted-pair verify / multiproof |
| `contracts/MerkleVerifier.sol` | Stateless view facade + leaf helpers |
| `test/MerkleProof.t.sol` | Unit + fuzz tests |

## Hash scheme

```text
leaf   = application-defined (see helpers)
parent = keccak256(abi.encodePacked(min(a,b), max(a,b)))   // order-independent
```

Callers must generate proofs with the **same** sorted-pair rule offline.

### Leaf helpers (facade)

```solidity
knowledgeLeaf(contentCID, proposalId, causalDAGHash)
  = keccak256(abi.encode(contentCID, proposalId, causalDAGHash))

advisoryLeaf(proposalId, advisoryHash)
  = keccak256(abi.encode(proposalId, advisoryHash))
```

## Usage

```solidity
import {MerkleProof} from "./libraries/MerkleProof.sol";

bool ok = MerkleProof.verify(proof, publishedRoot, leaf);
```

Or via facade:

```solidity
MerkleVerifier v = MerkleVerifier(addr);
bool ok = v.verify(proof, root, v.knowledgeLeaf(cid, id, dag));
```

## Tests

```bash
forge test --match-contract MerkleProofTest -vv
```

Independent of `AIExecutorAdvisoryOnlyTest` (B3b).
