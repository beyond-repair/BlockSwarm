# Security Policy

## Supported versions

This repository is an ACTIVE research-to-candidate Solidity stack. No mainnet deployment is claimed.

| Version | Supported |
|---------|-----------|
| `main` (SAGF candidate) | Yes (issue reports) |
| Tagged releases | After operator creates them |

## Reporting

Open a GitHub issue with the `security` label, or contact the owner via GitHub.
Do not file exploit details in public issues if a live deployment exists.

## Invariants (claim-capped)

- AI executor path is advisory-only in tests (`test/AIExecutorAdvisoryOnly.t.sol`).
- Merkle / revert-token bindings are validated only to the extent of Foundry tests in `test/`.
- No formal audit report is bundled as a verified claim.
