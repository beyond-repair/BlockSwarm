// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";

/**
 * @title RevertTokenLayer
 * @notice Chain-1 reversibility tokens: mint on authorization, rollback under governance.
 *
 * B2 inverse binding: `keccak256(inverseCalldata)` must equal the precommitted
 * `inverseActionHash` before any self-call.
 */
contract RevertTokenLayer is UUPSUpgradeable, AccessControlUpgradeable {
    // -------------------------------------------------------------------------
    // Roles
    // -------------------------------------------------------------------------

    bytes32 public constant GOVERNANCE_ROLE = keccak256("GOVERNANCE_ROLE");
    bytes32 public constant ORCHESTRATOR_ROLE = keccak256("ORCHESTRATOR_ROLE");

    // -------------------------------------------------------------------------
    // Types & storage
    // -------------------------------------------------------------------------

    struct RevertToken {
        bytes32 preStateRoot;
        bytes32 postStateRoot;
        bytes32 triggerProof; // OrchestrationEngine authorization receipt
        bytes32 causalDAGHash;
        bytes32 inverseActionHash; // keccak256(inverse/compensation calldata)
        uint256 timestamp;
        address authorizedBy;
        uint256 proposalId;
    }

    mapping(uint256 => RevertToken) public revertTokens;
    mapping(bytes32 => bool) public usedCausalHashes;

    uint256 public tokenCounter;

    // -------------------------------------------------------------------------
    // Events
    // -------------------------------------------------------------------------

    event RevertTokenMinted(
        uint256 indexed tokenId,
        bytes32 causalDAGHash,
        uint256 proposalId
    );
    event RollbackExecuted(
        uint256 indexed tokenId,
        bytes32 restoredToRoot,
        address executedBy
    );

    // -------------------------------------------------------------------------
    // Lifecycle
    // -------------------------------------------------------------------------

    constructor() {
        _disableInitializers();
    }

    function initialize(address governance) public initializer {
        __UUPSUpgradeable_init();
        __AccessControl_init();

        _grantRole(DEFAULT_ADMIN_ROLE, governance);
        _grantRole(GOVERNANCE_ROLE, governance);
        _grantRole(ORCHESTRATOR_ROLE, governance);
    }

    // -------------------------------------------------------------------------
    // Mint (orchestrator)
    // -------------------------------------------------------------------------

    /**
     * @notice Mint a revert token when a proposal is authorized (invariants 3.1 / 3.2).
     */
    function mintRevertToken(
        bytes32 preStateRoot,
        bytes32 postStateRoot,
        bytes32 triggerProof,
        bytes32 causalDAGHash,
        bytes32 inverseActionHash,
        uint256 proposalId
    ) external onlyRole(ORCHESTRATOR_ROLE) returns (uint256 tokenId) {
        require(causalDAGHash != bytes32(0), "Invalid causal hash");
        require(!usedCausalHashes[causalDAGHash], "DAG hash already used");

        tokenId = ++tokenCounter;

        revertTokens[tokenId] = RevertToken({
            preStateRoot: preStateRoot,
            postStateRoot: postStateRoot,
            triggerProof: triggerProof,
            causalDAGHash: causalDAGHash,
            inverseActionHash: inverseActionHash,
            timestamp: block.timestamp,
            authorizedBy: msg.sender,
            proposalId: proposalId
        });

        usedCausalHashes[causalDAGHash] = true;

        emit RevertTokenMinted(tokenId, causalDAGHash, proposalId);
    }

    // -------------------------------------------------------------------------
    // Rollback (governance)
    // -------------------------------------------------------------------------

    /**
     * @notice Execute inverse/compensation calldata for a minted token.
     * @dev Hash binding is checked before the self-call (B2).
     */
    function requestRollback(uint256 tokenId, bytes calldata inverseCalldata)
        external
        onlyRole(GOVERNANCE_ROLE)
    {
        RevertToken storage token = _requireExistingToken(tokenId);
        _requireMatchingInverseCalldata(token, inverseCalldata);
        _executeInverseCalldata(inverseCalldata);

        emit RollbackExecuted(tokenId, token.preStateRoot, msg.sender);
    }

    function getRevertToken(uint256 tokenId) external view returns (RevertToken memory) {
        return revertTokens[tokenId];
    }

    // -------------------------------------------------------------------------
    // Internal helpers (behavior-preserving)
    // -------------------------------------------------------------------------

    function _requireExistingToken(uint256 tokenId)
        internal
        view
        returns (RevertToken storage token)
    {
        token = revertTokens[tokenId];
        require(token.timestamp != 0, "RevertToken does not exist");
    }

    function _requireMatchingInverseCalldata(
        RevertToken storage token,
        bytes calldata inverseCalldata
    ) internal view {
        require(
            keccak256(inverseCalldata) == token.inverseActionHash,
            "Inverse calldata hash mismatch"
        );
    }

    function _executeInverseCalldata(bytes calldata inverseCalldata) internal {
        (bool success, ) = address(this).call(inverseCalldata);
        require(success, "Inverse/compensation failed");
    }

    function _authorizeUpgrade(address) internal override onlyRole(DEFAULT_ADMIN_ROLE) {}
}
