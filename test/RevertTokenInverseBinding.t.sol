// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import "../contracts/RevertTokenLayer.sol";

/**
 * @title RevertTokenInverseBindingTest
 * @notice B2 sole-surface tests: keccak256(inverseCalldata) binding.
 *
 * Run:
 *   forge test --match-contract RevertTokenInverseBindingTest -vv
 */
contract RevertTokenInverseBindingTest is Test {
    RevertTokenLayer internal layer;
    address internal governance = address(0xA11CE);
    address internal orchestrator = address(0xB0B);

    function setUp() public {
        RevertTokenLayer impl = new RevertTokenLayer();
        layer = RevertTokenLayer(
            address(
                new ERC1967Proxy(
                    address(impl),
                    abi.encodeWithSelector(RevertTokenLayer.initialize.selector, governance)
                )
            )
        );

        vm.startPrank(governance);
        layer.grantRole(layer.ORCHESTRATOR_ROLE(), orchestrator);
        vm.stopPrank();
    }

    function _mintWithInverseHash(bytes32 inverseHash, bytes32 dag) internal returns (uint256 tokenId) {
        vm.prank(orchestrator);
        tokenId = layer.mintRevertToken(
            bytes32(uint256(1)),
            bytes32(uint256(2)),
            bytes32(uint256(3)),
            dag,
            inverseHash,
            1
        );
    }

    function test_matchingCalldata_allowsRollback() public {
        bytes memory inverseCalldata =
            abi.encodeWithSelector(RevertTokenLayer.getRevertToken.selector, uint256(1));
        bytes32 invHash = keccak256(inverseCalldata);

        uint256 tokenId = _mintWithInverseHash(invHash, keccak256("dag-match"));

        vm.prank(governance);
        layer.requestRollback(tokenId, inverseCalldata);

        RevertTokenLayer.RevertToken memory rt = layer.getRevertToken(tokenId);
        assertEq(rt.inverseActionHash, invHash);
    }

    function test_mismatchedCalldata_reverts() public {
        bytes memory correct =
            abi.encodeWithSelector(RevertTokenLayer.getRevertToken.selector, uint256(1));
        bytes32 invHash = keccak256(correct);

        uint256 tokenId = _mintWithInverseHash(invHash, keccak256("dag-mismatch"));

        bytes memory wrong =
            abi.encodeWithSelector(RevertTokenLayer.getRevertToken.selector, uint256(999));
        assertTrue(keccak256(wrong) != invHash);

        vm.prank(governance);
        vm.expectRevert(bytes("Inverse calldata hash mismatch"));
        layer.requestRollback(tokenId, wrong);
    }

    function test_hashIsOverExactSuppliedBytes() public {
        bytes memory a = hex"deadbeef";
        bytes memory b = hex"deadbeef00";
        assertTrue(keccak256(a) != keccak256(b));

        uint256 tokenId = _mintWithInverseHash(keccak256(a), keccak256("dag-exact"));

        vm.prank(governance);
        vm.expectRevert(bytes("Inverse calldata hash mismatch"));
        layer.requestRollback(tokenId, b);

        vm.prank(governance);
        vm.expectRevert(bytes("Inverse/compensation failed"));
        layer.requestRollback(tokenId, a);
    }

    function test_checkOccursBeforeCall_mismatchLeavesNoSideEffect() public {
        bytes memory correct =
            abi.encodeWithSelector(RevertTokenLayer.getRevertToken.selector, uint256(1));
        uint256 tokenId = _mintWithInverseHash(keccak256(correct), keccak256("dag-order"));

        bytes memory wrong =
            abi.encodeWithSelector(RevertTokenLayer.getRevertToken.selector, uint256(1));
        wrong[wrong.length - 1] = 0x02;

        vm.prank(governance);
        vm.expectRevert(bytes("Inverse calldata hash mismatch"));
        layer.requestRollback(tokenId, wrong);

        RevertTokenLayer.RevertToken memory rt = layer.getRevertToken(tokenId);
        assertEq(rt.inverseActionHash, keccak256(correct));
        assertTrue(rt.timestamp != 0);
    }

    function test_emptyCalldata_onlyIfPrecommitted() public {
        bytes memory empty = "";
        bytes32 h = keccak256(empty);
        uint256 tokenId = _mintWithInverseHash(h, keccak256("dag-empty"));

        vm.prank(governance);
        vm.expectRevert(bytes("Inverse/compensation failed"));
        layer.requestRollback(tokenId, empty);
    }
}
