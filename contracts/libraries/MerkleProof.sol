// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title MerkleProof
 * @notice Pure Merkle inclusion verification (sorted pairwise hashing).
 *
 * Use cases in BlockSwarm / SAGF (non-B2):
 *   - KnowledgeLedger contentCID inclusion under a published stateRoot
 *   - Advisory DAG leaf inclusion under an advisory root
 *   - Future one-way Clean-Room attestation roots
 *
 * Does NOT open Chain-3 execution or RevertTokenLayer rollback (B2 still blocked).
 *
 * Hash convention:
 *   leaf = leaf (pre-hashed by caller, e.g. keccak256(abi.encode(...)))
 *   parent = keccak256(abi.encodePacked(min(a,b), max(a,b)))  // sorted pair
 *
 * Compatible with proofs generated offline with the same sorted-pair rule.
 */
library MerkleProof {
    /**
     * @notice Verify `leaf` is in the tree rooted at `root` using `proof`.
     * @param proof Sibling hashes from leaf to root (bottom-up).
     * @param root  Expected Merkle root.
     * @param leaf  Leaf node (already hashed by the application).
     * @return True if the reconstructed root equals `root`.
     */
    function verify(
        bytes32[] memory proof,
        bytes32 root,
        bytes32 leaf
    ) internal pure returns (bool) {
        return processProof(proof, leaf) == root;
    }

    /**
     * @notice Calldata variant to avoid memory copies when proofs are large.
     */
    function verifyCalldata(
        bytes32[] calldata proof,
        bytes32 root,
        bytes32 leaf
    ) internal pure returns (bool) {
        return processProofCalldata(proof, leaf) == root;
    }

    /**
     * @notice Reconstruct root from leaf + proof (memory).
     */
    function processProof(bytes32[] memory proof, bytes32 leaf) internal pure returns (bytes32) {
        bytes32 computed = leaf;
        for (uint256 i = 0; i < proof.length; ) {
            computed = commutativeKeccak(computed, proof[i]);
            unchecked {
                ++i;
            }
        }
        return computed;
    }

    /**
     * @notice Reconstruct root from leaf + proof (calldata).
     */
    function processProofCalldata(
        bytes32[] calldata proof,
        bytes32 leaf
    ) internal pure returns (bytes32) {
        bytes32 computed = leaf;
        for (uint256 i = 0; i < proof.length; ) {
            computed = commutativeKeccak(computed, proof[i]);
            unchecked {
                ++i;
            }
        }
        return computed;
    }

    /**
     * @notice Multi-proof verification: several leaves under one root.
     * @dev `proofFlags[i] == true` means take next hash from the working stack
     *      (combine two processed nodes); false means consume next proof sibling.
     *      Flags length must equal proof.length + leaves.length - 1.
     */
    function multiProofVerify(
        bytes32[] memory proof,
        bool[] memory proofFlags,
        bytes32 root,
        bytes32[] memory leaves
    ) internal pure returns (bool) {
        return processMultiProof(proof, proofFlags, leaves) == root;
    }

    function processMultiProof(
        bytes32[] memory proof,
        bool[] memory proofFlags,
        bytes32[] memory leaves
    ) internal pure returns (bytes32 merkleRoot) {
        uint256 leavesLen = leaves.length;
        uint256 proofLen = proof.length;
        uint256 totalHashes = proofFlags.length;

        require(leavesLen + proofLen - 1 == totalHashes, "MerkleProof: invalid multiproof");

        bytes32[] memory hashes = new bytes32[](totalHashes + leavesLen);
        uint256 leafPos = 0;
        uint256 hashPos = 0;
        uint256 proofPos = 0;

        for (uint256 i = 0; i < totalHashes; ) {
            bytes32 a = leafPos < leavesLen
                ? leaves[leafPos++]
                : hashes[hashPos++];

            bytes32 b = proofFlags[i]
                ? (leafPos < leavesLen ? leaves[leafPos++] : hashes[hashPos++])
                : proof[proofPos++];

            hashes[i] = commutativeKeccak(a, b);
            unchecked {
                ++i;
            }
        }

        if (totalHashes > 0) {
            merkleRoot = hashes[totalHashes - 1];
        } else if (leavesLen > 0) {
            merkleRoot = leaves[0];
        } else {
            merkleRoot = proofLen > 0 ? proof[0] : bytes32(0);
        }
    }

    /**
     * @dev Sorted pairwise keccak — order-independent parent hash.
     */
    function commutativeKeccak(bytes32 a, bytes32 b) internal pure returns (bytes32) {
        return a < b
            ? keccak256(abi.encodePacked(a, b))
            : keccak256(abi.encodePacked(b, a));
    }

    /**
     * @notice Helper: hash an application leaf from arbitrary payload bytes.
     */
    function hashLeaf(bytes memory data) internal pure returns (bytes32) {
        return keccak256(data);
    }

    /**
     * @notice Helper: double-hash (Bitcoin-style) if needed by an external scheme.
     */
    function hashLeafDouble(bytes memory data) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(keccak256(data)));
    }
}
