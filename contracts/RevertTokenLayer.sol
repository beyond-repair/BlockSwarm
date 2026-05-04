// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

contract RevertTokenLayer is UUPSUpgradeable, AccessControlUpgradeable {
    using ECDSA for bytes32;

    bytes32 public constant GOVERNANCE_ROLE = keccak256("GOVERNANCE_ROLE");
    bytes32 public constant ORCHESTRATOR_ROLE = keccak256("ORCHESTRATOR_ROLE");

    struct RevertToken {
        bytes32 preStateRoot;
        bytes32 postStateRoot;
        bytes32 triggerProof;        // EIP-712 signed receipt from OrchestrationEngine
        bytes32 causalDAGHash;
        bytes32 inverseActionHash;   // keccak256 of inverse() or compensation() calldata
        uint256 timestamp;
        address authorizedBy;
        uint256 proposalId;
    }

    mapping(uint256 => RevertToken) public revertTokens;
    mapping(bytes32 => bool) public usedCausalHashes;
    uint256 public tokenCounter;

    event RevertTokenMinted(uint256 indexed tokenId, bytes32 causalDAGHash, uint256 proposalId);
    event RollbackExecuted(uint256 indexed tokenId, bytes32 restoredToRoot, address executedBy);

    constructor() {
        _disableInitializers();
    }

    function initialize(address _governance) public initializer {
        __UUPSUpgradeable_init();
        __AccessControl_init();
        _grantRole(DEFAULT_ADMIN_ROLE, _governance);
        _grantRole(GOVERNANCE_ROLE, _governance);
        _grantRole(ORCHESTRATOR_ROLE, _governance);
    }

    /**
     * @notice Mint RevertToken on authorized execution (Enforces Invariants 3.1 & 3.2)
     */
    function mintRevertToken(
        bytes32 preStateRoot,
        bytes32 postStateRoot,
        bytes32 triggerProof,
        bytes32 causalDAGHash,
        bytes32 inverseActionHash,
        uint256 proposalId
    ) external onlyRole(ORCHESTRATOR_ROLE) returns (uint256) {
        require(!usedCausalHashes[causalDAGHash], "DAG hash already used");
        require(causalDAGHash != bytes32(0), "Invalid causal hash");

        uint256 tokenId = ++tokenCounter;

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
        return tokenId;
    }

    /**
     * @notice Execute monotonic rollback (Invariant 3.2)
     */
    function requestRollback(uint256 tokenId, bytes calldata inverseCalldata) 
        external onlyRole(GOVERNANCE_ROLE) 
    {
        RevertToken storage rt = revertTokens[tokenId];
        require(rt.timestamp != 0, "RevertToken does not exist");

        // Execute inverse or compensation action
        (bool success, ) = address(this).call(inverseCalldata);
        require(success, "Inverse/compensation failed");

        emit RollbackExecuted(tokenId, rt.preStateRoot, msg.sender);
    }

    function getRevertToken(uint256 tokenId) external view returns (RevertToken memory) {
        return revertTokens[tokenId];
    }

    function _authorizeUpgrade(address) internal override onlyRole(DEFAULT_ADMIN_ROLE) {}
}
