# BlockSwarm / SAGF — Formal Invariants

**Blueprint:** v0.4.1  
**Scope:** Boundary rules for the four-chain substrate.  
**Status:** B1 documents Chain-3 advisory isolation. B2/B3 refine voting, rollback integrity, and role wiring.

---

## Four-Chain Authority Model

| Chain | Layer | May bind state? | Primary contracts |
|-------|--------|-----------------|-------------------|
| 1 | Trust & Governance | **Yes** | GovernanceNFT, DAOGovernor, RevertTokenLayer |
| 2 | Communication & Oracle | Transport / authorize under Chain-1 | OrchestrationEngine, KnowledgeLedger |
| 3 | AI Cognitive | **No** — advisory data only | AIExecutor |
| 0 | Physical Execution | Off-chain TEE / agents under attested policy | (external) |

---

## Invariant 4.2 — AI Cannot Execute

> An address possessing Chain-3 advisory authority MUST NOT be able
> to directly or indirectly invoke arbitrary external contract calls,
> governance execution, rollback, or other binding state transitions.
>
> AI output is **advisory data only**.
>
> Binding state transitions require Chain-1 governance authority or
> another explicitly authorized **non-AI** execution boundary.

### Acceptance (B1)

`contracts/AIExecutor.sol` may expose only:

- `registerAgent` / `revokeAgent`
- `processAdvisory` → forwards advisory hash to `OrchestrationEngine.receiveAdvisory`

It MUST NOT expose:

- `target.call(...)` or any arbitrary external call
- `executeAuthorized` or equivalent execution primitives
- `triggerRevert` / rollback requests
- KnowledgeLedger mutation that implies post-execution authority from AI roles

### Separation of concerns

```text
AIExecutor (Chain-3)
    → advisory state
    → advisory hash to OrchestrationEngine
    ✗ arbitrary execution
    ✗ governance / revert actuation

Chain-1 governance (DAOGovernor + roles)
    → authorized actuation path

OrchestrationEngine (Chain-2)
    → receive advisory
    → authorize proposal under EXECUTOR_ROLE (governance), not AI
```

Do **not** restore execution primitives inside `AIExecutor` behind an extra role.
Execution belongs on a separately named, governance-controlled component if required later.

---

## Related invariants (stubs for B2+)

| ID | Summary | Status |
|----|---------|--------|
| 3.1 / 3.2 | Revert tokens + monotonic rollback | Present in RevertTokenLayer; inverse calldata integrity deferred to B2 |
| 4.1 | Proposal authorization is Chain-1 / EXECUTOR_ROLE | OrchestrationEngine.authorizeProposal |
| 5.1 | Advisory provenance | processAdvisory + receiveAdvisory |
| 6.1 | Soulbound / NFC governance identity | GovernanceNFT |
| 7.x | Knowledge provenance on ledger | KnowledgeLedger |

---

## Repository boundary

- **Canonical implementation:** `contracts/`
- **Historical sketches:** `legacy/` (not deploy targets)
- **Sovereign offline core:** `beyond-repair/sovereign-clean-room` (Group A) — not subordinate to BlockSwarm

Optional future bridge: one-way attestation from Clean-Room ledger hashes into KnowledgeLedger. Clean-Room remains the offline trust root.
