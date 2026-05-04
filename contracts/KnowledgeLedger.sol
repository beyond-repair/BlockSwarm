// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";

contract KnowledgeLedger is UUPSUpgradeable, AccessControlUpgradeable {
    bytes32 public constant ORACLE_ROLE = keccak256("ORACLE_ROLE");
    bytes32 public constant EXECUTOR_ROLE = keccak256("EXECUTOR_ROLE");

    struct LedgerEntry {
        bytes32 contentCID;        // IPFS / Arweave hash
        bytes32 stateRoot;
        uint256 timestamp;
        address recordedBy;
        uint256 proposalId;
        bytes32 causalDAGHash;
    }

    mapping(bytes32 => LedgerEntry) public entries;
    mapping(uint256 => bytes32[]) public proposalHistory; // proposalId → list of CIDs

    uint256 public entryCount;

    event KnowledgeRecorded(bytes32 indexed cid, bytes32 stateRoot, uint256 proposalId);
    event StateRootUpdated(uint256 indexed proposalId, bytes32 newStateRoot);

    constructor() {
        _disableInitializers();
    }

    function initialize(address _governance) public initializer {
        __UUPSUpgradeable_init();
        __AccessControl_init();
        _grantRole(DEFAULT_ADMIN_ROLE, _governance);
        _grantRole(ORACLE_ROLE, _governance);
        _grantRole(EXECUTOR_ROLE, _governance);
    }

    /**
     * @notice Record minimal on-chain knowledge (Invariant 7.x - Provenance)
     */
    function recordEntry(
        bytes32 contentCID,
        bytes32 stateRoot,
        uint256 proposalId,
        bytes32 causalDAGHash
    ) external onlyRole(ORACLE_ROLE) {
        require(entries[contentCID].timestamp == 0, "Entry already exists");

        entries[contentCID] = LedgerEntry({
            contentCID: contentCID,
            stateRoot: stateRoot,
            timestamp: block.timestamp,
            recordedBy: msg.sender,
            proposalId: proposalId,
            causalDAGHash: causalDAGHash
        });

        proposalHistory[proposalId].push(contentCID);
        entryCount++;

        emit KnowledgeRecorded(contentCID, stateRoot, proposalId);
    }

    /**
     * @notice Update state root after execution or rollback
     */
    function updateStateRoot(uint256 proposalId, bytes32 newStateRoot) 
        external onlyRole(EXECUTOR_ROLE) 
    {
        require(proposalHistory[proposalId].length > 0, "No history for proposal");

        bytes32 latestCID = proposalHistory[proposalId][proposalHistory[proposalId].length - 1];
        entries[latestCID].stateRoot = newStateRoot;

        emit StateRootUpdated(proposalId, newStateRoot);
    }

    function getEntry(bytes32 contentCID) external view returns (LedgerEntry memory) {
        return entries[contentCID];
    }

    function getProposalHistory(uint256 proposalId) external view returns (bytes32[] memory) {
        return proposalHistory[proposalId];
    }

    function _authorizeUpgrade(address) internal override onlyRole(DEFAULT_ADMIN_ROLE) {}
}
