// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "./RevertTokenLayer.sol";

contract OrchestrationEngine is UUPSUpgradeable, AccessControlUpgradeable {
    using ECDSA for bytes32;

    bytes32 public constant EXECUTOR_ROLE = keccak256("EXECUTOR_ROLE");
    bytes32 public constant ADVISOR_ROLE = keccak256("ADVISOR_ROLE"); // chain3 advisory origin

    RevertTokenLayer public revertLayer;

    mapping(uint256 => bool) public authorizedProposals;
    mapping(bytes32 => bool) public usedAdvisoryHashes;

    event AdvisoryReceived(uint256 indexed proposalId, bytes32 advisoryHash, address origin);
    event ProposalAuthorized(uint256 indexed proposalId, uint256 revertTokenId);
    event ExecutionPayloadSigned(bytes32 indexed payloadHash, address executor);

    constructor() {
        _disableInitializers();
    }

    function initialize(address _revertLayer, address _governance) public initializer {
        __UUPSUpgradeable_init();
        __AccessControl_init();

        revertLayer = RevertTokenLayer(_revertLayer);

        _grantRole(DEFAULT_ADMIN_ROLE, _governance);
        _grantRole(EXECUTOR_ROLE, _governance);
        _grantRole(ADVISOR_ROLE, _governance); // chain3 can propose advisory
    }

    /**
     * @notice Receive Advisory DAG Proposal from chain3 (Invariant 4.2 + 5.1)
     */
    function receiveAdvisory(
        uint256 proposalId,
        bytes32 advisoryHash,
        bytes calldata signature
    ) external onlyRole(ADVISOR_ROLE) {
        require(!usedAdvisoryHashes[advisoryHash], "Advisory hash already used");

        bytes32 digest = keccak256(abi.encode(proposalId, advisoryHash, block.timestamp));
        address signer = digest.recover(signature);
        require(hasRole(ADVISOR_ROLE, signer), "Invalid advisory signature");

        usedAdvisoryHashes[advisoryHash] = true;

        emit AdvisoryReceived(proposalId, advisoryHash, signer);
    }

    /**
     * @notice Authorize proposal for execution (chain1 only) — Enforces Invariant 4.1
     */
    function authorizeProposal(
        uint256 proposalId,
        bytes32 advisoryHash,
        bytes calldata executorSignature
    ) external onlyRole(EXECUTOR_ROLE) returns (uint256) {
        require(!authorizedProposals[proposalId], "Proposal already authorized");

        // Verify executor signature
        bytes32 digest = keccak256(abi.encode(proposalId, advisoryHash));
        require(digest.recover(executorSignature) == msg.sender, "Invalid executor signature");

        authorizedProposals[proposalId] = true;

        // Mint RevertToken skeleton (pre/post roots filled post-execution)
        uint256 rtId = revertLayer.mintRevertToken(
            bytes32(0),                    // preStateRoot (filled on execution)
            bytes32(0),                    // postStateRoot
            keccak256(abi.encodePacked("AUTH", proposalId)),
            keccak256(abi.encodePacked(block.timestamp, proposalId, advisoryHash)),
            bytes32(0),                    // inverseActionHash registered later
            proposalId
        );

        emit ProposalAuthorized(proposalId, rtId);
        return rtId;
    }

    function _authorizeUpgrade(address) internal override onlyRole(DEFAULT_ADMIN_ROLE) {}
}
