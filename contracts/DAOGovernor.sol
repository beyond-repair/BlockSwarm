// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "./GovernanceNFT.sol";
import "./RevertTokenLayer.sol";
import "./OrchestrationEngine.sol";

/**
 * @title DAOGovernor
 * @notice Chain-1 governance: proposals, SBT voting, execution under EXECUTOR_ROLE.
 *
 * B2b-1: each address that holds a soulbound token may cast at most one vote
 * per proposal (`hasVoted[proposalId][voter]`).
 */
contract DAOGovernor is UUPSUpgradeable, AccessControlUpgradeable {
    bytes32 public constant PROPOSER_ROLE = keccak256("PROPOSER_ROLE");
    bytes32 public constant EXECUTOR_ROLE = keccak256("EXECUTOR_ROLE");

    GovernanceNFT public sbtContract;
    RevertTokenLayer public revertLayer;
    OrchestrationEngine public orchestrator;

    struct Proposal {
        address proposer;
        bytes32 contentCID;
        bytes32 advisoryHash;
        uint256 voteStart;
        uint256 voteEnd;
        uint256 forVotes;
        uint256 againstVotes;
        bool executed;
        uint256 revertTokenId;
    }

    mapping(uint256 => Proposal) public proposals;
    uint256 public proposalCount;

    /// @notice proposalId => voter => already cast (one vote per SBT holder per proposal)
    mapping(uint256 => mapping(address => bool)) public hasVoted;

    event ProposalCreated(
        uint256 indexed proposalId,
        address proposer,
        bytes32 contentCID,
        bytes32 advisoryHash
    );
    event VoteCast(address indexed voter, uint256 indexed proposalId, bool support);
    event ProposalExecuted(uint256 indexed proposalId, uint256 revertTokenId);

    constructor() {
        _disableInitializers();
    }

    function initialize(
        address sbtContract_,
        address revertLayer_,
        address orchestrator_,
        address governance
    ) public initializer {
        __UUPSUpgradeable_init();
        __AccessControl_init();

        sbtContract = GovernanceNFT(sbtContract_);
        revertLayer = RevertTokenLayer(revertLayer_);
        orchestrator = OrchestrationEngine(orchestrator_);

        _grantRole(DEFAULT_ADMIN_ROLE, governance);
        _grantRole(PROPOSER_ROLE, governance);
        _grantRole(EXECUTOR_ROLE, governance);
    }

    /**
     * @notice Create proposal from chain-3 advisory data (Invariant 4.2: AI does not execute).
     */
    function propose(bytes32 contentCID, bytes32 advisoryHash)
        external
        onlyRole(PROPOSER_ROLE)
        returns (uint256 proposalId)
    {
        proposalId = ++proposalCount;

        proposals[proposalId] = Proposal({
            proposer: msg.sender,
            contentCID: contentCID,
            advisoryHash: advisoryHash,
            voteStart: block.timestamp,
            voteEnd: block.timestamp + 7 days,
            forVotes: 0,
            againstVotes: 0,
            executed: false,
            revertTokenId: 0
        });

        emit ProposalCreated(proposalId, msg.sender, contentCID, advisoryHash);
    }

    /**
     * @notice Cast one vote with SBT + NFC proof (Invariants 6.1, 6.2).
     * @dev B2b-1: reverts if `msg.sender` already voted on this proposal.
     *      Weight is binary (1) per soulbound holder — not stake-weighted.
     */
    function castVote(uint256 proposalId, bool support, bytes calldata nfcProof) external {
        Proposal storage proposal = proposals[proposalId];
        require(proposal.voteStart != 0, "Unknown proposal");
        require(
            block.timestamp >= proposal.voteStart && block.timestamp <= proposal.voteEnd,
            "Voting period inactive"
        );
        require(!hasVoted[proposalId][msg.sender], "Already voted");
        require(sbtContract.verifyNFCSignature(msg.sender, nfcProof), "Invalid NFC proof");

        uint256 tokenId = sbtContract.tokenOfOwnerByIndex(msg.sender, 0);
        require(sbtContract.ownerOf(tokenId) == msg.sender, "Must hold active SBT");

        hasVoted[proposalId][msg.sender] = true;

        if (support) {
            proposal.forVotes += 1;
        } else {
            proposal.againstVotes += 1;
        }

        emit VoteCast(msg.sender, proposalId, support);
    }

    /**
     * @notice Execute approved proposal (Chain-1 EXECUTOR_ROLE only).
     */
    function executeProposal(uint256 proposalId) external onlyRole(EXECUTOR_ROLE) {
        Proposal storage proposal = proposals[proposalId];
        require(block.timestamp > proposal.voteEnd, "Voting still active");
        require(proposal.forVotes > proposal.againstVotes, "Proposal rejected");
        require(!proposal.executed, "Already executed");

        uint256 revertTokenId = orchestrator.authorizeProposal(
            proposalId,
            proposal.advisoryHash,
            abi.encodePacked(block.timestamp)
        );

        proposal.revertTokenId = revertTokenId;
        proposal.executed = true;

        emit ProposalExecuted(proposalId, revertTokenId);
    }

    function _authorizeUpgrade(address) internal override onlyRole(DEFAULT_ADMIN_ROLE) {}
}
