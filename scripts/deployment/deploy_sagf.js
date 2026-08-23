// scripts/deployment/deploy_sagf.js
// Deploys canonical contracts/ package (B1 advisory-only AIExecutor).
const hre = require("hardhat");
const fs = require("fs");
const path = require("path");

async function main() {
    const [deployer] = await hre.ethers.getSigners();
    console.log("Deploying BlockSwarm SAGF with account:", deployer.address);

    // 1. GovernanceNFT (Chain-1 identity)
    const GovernanceNFT = await hre.ethers.getContractFactory("GovernanceNFT");
    const nft = await GovernanceNFT.deploy();
    await nft.waitForDeployment();
    await nft.initialize(deployer.address);
    console.log("GovernanceNFT:", await nft.getAddress());

    // 2. RevertTokenLayer (Chain-1 reversibility)
    const RevertTokenLayer = await hre.ethers.getContractFactory("RevertTokenLayer");
    const revertLayer = await RevertTokenLayer.deploy();
    await revertLayer.waitForDeployment();
    await revertLayer.initialize(deployer.address);
    console.log("RevertTokenLayer:", await revertLayer.getAddress());

    // 3. OrchestrationEngine (Chain-2)
    const OrchestrationEngine = await hre.ethers.getContractFactory("OrchestrationEngine");
    const orchestrator = await OrchestrationEngine.deploy();
    await orchestrator.waitForDeployment();
    await orchestrator.initialize(await revertLayer.getAddress(), deployer.address);
    console.log("OrchestrationEngine:", await orchestrator.getAddress());

    // Wire ORCHESTRATOR_ROLE so authorizeProposal can mint revert tokens
    const ORCHESTRATOR_ROLE = await revertLayer.ORCHESTRATOR_ROLE();
    await revertLayer.grantRole(ORCHESTRATOR_ROLE, await orchestrator.getAddress());

    // 4. KnowledgeLedger (Chain-2 provenance)
    const KnowledgeLedger = await hre.ethers.getContractFactory("KnowledgeLedger");
    const knowledgeLedger = await KnowledgeLedger.deploy();
    await knowledgeLedger.waitForDeployment();
    await knowledgeLedger.initialize(deployer.address);
    console.log("KnowledgeLedger:", await knowledgeLedger.getAddress());

    // 5. DAOGovernor (Chain-1)
    const DAOGovernor = await hre.ethers.getContractFactory("DAOGovernor");
    const dao = await DAOGovernor.deploy();
    await dao.waitForDeployment();
    await dao.initialize(
        await nft.getAddress(),
        await revertLayer.getAddress(),
        await orchestrator.getAddress(),
        deployer.address
    );
    console.log("DAOGovernor:", await dao.getAddress());

    // 6. AIExecutor (Chain-3 — advisory only; B1 API)
    //    initialize(orchestrator, governance) — no revert/ledger injection
    const AIExecutor = await hre.ethers.getContractFactory("AIExecutor");
    const aiExecutor = await AIExecutor.deploy();
    await aiExecutor.waitForDeployment();
    await aiExecutor.initialize(await orchestrator.getAddress(), deployer.address);
    console.log("AIExecutor (advisory-only):", await aiExecutor.getAddress());

    // Chain-3 → Chain-2: AIExecutor may call receiveAdvisory
    const ADVISOR_ROLE = await orchestrator.ADVISOR_ROLE();
    await orchestrator.grantRole(ADVISOR_ROLE, await aiExecutor.getAddress());

    // 7. Stateless MerkleVerifier (optional tooling)
    const MerkleVerifier = await hre.ethers.getContractFactory("MerkleVerifier");
    const merkle = await MerkleVerifier.deploy();
    await merkle.waitForDeployment();
    console.log("MerkleVerifier:", await merkle.getAddress());

    const addresses = {
        governanceNFT: await nft.getAddress(),
        daoGovernor: await dao.getAddress(),
        revertTokenLayer: await revertLayer.getAddress(),
        orchestrationEngine: await orchestrator.getAddress(),
        knowledgeLedger: await knowledgeLedger.getAddress(),
        aiExecutor: await aiExecutor.getAddress(),
        merkleVerifier: await merkle.getAddress(),
        deployer: deployer.address,
        notes: {
            aiExecutor: "B1 advisory-only; no target.call / triggerRevert",
            invariant_4_2: "AI cannot execute",
        },
    };

    console.log("\n=== SAGF Deployment Complete ===");
    console.dir(addresses, { depth: null });

    const outDir = path.join(__dirname, "..", "..", "deployments");
    fs.mkdirSync(outDir, { recursive: true });
    const outFile = path.join(outDir, `sagf-${hre.network.name}.json`);
    fs.writeFileSync(outFile, JSON.stringify(addresses, null, 2));
    console.log("Wrote", outFile);
}

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });
