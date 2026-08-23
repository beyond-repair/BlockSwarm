# One-Way Attestation Bridge Schema

**Status:** Documentation only — no on-chain deploy dependency.  
**Direction:** Clean-Room (offline trust root) → BlockSwarm KnowledgeLedger / Merkle root.  
**Never reverse:** BlockSwarm is not constitutional authority for Clean-Room.

---

## Trust model

```text
sovereign-clean-room
  ledger entry (hash-chained)
  PhysicsVerification / skill telemetry
       │
       │  export package (offline)
       ▼
  AttestationBundle (JSON)
       │
       │  optional: build Merkle leaves + root offline
       ▼
  knowledgeLeaf / Merkle root
       │
       ▼
BlockSwarm KnowledgeLedger.recordEntry  (ORACLE_ROLE)
  or external MerkleVerifier.verify(proof, root, leaf)
```

A valid on-chain record means: *this attestation was published*.  
It does **not** mean experimental validation of Ware/CFT/IQG or that Chain-3 AI may execute.

---

## AttestationBundle (v0.1)

```json
{
  "schema": "beyond-repair.attestation.v0.1",
  "source": {
    "system": "sovereign-clean-room",
    "workspace_id": "string",
    "network_access": false
  },
  "ledger": {
    "seq": 0,
    "entry_hash": "0x…",
    "prev_hash": "0x…",
    "event_type": "physics_ware_sparc"
  },
  "payload": {
    "input_hash": "hex",
    "result_hash": "hex",
    "status": "PASS|FAIL|INCONCLUSIVE",
    "claim_class": "phenomenological_hypothesis",
    "experimental_validation": false,
    "energy_extraction_validated": false,
    "thrust_validated": false,
    "metrics": {}
  },
  "merkle": {
    "leaf_encoding": "knowledgeLeaf",
    "content_cid": "bytes32 hex — keccak256 of canonical JSON payload",
    "proposal_id": 0,
    "causal_dag_hash": "bytes32 — optional batch root",
    "leaf": "bytes32 — keccak256(abi.encode(contentCID, proposalId, causalDAGHash))",
    "root": "bytes32 — optional batch Merkle root",
    "proof": []
  },
  "exported_at": "ISO-8601"
}
```

### Leaf encoding (must match `MerkleVerifier.knowledgeLeaf`)

```text
contentCID      = keccak256(utf8(canonical_json(payload)))
proposalId      = uint256 (0 if not tied to a DAO proposal)
causalDAGHash   = batch root or bytes32(0)
leaf            = keccak256(abi.encode(contentCID, proposalId, causalDAGHash))
```

### Immutable claim flags

Exports **must** carry:

- `claim_class = phenomenological_hypothesis`
- `experimental_validation = false`
- `energy_extraction_validated = false`
- `thrust_validated = false`

Stripping these while reusing `result_hash` is considered tampering at the schema layer.

---

## On-chain publication (optional)

1. Offline: build `AttestationBundle`, compute `leaf` / `root` / `proof`.
2. Holder of `ORACLE_ROLE` calls:

```solidity
knowledgeLedger.recordEntry(
    contentCID,      // from bundle.merkle.content_cid
    stateRoot,       // optional: Merkle root or Clean-Room tip hash
    proposalId,
    causalDAGHash
);
```

3. Third parties verify inclusion:

```solidity
MerkleVerifier.verify(proof, root, leaf)
```

---

## Out of scope (do not implement here)

- Chain-3 AI execution
- Automatic bridging from on-chain events into Clean-Room
- Treating ledger signatures as physics confirmation
- B2 rollback / inverse calldata (still gated on B3b)

---

## Related

- Clean-Room: `core/clean_room_ledger.py`, `core/clean_room_physics.py`
- BlockSwarm: `contracts/KnowledgeLedger.sol`, `contracts/MerkleVerifier.sol`, `docs/MERKLE.md`
- Invariants: `docs/FORMAL_INVARIANTS.md` (4.2 AI cannot execute)
