# Changelog

## [Unreleased] — Sweep-537 (2026-10-26)

- Randomized portfolio completion sweep confirmation: classification remains **ACTIVE**.
- Claim cap unchanged: **AI advises. It cannot execute.** No mainnet, audit, or economic-security claim.
- Last verified Foundry Actions run: **38252865430** (success on `98480104c353ffd22e1522943a5c5f6545044d18`).
- Tags and releases remain empty (operator residual for `v0.5.0-sagf`).
- No open Dependabot alerts. Submodules pinned (forge-std v1.9.4, OpenZeppelin v4.9.6). Tests under `test/` present.
- No contract mutation this sweep. Documentation only.

## [v0.5.0-sagf] — 2026-08-23

### Production-candidate release

- **B1** Chain-3 AIExecutor advisory-only (Invariant 4.2)
- **B3** Runtime execution-boundary Foundry suite
- **B2a** Inverse calldata ↔ hash binding on RevertTokenLayer
- **B2b-1** One-vote-per-SBT on DAOGovernor
- **B2b-2** PROPOSER / EXECUTOR / admin role helpers
- **B2b-3** ERC1967 proxy deploy + cross-contract role wiring
- **CI** `.github/workflows/foundry.yml`
- **Root cleanup** sketches quarantined (git history retains content)
- **Governance** linked to ADL-Governance

### Tests

Local validation: **45** Foundry tests passed (`forge test`).

### Deploy

- `scripts/deployment/deploy_sagf.js`
- `script/DeploySAGF.s.sol`
