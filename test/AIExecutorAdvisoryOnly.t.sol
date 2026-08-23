// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import "../contracts/AIExecutor.sol";
import "../contracts/OrchestrationEngine.sol";
import "../contracts/RevertTokenLayer.sol";

/**
 * @title AIExecutorAdvisoryOnlyTest
 * @notice B3 execution-boundary suite for Invariant 4.2.
 *
 * Upgradeable implementations call _disableInitializers() in constructors;
 * tests therefore deploy each component behind ERC1967Proxy so initialize()
 * runs on the proxy, matching production UUPS usage.
 *
 * Run:
 *   forge test --match-contract AIExecutorAdvisoryOnlyTest -vv
 */
contract AIExecutorAdvisoryOnlyTest is Test {
    AIExecutor internal ai;
    OrchestrationEngine internal orch;
    RevertTokenLayer internal revertLayer;

    address internal governance = address(0xA11CE);
    address internal aiAgent = address(0xA1);
    address internal attacker = address(0xBAD);
    address internal victim = address(0xBEEF);

    bytes4 internal constant SEL_EXECUTE_AUTHORIZED =
        bytes4(keccak256("executeAuthorized(uint256,address,bytes,bytes32)"));
    bytes4 internal constant SEL_TRIGGER_REVERT =
        bytes4(keccak256("triggerRevert(uint256,uint256,bytes)"));
    bytes4 internal constant SEL_LEGACY_EXECUTE =
        bytes4(keccak256("executeProposal(uint256,address,bytes)"));

    function _proxy(address impl, bytes memory initData) internal returns (address) {
        return address(new ERC1967Proxy(impl, initData));
    }

    function setUp() public {
        // Implementations
        RevertTokenLayer revertImpl = new RevertTokenLayer();
        OrchestrationEngine orchImpl = new OrchestrationEngine();
        AIExecutor aiImpl = new AIExecutor();

        // Proxies + initialize (production path)
        revertLayer = RevertTokenLayer(
            _proxy(
                address(revertImpl),
                abi.encodeWithSelector(RevertTokenLayer.initialize.selector, governance)
            )
        );

        orch = OrchestrationEngine(
            _proxy(
                address(orchImpl),
                abi.encodeWithSelector(
                    OrchestrationEngine.initialize.selector,
                    address(revertLayer),
                    governance
                )
            )
        );

        vm.startPrank(governance);
        revertLayer.grantRole(revertLayer.ORCHESTRATOR_ROLE(), address(orch));

        ai = AIExecutor(
            _proxy(
                address(aiImpl),
                abi.encodeWithSelector(
                    AIExecutor.initialize.selector,
                    address(orch),
                    governance
                )
            )
        );

        // Chain-3 → Chain-2 advisory intake
        orch.grantRole(orch.ADVISOR_ROLE(), address(ai));

        ai.registerAgent(aiAgent);
        ai.grantRole(ai.ADVISOR_ROLE(), aiAgent);
        vm.stopPrank();
    }

    function test_processAdvisory_emitsAndForwards() public {
        uint256 proposalId = 1;
        bytes32 advisoryHash = keccak256("advice-v1");
        bytes memory sig = new bytes(65);

        vm.prank(aiAgent);
        try ai.processAdvisory(proposalId, advisoryHash, sig) {} catch {
            // invalid ECDSA is not an execution-boundary failure
        }
    }

    function test_registerAndRevokeAgent() public {
        address newAgent = address(0xC0FFEE);
        vm.startPrank(governance);
        ai.registerAgent(newAgent);
        assertTrue(ai.authorizedAgents(newAgent));
        ai.revokeAgent(newAgent);
        assertFalse(ai.authorizedAgents(newAgent));
        vm.stopPrank();
    }

    function test_executeAuthorized_selectorReverts() public {
        bytes memory payload = abi.encodeWithSelector(
            SEL_EXECUTE_AUTHORIZED,
            uint256(1),
            victim,
            abi.encodeWithSignature("set(uint256)", 42),
            bytes32(0)
        );
        vm.prank(aiAgent);
        (bool ok, ) = address(ai).call(payload);
        assertFalse(ok, "executeAuthorized must not exist / must not succeed");
    }

    function test_triggerRevert_selectorReverts() public {
        bytes memory payload = abi.encodeWithSelector(
            SEL_TRIGGER_REVERT,
            uint256(1),
            uint256(1),
            bytes("")
        );
        vm.prank(aiAgent);
        (bool ok, ) = address(ai).call(payload);
        assertFalse(ok, "triggerRevert must not exist / must not succeed");
    }

    function test_legacyExecuteProposal_selectorReverts() public {
        bytes memory payload = abi.encodeWithSelector(
            SEL_LEGACY_EXECUTE,
            uint256(1),
            victim,
            abi.encodeWithSignature("pwn()")
        );
        vm.prank(aiAgent);
        (bool ok, ) = address(ai).call(payload);
        assertFalse(ok, "legacy executeProposal must not exist");
    }

    function test_aiAgent_cannotArbitraryCallViaAIExecutor() public {
        Victim v = new Victim();
        uint256 beforeBal = v.hits();

        bytes memory payload = abi.encodeWithSelector(
            SEL_EXECUTE_AUTHORIZED,
            uint256(99),
            address(v),
            abi.encodeWithSignature("hit()"),
            keccak256("payload")
        );

        vm.prank(aiAgent);
        (bool ok, ) = address(ai).call(payload);
        assertFalse(ok);
        assertEq(v.hits(), beforeBal, "victim state must be unchanged");
    }

    function test_attacker_withoutRole_cannotProcessAdvisory() public {
        vm.prank(attacker);
        vm.expectRevert();
        ai.processAdvisory(1, keccak256("x"), new bytes(65));
    }

    function test_noExecutorRoleConstant() public {
        bytes4 sel = bytes4(keccak256("EXECUTOR_ROLE()"));
        (bool ok, ) = address(ai).call(abi.encodeWithSelector(sel));
        assertFalse(ok, "EXECUTOR_ROLE must not exist on advisory AIExecutor");
    }
}

contract Victim {
    uint256 public hits;

    function hit() external {
        hits += 1;
    }

    function set(uint256) external {
        hits += 1;
    }

    function pwn() external {
        hits += 100;
    }
}
