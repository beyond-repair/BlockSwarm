// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../contracts/libraries/MerkleProof.sol";
import "../contracts/MerkleVerifier.sol";

/**
 * @title MerkleProofTest
 * @notice Unit tests for sorted-pair Merkle verification.
 *
 * Run:
 *   forge test --match-contract MerkleProofTest -vv
 */
contract MerkleProofTest is Test {
    MerkleVerifier internal verifier;

    function setUp() public {
        verifier = new MerkleVerifier();
    }

    function test_singleLeaf_isRoot() public pure {
        bytes32 leaf = keccak256("solo");
        bytes32[] memory proof = new bytes32[](0);
        assertTrue(MerkleProof.verify(proof, leaf, leaf));
    }

    function test_twoLeaves_inclusion() public pure {
        bytes32 a = keccak256("a");
        bytes32 b = keccak256("b");
        bytes32 root = MerkleProof.commutativeKeccak(a, b);

        bytes32[] memory proofA = new bytes32[](1);
        proofA[0] = b;
        assertTrue(MerkleProof.verify(proofA, root, a));

        bytes32[] memory proofB = new bytes32[](1);
        proofB[0] = a;
        assertTrue(MerkleProof.verify(proofB, root, b));
    }

    function test_orderIndependent_parent() public pure {
        bytes32 x = bytes32(uint256(1));
        bytes32 y = bytes32(uint256(2));
        assertEq(MerkleProof.commutativeKeccak(x, y), MerkleProof.commutativeKeccak(y, x));
    }

    function test_fourLeaves_balanced() public pure {
        // leaves L0..L3
        bytes32 l0 = keccak256("0");
        bytes32 l1 = keccak256("1");
        bytes32 l2 = keccak256("2");
        bytes32 l3 = keccak256("3");

        bytes32 n01 = MerkleProof.commutativeKeccak(l0, l1);
        bytes32 n23 = MerkleProof.commutativeKeccak(l2, l3);
        bytes32 root = MerkleProof.commutativeKeccak(n01, n23);

        // proof for l0: sibling l1, then uncle n23
        bytes32[] memory proof = new bytes32[](2);
        proof[0] = l1;
        proof[1] = n23;
        assertTrue(MerkleProof.verify(proof, root, l0));

        // proof for l3: sibling l2, then uncle n01
        proof[0] = l2;
        proof[1] = n01;
        assertTrue(MerkleProof.verify(proof, root, l3));
    }

    function test_reject_wrongLeaf() public pure {
        bytes32 a = keccak256("a");
        bytes32 b = keccak256("b");
        bytes32 root = MerkleProof.commutativeKeccak(a, b);
        bytes32[] memory proof = new bytes32[](1);
        proof[0] = b;
        assertFalse(MerkleProof.verify(proof, root, keccak256("evil")));
    }

    function test_reject_tamperedProof() public pure {
        bytes32 a = keccak256("a");
        bytes32 b = keccak256("b");
        bytes32 root = MerkleProof.commutativeKeccak(a, b);
        bytes32[] memory proof = new bytes32[](1);
        proof[0] = keccak256("wrong-sibling");
        assertFalse(MerkleProof.verify(proof, root, a));
    }

    function test_facade_verify_and_knowledgeLeaf() public view {
        bytes32 cid = keccak256("cid");
        uint256 proposalId = 7;
        bytes32 dag = keccak256("dag");
        bytes32 leaf = verifier.knowledgeLeaf(cid, proposalId, dag);
        assertEq(leaf, keccak256(abi.encode(cid, proposalId, dag)));

        bytes32[] memory empty = new bytes32[](0);
        assertTrue(verifier.verify(empty, leaf, leaf));
    }

    function test_advisoryLeaf_encoding() public view {
        bytes32 h = verifier.advisoryLeaf(3, keccak256("advice"));
        assertEq(h, keccak256(abi.encode(uint256(3), keccak256("advice"))));
    }

    function testFuzz_commutative(bytes32 a, bytes32 b) public pure {
        assertEq(MerkleProof.commutativeKeccak(a, b), MerkleProof.commutativeKeccak(b, a));
    }

    function testFuzz_selfProof(bytes32 leaf) public pure {
        bytes32[] memory proof = new bytes32[](0);
        assertTrue(MerkleProof.verify(proof, leaf, leaf));
    }
}
