# BlockSwarm Governance

**Classification:** ACTIVE (P2)
**Governing source:** [ADL-Governance](https://github.com/beyond-repair/ADL-Governance)
**Sweep:** 056 (2026-09-05)

## Claim cap

- On-chain contracts and Foundry tests in this repository are the only executable claims.
- "AI advises. It cannot execute." is an **intended invariant** of `AIExecutor` as tested; it is not a proof of production deployment or mainnet usage.
- No claim of deployed production network, audited mainnet, or economic security is authorized by this file.
- SAGF v0.5.0 is a **named candidate**. Tag + GitHub Release remain operator-only (see ADL-Governance `docs/OPERATOR_QUEUE.md`).

## Tests / CI

- Local: `forge test -vv`
- CI: `.github/workflows/foundry.yml`
- Prior empirical CI status: green (Sweep-050 run id 32707027387). Re-verify on Actions after any contract change.

## Lifecycle

ACTIVE until operator archives or a successor is named in README.
Do not delete history.
