// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import "../contracts/DAOGovernor.sol";
import "../contracts/GovernanceNFT.sol";
import "../contracts/RevertTokenLayer.sol";
import "../contracts/OrchestrationEngine.sol";
import "../contracts/AIExecutor.sol";
import "../contracts/KnowledgeLedger.sol";
import "../contracts/MerkleVerifier.sol";

/**
 * @title DeploySAGF
 * @notice B2b-3 Foundry deployment: UUPS proxies + cross-contract roles.
 *
 *   forge script script/DeploySAGF.s.sol:DeploySAGF --rpc-url <RPC> --broadcast
 */
contract DeploySAGF is Script {
    function run() external {
        address admin = msg.sender;
        vm.startBroadcast();

        GovernanceNFT nft = GovernanceNFT(
            _proxy(
                address(new GovernanceNFT()),
                abi.encodeWithSelector(GovernanceNFT.initialize.selector, admin)
            )
        );

        RevertTokenLayer revertLayer = RevertTokenLayer(
            _proxy(
                address(new RevertTokenLayer()),
                abi.encodeWithSelector(RevertTokenLayer.initialize.selector, admin)
            )
        );

        OrchestrationEngine orch = OrchestrationEngine(
            _proxy(
                address(new OrchestrationEngine()),
                abi.encodeWithSelector(
                    OrchestrationEngine.initialize.selector,
                    address(revertLayer),
                    admin
                )
            )
        );

        KnowledgeLedger ledger = KnowledgeLedger(
            _proxy(
                address(new KnowledgeLedger()),
                abi.encodeWithSelector(KnowledgeLedger.initialize.selector, admin)
            )
        );

        DAOGovernor dao = DAOGovernor(
            _proxy(
                address(new DAOGovernor()),
                abi.encodeWithSelector(
                    DAOGovernor.initialize.selector,
                    address(nft),
                    address(revertLayer),
                    address(orch),
                    admin
                )
            )
        );

        AIExecutor ai = AIExecutor(
            _proxy(
                address(new AIExecutor()),
                abi.encodeWithSelector(AIExecutor.initialize.selector, address(orch), admin)
            )
        );

        MerkleVerifier merkle = new MerkleVerifier();

        // Cross-contract wiring
        revertLayer.grantRole(revertLayer.ORCHESTRATOR_ROLE(), address(orch));
        orch.grantRole(orch.ADVISOR_ROLE(), address(ai));
        orch.grantRole(orch.EXECUTOR_ROLE(), address(dao));

        vm.stopBroadcast();

        console2.log("GovernanceNFT", address(nft));
        console2.log("RevertTokenLayer", address(revertLayer));
        console2.log("OrchestrationEngine", address(orch));
        console2.log("KnowledgeLedger", address(ledger));
        console2.log("DAOGovernor", address(dao));
        console2.log("AIExecutor", address(ai));
        console2.log("MerkleVerifier", address(merkle));
        console2.log("admin", admin);
    }

    function _proxy(address impl, bytes memory initData) internal returns (address) {
        return address(new ERC1967Proxy(impl, initData));
    }
}
