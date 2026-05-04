// scripts/deployment/deploy_sagf.js
const hre = require("hardhat");

async function main() {
    const [deployer] = await hre.ethers.getSigners();
    console.log("Deploying BlockSwarm SAGF (chain1) with account:", deployer.address);

    // 1. Deploy GovernanceNFT v2 (SBT Root)
    const GovernanceNFT = await hre.ethers.getContractFactory("GovernanceNFT");
    const nft = await GovernanceNFT.deploy();
    await nft.waitForDeployment();
    await nft.initialize(deployer.address);
    console.log("GovernanceNFT (SBT) deployed to:", nft.target);

    // 2. Deploy RevertTokenLayer
    const RevertTokenLayer = await hre.ethers.getContractFactory("RevertTokenLayer");
    const revertLayer = await RevertTokenLayer.deploy();
    await revertLayer.waitForDeployment();
    await revertLayer.initialize(deployer.address);
    console.log("RevertTokenLayer deployed to:", revertLayer.target);

    // 3. Deploy OrchestrationEngine
    const OrchestrationEngine = await hre.ethers.getContractFactory("OrchestrationEngine");
    const orchestrator = await OrchestrationEngine.deploy();
    await orchestrator.waitForDeployment();
    await orchestrator.initialize(revertLayer.target, deployer.address);
    console.log("OrchestrationEngine deployed to:", orchestrator.target);

    // 4. Deploy KnowledgeLedger
    const KnowledgeLedger = await hre.ethers.getContractFactory("KnowledgeLedger");
    const knowledgeLedger = await KnowledgeLedger.deploy();
    await knowledgeLedger.waitForDeployment();
    await knowledgeLedger.initialize(deployer.address);
    console.log("KnowledgeLedger deployed to:", knowledgeLedger.target);

    // 5. Deploy DAOGovernor v2
    const DAOGovernor = await hre.ethers.getContractFactory("DAOGovernor");
    const dao = await DAOGovernor.deploy();
    await dao.waitForDeployment();
    await dao.initialize(
        nft.target,
        revertLayer.target,
        orchestrator.target,
        deployer.address
    );
    console.log("DAOGovernor v2 deployed to:", dao.target);

    // 6. Deploy AIExecutor v2
    const AIExecutor = await hre.ethers.getContractFactory("AIExecutor");
    const aiExecutor = await AIExecutor.deploy();
    await aiExecutor.waitForDeployment();
    await aiExecutor.initialize(
        orchestrator.target,
        revertLayer.target,
        knowledgeLedger.target,
        deployer.address
    );
    console.log("AIExecutor v2 deployed to:", aiExecutor.target);

    // Save addresses for frontend / agents
    const addresses = {
        governanceNFT: nft.target,
        daoGovernor: dao.target,
        revertTokenLayer: revertLayer.target,
        orchestrationEngine: orchestrator.target,
        knowledgeLedger: knowledgeLedger.target,
        aiExecutor: aiExecutor.target,
        deployer: deployer.address
    };

    console.log("\n=== SAGF (chain1) Deployment Complete ===");
    console.dir(addresses, { depth: null });

    // TODO: Write to .env or deployment.json
}

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });
