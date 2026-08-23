# Release v0.5.0-sagf

**Date:** 2026-08-23  
**Status:** Production candidate (maturity 5 target)

## Verified

- Root clean: sketches removed from repository root
- `forge test`: **45 passed** (local)
- CI workflow: `.github/workflows/foundry.yml`
- Tracks B1–B2b-3 closed
- Governed by ADL-Governance

## Create the git tag (required once)

API tooling in this environment cannot create tags. On a machine with `gh` or git push rights:

```bash
git clone https://github.com/beyond-repair/BlockSwarm.git
cd BlockSwarm
git checkout main
git pull
git tag -a v0.5.0-sagf -m "SAGF production candidate — B1–B2b-3 complete"
git push origin v0.5.0-sagf
# optional: GitHub Release from tag
gh release create v0.5.0-sagf --title "v0.5.0-sagf" --notes-file docs/CHANGELOG.md
```

## Deploy paths

- Foundry: `forge script script/DeploySAGF.s.sol`
- Hardhat: `scripts/deployment/deploy_sagf.js`
