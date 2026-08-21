// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./libraries/MerkleProof.sol";

/**
 * @title MerkleVerifier
 * @notice Thin, non-upgradeable facade exposing Merkle inclusion checks.
 *
 * Intended for:
 *   - Off-chain tools / indexers calling staticcall
 *   - Other contracts verifying KnowledgeLedger or advisory roots
 *   - Clean-Room → BlockSwarm one-way attestation of a root + proof
 *
 * Stateless: no storage, no roles, no Chain-3 authority.
 */
contract MerkleVerifier {
    using MerkleProof for bytes32[];

    /**
     * @notice Verify leaf inclusion under root.
     */
    function verify(
        bytes32[] calldata proof,
        bytes32 root,
        bytes32 leaf
    ) external pure returns (bool) {
        return MerkleProof.verifyCalldata(proof, root, leaf);
    }

    /**
     * @notice Reconstruct root from leaf + proof (debug / indexers).
     */
    function processProof(
        bytes32[] calldata proof,
        bytes32 leaf
    ) external pure returns (bytes32) {
        return MerkleProof.processProofCalldata(proof, leaf);
    }

    /**
     * @notice Multi-leaf inclusion under one root.
     */
    function multiProofVerify(
        bytes32[] calldata proof,
        bool[] calldata proofFlags,
        bytes32 root,
        bytes32[] calldata leaves
    ) external pure returns (bool) {
        // Copy calldata arrays into memory for library multiproof
        bytes32[] memory proofMem = proof;
        bool[] memory flagsMem = proofFlags;
        bytes32[] memory leavesMem = leaves;
        return MerkleProof.multiProofVerify(proofMem, flagsMem, root, leavesMem);
    }

    /**
     * @notice Application leaf: keccak256(contentCID, proposalId, causalDAGHash).
     * @dev Matches a conventional KnowledgeLedger-oriented leaf encoding.
     */
    function knowledgeLeaf(
        bytes32 contentCID,
        uint256 proposalId,
        bytes32 causalDAGHash
    ) external pure returns (bytes32) {
        return keccak256(abi.encode(contentCID, proposalId, causalDAGHash));
    }

    /**
     * @notice Application leaf: keccak256(proposalId, advisoryHash).
     */
    function advisoryLeaf(
        uint256 proposalId,
        bytes32 advisoryHash
    ) external pure returns (bytes32) {
        return keccak256(abi.encode(proposalId, advisoryHash));
    }
}
