// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import "../contracts/DAOGovernor.sol";
import "../contracts/GovernanceNFT.sol";
import "../contracts/RevertTokenLayer.sol";
import "../contracts/OrchestrationEngine.sol";
import "../contracts/AIExecutor.sol";
import "../contracts/KnowledgeLedger.sol";
import "../contracts/MerkleVerifier.sol";

/**
 * @title SAGFDeployWiringTest
 * @notice B2b-3: post-deploy init and cross-contract role wiring.
 *
 *   forge test --match-contract SAGFDeployWiringTest -vv
 */
contract SAGFDeployWiringTest is Test {
    address internal admin = address(0xA11CE);

    GovernanceNFT internal nft;
    RevertTokenLayer internal revertLayer;
    OrchestrationEngine internal orch;
    KnowledgeLedger internal ledger;
    DAOGovernor internal dao;
    AIExecutor internal ai;
    MerkleVerifier internal merkle;

    function _proxy(address impl, bytes memory initData) internal returns (address) {
        return address(new ERC1967Proxy(impl, initData));
    }

    function setUp() public {
        // Deploy implementations + proxies with initialize (production path)
        nft = GovernanceNFT(
            _proxy(
                address(new GovernanceNFT()),
                abi.encodeWithSelector(GovernanceNFT.initialize.selector, admin)
            )
        );

        revertLayer = RevertTokenLayer(
            _proxy(
                address(new RevertTokenLayer()),
                abi.encodeWithSelector(RevertTokenLayer.initialize.selector, admin)
            )
        );

        orch = OrchestrationEngine(
            _proxy(
                address(new OrchestrationEngine()),
                abi.encodeWithSelector(
                    OrchestrationEngine.initialize.selector,
                    address(revertLayer),
                    admin
                )
            )
        );

        ledger = KnowledgeLedger(
            _proxy(
                address(new KnowledgeLedger()),
                abi.encodeWithSelector(KnowledgeLedger.initialize.selector, admin)
            )
        );

        dao = DAOGovernor(
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

        ai = AIExecutor(
            _proxy(
                address(new AIExecutor()),
                abi.encodeWithSelector(AIExecutor.initialize.selector, address(orch), admin)
            )
        );

        merkle = new MerkleVerifier();

        // B2b-3 cross-contract wiring
        vm.startPrank(admin);
        revertLayer.grantRole(revertLayer.ORCHESTRATOR_ROLE(), address(orch));
        orch.grantRole(orch.ADVISOR_ROLE(), address(ai));
        orch.grantRole(orch.EXECUTOR_ROLE(), address(dao));
        vm.stopPrank();
    }

    function test_dao_admin_bootstrap_roles() public view {
        assertTrue(dao.hasRole(dao.DEFAULT_ADMIN_ROLE(), admin));
        assertTrue(dao.hasRole(dao.PROPOSER_ROLE(), admin));
        assertTrue(dao.hasRole(dao.EXECUTOR_ROLE(), admin));
    }

    function test_dao_wired_to_dependencies() public view {
        assertEq(address(dao.sbtContract()), address(nft));
        assertEq(address(dao.revertLayer()), address(revertLayer));
        assertEq(address(dao.orchestrator()), address(orch));
    }

    function test_revertLayer_orchestrator_role() public view {
        assertTrue(revertLayer.hasRole(revertLayer.ORCHESTRATOR_ROLE(), address(orch)));
    }

    function test_orch_advisor_is_aiExecutor() public view {
        assertTrue(orch.hasRole(orch.ADVISOR_ROLE(), address(ai)));
    }

    function test_orch_executor_includes_dao() public view {
        assertTrue(orch.hasRole(orch.EXECUTOR_ROLE(), address(dao)));
    }

    function test_ai_points_at_orchestrator() public view {
        assertEq(address(ai.orchestrator()), address(orch));
        assertTrue(ai.hasRole(ai.DEFAULT_ADMIN_ROLE(), admin));
    }

    function test_ai_has_no_executor_role_constant() public {
        // Chain-3 must not expose EXECUTOR_ROLE (B1)
        (bool ok, ) = address(ai).call(abi.encodeWithSignature("EXECUTOR_ROLE()"));
        assertFalse(ok);
    }

    function test_stranger_cannot_grant_dao_roles() public {
        address stranger = address(0xBAD);
        vm.prank(stranger);
        vm.expectRevert();
        dao.grantProposer(stranger);
    }

    function test_merkle_deployed() public view {
        assertTrue(address(merkle) != address(0));
    }
}
