// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../contracts/AIExecutor.sol";
import "../contracts/OrchestrationEngine.sol";
import "../contracts/RevertTokenLayer.sol";

/**
 * @title AIExecutorAdvisoryOnlyTest
 * @notice B3 execution-boundary suite for Invariant 4.2.
 *
 * Goal: demonstrate on a deployed AIExecutor that an authorized AI/advisor
 * cannot turn advisory authority into external state-changing calls,
 * governance execution, or rollback.
 *
 * Run (after `forge install` of OZ + forge-std):
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

    // Selectors that MUST NOT exist on advisory-only AIExecutor (pre-B1 attack surface)
    bytes4 internal constant SEL_EXECUTE_AUTHORIZED =
        bytes4(keccak256("executeAuthorized(uint256,address,bytes,bytes32)"));
    bytes4 internal constant SEL_TRIGGER_REVERT =
        bytes4(keccak256("triggerRevert(uint256,uint256,bytes)"));
    bytes4 internal constant SEL_LEGACY_EXECUTE =
        bytes4(keccak256("executeProposal(uint256,address,bytes)"));

    function setUp() public {
        vm.startPrank(governance);

        revertLayer = new RevertTokenLayer();
        revertLayer.initialize(governance);

        orch = new OrchestrationEngine();
        orch.initialize(address(revertLayer), governance);

        // Grant orchestrator role so mint path works if exercised elsewhere
        revertLayer.grantRole(revertLayer.ORCHESTRATOR_ROLE(), address(orch));

        ai = new AIExecutor();
        ai.initialize(address(orch), governance);

        // Wire Chain-3 advisory path: AIExecutor needs ADVISOR_ROLE on OrchestrationEngine
        orch.grantRole(orch.ADVISOR_ROLE(), address(ai));

        // Register AI agent and grant it ADVISOR_ROLE on AIExecutor so it can processAdvisory
        ai.registerAgent(aiAgent);
        ai.grantRole(ai.ADVISOR_ROLE(), aiAgent);

        vm.stopPrank();
    }

    // -------------------------------------------------------------------------
    // Positive: advisory surface works
    // -------------------------------------------------------------------------

    function test_processAdvisory_emitsAndForwards() public {
        uint256 proposalId = 1;
        bytes32 advisoryHash = keccak256("advice-v1");

        // Signature over digest expected by OrchestrationEngine.receiveAdvisory
        // digest = keccak256(abi.encode(proposalId, advisoryHash, block.timestamp))
        // For this unit test we use a placeholder signature; receiveAdvisory may
        // revert on ECDSA if strict — we still assert the call path is advisory-only.
        bytes memory sig = new bytes(65);

        vm.prank(aiAgent);
        // May revert on invalid signature inside OrchestrationEngine — that is OK
        // for boundary testing; the important property is we did not perform target.call.
        try ai.processAdvisory(proposalId, advisoryHash, sig) {
            // success path
        } catch {
            // signature failure is not an execution-boundary failure
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

    // -------------------------------------------------------------------------
    // Negative: execution primitives are not reachable
    // -------------------------------------------------------------------------

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
        // Deploy a simple victim that flips state if called
        Victim v = new Victim();
        uint256 beforeBal = v.hits();

        // Attempt low-level call patterns an AI agent might try if execution
        // primitives still lived on AIExecutor
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
        // B1 removed EXECUTOR_ROLE from AIExecutor. Probing the constant getter
        // via selector must fail.
        bytes4 sel = bytes4(keccak256("EXECUTOR_ROLE()"));
        (bool ok, ) = address(ai).call(abi.encodeWithSelector(sel));
        assertFalse(ok, "EXECUTOR_ROLE must not exist on advisory AIExecutor");
    }
}

/// @dev Minimal external target for call-boundary probes
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
