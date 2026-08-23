// scripts/deployment/deploy_sagf.js
// B2b-3: Deploy SAGF upgradeable stack behind ERC1967Proxy and wire roles.
// Does not change voting (B2b-1) or role *logic* (B2b-2) — only init/wiring.
const hre = require("hardhat");
const fs = require("fs");
const path = require("path");

async function deployProxy(implFactory, initData) {
    const impl = await implFactory.deploy();
    await impl.waitForDeployment();
    const Proxy = await hre.ethers.getContractFactory(
        "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol:ERC1967Proxy"
    );
    const proxy = await Proxy.deploy(await impl.getAddress(), initData);
    await proxy.waitForDeployment();
    return hre.ethers.getContractAt(
        await implFactory.interface.format ? implFactory.interface : implFactory,
        await proxy.getAddress()
    ).catch(async () => {
        // attach via contract name
        return proxy;
    });
}

async function main() {
    const [deployer] = await hre.ethers.getSigners();
    const admin = deployer.address;
    console.log("Deploying BlockSwarm SAGF (B2b-3 wiring) with admin:", admin);

    const ERC1967Proxy = await hre.ethers.getContractFactory(
        "contracts/../node_modules/@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol:ERC1967Proxy"
    ).catch(() => null);

    // Prefer OpenZeppelin upgrades plugin when available; else manual proxy.
    async function uups(name, initArgs) {
        const Factory = await hre.ethers.getContractFactory(name);
        if (hre.upgrades && hre.upgrades.deployProxy) {
            const proxy = await hre.upgrades.deployProxy(Factory, initArgs, {
                kind: "uups",
                initializer: "initialize",
            });
            await proxy.waitForDeployment();
            return proxy;
        }
        // Manual: deploy impl + ERC1967Proxy with encoded initialize
        const impl = await Factory.deploy();
        await impl.waitForDeployment();
        const initData = Factory.interface.encodeFunctionData("initialize", initArgs);
        let ProxyFactory;
        try {
            ProxyFactory = await hre.ethers.getContractFactory("ERC1967Proxy");
        } catch {
            ProxyFactory = await hre.ethers.getContractFactory(
                "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol:ERC1967Proxy"
            );
        }
        const proxy = await ProxyFactory.deploy(await impl.getAddress(), initData);
        await proxy.waitForDeployment();
        return Factory.attach(await proxy.getAddress());
    }

    // 1. Identity
    const nft = await uups("GovernanceNFT", [admin]);
    console.log("GovernanceNFT:", await nft.getAddress());

    // 2. Revert layer
    const revertLayer = await uups("RevertTokenLayer", [admin]);
    console.log("RevertTokenLayer:", await revertLayer.getAddress());

    // 3. Orchestration
    const orchestrator = await uups("OrchestrationEngine", [
        await revertLayer.getAddress(),
        admin,
    ]);
    console.log("OrchestrationEngine:", await orchestrator.getAddress());

    // 4. Knowledge ledger
    const knowledgeLedger = await uups("KnowledgeLedger", [admin]);
    console.log("KnowledgeLedger:", await knowledgeLedger.getAddress());

    // 5. DAO Governor
    const dao = await uups("DAOGovernor", [
        await nft.getAddress(),
        await revertLayer.getAddress(),
        await orchestrator.getAddress(),
        admin,
    ]);
    console.log("DAOGovernor:", await dao.getAddress());

    // 6. AI Executor (advisory only)
    const aiExecutor = await uups("AIExecutor", [
        await orchestrator.getAddress(),
        admin,
    ]);
    console.log("AIExecutor:", await aiExecutor.getAddress());

    // 7. Merkle verifier (stateless — plain deploy)
    const MerkleVerifier = await hre.ethers.getContractFactory("MerkleVerifier");
    const merkle = await MerkleVerifier.deploy();
    await merkle.waitForDeployment();
    console.log("MerkleVerifier:", await merkle.getAddress());

    // ----- Cross-contract role wiring (B2b-3) -----
    const ORCHESTRATOR_ROLE = await revertLayer.ORCHESTRATOR_ROLE();
    await (await revertLayer.grantRole(ORCHESTRATOR_ROLE, await orchestrator.getAddress())).wait();

    const ADVISOR_ROLE = await orchestrator.ADVISOR_ROLE();
    await (await orchestrator.grantRole(ADVISOR_ROLE, await aiExecutor.getAddress())).wait();

    // Governor must hold orch EXECUTOR_ROLE so executeProposal → authorizeProposal succeeds
    const EXECUTOR_ROLE = await orchestrator.EXECUTOR_ROLE();
    await (await orchestrator.grantRole(EXECUTOR_ROLE, await dao.getAddress())).wait();

    const addresses = {
        governanceNFT: await nft.getAddress(),
        daoGovernor: await dao.getAddress(),
        revertTokenLayer: await revertLayer.getAddress(),
        orchestrationEngine: await orchestrator.getAddress(),
        knowledgeLedger: await knowledgeLedger.getAddress(),
        aiExecutor: await aiExecutor.getAddress(),
        merkleVerifier: await merkle.getAddress(),
        admin,
        wiring: {
            revertLayer_ORCHESTRATOR_ROLE: await orchestrator.getAddress(),
            orch_ADVISOR_ROLE: await aiExecutor.getAddress(),
            orch_EXECUTOR_ROLE: await dao.getAddress(),
            dao_DEFAULT_ADMIN: admin,
            dao_PROPOSER: admin,
            dao_EXECUTOR: admin,
        },
        notes: {
            aiExecutor: "B1 advisory-only",
            invariant_4_2: "AI cannot execute",
            b2b3: "proxy init + cross-contract roles",
        },
    };

    console.log("\n=== SAGF Deployment Complete (B2b-3) ===");
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
