# BlockSwarm Governance

**Classification:** ACTIVE (P2)
**Governing source:** [ADL-Governance](https://github.com/beyond-repair/ADL-Governance)
**Sweep:** 309 (2026-10-12)

## Claim cap

- On-chain contracts and Foundry tests in this repository are the only executable claims.
- "AI advises. It cannot execute." is an **intended invariant** of `AIExecutor` as tested; it is not a proof of production deployment or mainnet usage.
- No claim of deployed production network, audited mainnet, or economic security is authorized by this file.
- SAGF v0.5.0 is a **named candidate**. Tag + GitHub Release remain operator-only (see ADL-Governance `docs/OPERATOR_QUEUE.md`).

## Tests / CI

- Local: `forge test -vv`
- CI: `.github/workflows/foundry.yml`
- Last verified CI: green run id **36859452185** (2026-10-01, head `6e90f6f85c0969fa8a262a70ceba833d618a22db`).

## Lifecycle

ACTIVE until operator archives or a successor is named in README.
Do not delete history.
