// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import "../contracts/RevertTokenLayer.sol";

/**
 * @title RevertTokenInverseBindingTest
 * @notice B2: keccak256(inverseCalldata) must match inverseActionHash before call.
 *
 *   forge test --match-contract RevertTokenInverseBindingTest -vv
 */
contract RevertTokenInverseBindingTest is Test {
    RevertTokenLayer internal layer;

    address internal constant GOVERNANCE = address(0xA11CE);
    address internal constant ORCHESTRATOR = address(0xB0B);

    function setUp() public {
        RevertTokenLayer implementation = new RevertTokenLayer();
        bytes memory initData =
            abi.encodeWithSelector(RevertTokenLayer.initialize.selector, GOVERNANCE);

        layer = RevertTokenLayer(address(new ERC1967Proxy(address(implementation), initData)));

        // Read role id before prank — vm.prank applies to the next call only.
        bytes32 orchestratorRole = layer.ORCHESTRATOR_ROLE();
        vm.prank(GOVERNANCE);
        layer.grantRole(orchestratorRole, ORCHESTRATOR);
    }

    // -----------------------------------------------------------------------
    // Helpers
    // -----------------------------------------------------------------------

    function _viewTokenCalldata(uint256 tokenId) internal pure returns (bytes memory) {
        return abi.encodeWithSelector(RevertTokenLayer.getRevertToken.selector, tokenId);
    }

    function _mint(bytes32 inverseHash, bytes32 dag) internal returns (uint256 tokenId) {
        vm.prank(ORCHESTRATOR);
        tokenId = layer.mintRevertToken(
            bytes32(uint256(1)),
            bytes32(uint256(2)),
            bytes32(uint256(3)),
            dag,
            inverseHash,
            /* proposalId */ 1
        );
    }

    // -----------------------------------------------------------------------
    // Cases
    // -----------------------------------------------------------------------

    function test_matchingCalldata_allowsRollback() public {
        bytes memory inverseCalldata = _viewTokenCalldata(1);
        bytes32 invHash = keccak256(inverseCalldata);
        uint256 tokenId = _mint(invHash, keccak256("dag-match"));

        vm.prank(GOVERNANCE);
        layer.requestRollback(tokenId, inverseCalldata);

        assertEq(layer.getRevertToken(tokenId).inverseActionHash, invHash);
    }

    function test_mismatchedCalldata_reverts() public {
        bytes memory correct = _viewTokenCalldata(1);
        uint256 tokenId = _mint(keccak256(correct), keccak256("dag-mismatch"));

        bytes memory wrong = _viewTokenCalldata(999);
        assertTrue(keccak256(wrong) != keccak256(correct));

        vm.prank(GOVERNANCE);
        vm.expectRevert(bytes("Inverse calldata hash mismatch"));
        layer.requestRollback(tokenId, wrong);
    }

    function test_hashIsOverExactSuppliedBytes() public {
        bytes memory exact = hex"deadbeef";
        bytes memory extended = hex"deadbeef00";
        assertTrue(keccak256(exact) != keccak256(extended));

        uint256 tokenId = _mint(keccak256(exact), keccak256("dag-exact"));

        vm.prank(GOVERNANCE);
        vm.expectRevert(bytes("Inverse calldata hash mismatch"));
        layer.requestRollback(tokenId, extended);

        // Hash matches but no function exists → fails after the binding check
        vm.prank(GOVERNANCE);
        vm.expectRevert(bytes("Inverse/compensation failed"));
        layer.requestRollback(tokenId, exact);
    }

    function test_checkOccursBeforeCall_mismatchLeavesNoSideEffect() public {
        bytes memory correct = _viewTokenCalldata(1);
        uint256 tokenId = _mint(keccak256(correct), keccak256("dag-order"));

        bytes memory wrong = _viewTokenCalldata(1);
        wrong[wrong.length - 1] = 0x02;

        vm.prank(GOVERNANCE);
        vm.expectRevert(bytes("Inverse calldata hash mismatch"));
        layer.requestRollback(tokenId, wrong);

        RevertTokenLayer.RevertToken memory token = layer.getRevertToken(tokenId);
        assertEq(token.inverseActionHash, keccak256(correct));
        assertTrue(token.timestamp != 0);
    }

    function test_emptyCalldata_onlyIfPrecommitted() public {
        bytes memory empty = "";
        uint256 tokenId = _mint(keccak256(empty), keccak256("dag-empty"));

        vm.prank(GOVERNANCE);
        vm.expectRevert(bytes("Inverse/compensation failed"));
        layer.requestRollback(tokenId, empty);
    }
}
