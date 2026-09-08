# Changelog

## [Unreleased] — Sweep-117 (2026-09-07)

- Governance lock: classification remains **ACTIVE**.
- Claim cap unchanged: no mainnet, audit, or economic-security claim.
- Last verified Foundry Actions run: **33986287866** (success). Tag `v0.5.0-sagf` remains operator-only.
- No contract mutation this sweep.

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
