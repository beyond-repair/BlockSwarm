// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "./GovernanceNFT.sol";
import "./RevertTokenLayer.sol";
import "./OrchestrationEngine.sol";

contract DAOGovernor is UUPSUpgradeable, AccessControlUpgradeable {
    bytes32 public constant PROPOSER_ROLE = keccak256("PROPOSER_ROLE");
    bytes32 public constant EXECUTOR_ROLE = keccak256("EXECUTOR_ROLE");

    GovernanceNFT public sbtContract;
    RevertTokenLayer public revertLayer;
    OrchestrationEngine public orchestrator;

    struct Proposal {
        address proposer;
        bytes32 contentCID;      // IPFS hash of proposal details
        bytes32 advisoryHash;    // From chain3 Digital Double
        uint256 voteStart;
        uint256 voteEnd;
        uint256 forVotes;
        uint256 againstVotes;
        bool executed;
        uint256 revertTokenId;
    }

    mapping(uint256 => Proposal) public proposals;
    uint256 public proposalCount;

    event ProposalCreated(uint256 indexed proposalId, address proposer, bytes32 contentCID, bytes32 advisoryHash);
    event VoteCast(address indexed voter, uint256 indexed proposalId, bool support);
    event ProposalExecuted(uint256 indexed proposalId, uint256 revertTokenId);

    constructor() {
        _disableInitializers();
    }

    function initialize(
        address _sbtContract,
        address _revertLayer,
        address _orchestrator,
        address _governance
    ) public initializer {
        __UUPSUpgradeable_init();
        __AccessControl_init();

        sbtContract = GovernanceNFT(_sbtContract);
        revertLayer = RevertTokenLayer(_revertLayer);
        orchestrator = OrchestrationEngine(_orchestrator);

        _grantRole(DEFAULT_ADMIN_ROLE, _governance);
        _grantRole(PROPOSER_ROLE, _governance);
        _grantRole(EXECUTOR_ROLE, _governance);
    }

    /**
     * @notice Create proposal from chain3 advisory (Invariant 4.2)
     */
    function propose(bytes32 contentCID, bytes32 advisoryHash) 
        external onlyRole(PROPOSER_ROLE) returns (uint256) 
    {
        uint256 proposalId = ++proposalCount;

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
        return proposalId;
    }

    /**
     * @notice Cast vote with SBT + NFC proof (Invariant 6.1)
     */
    function castVote(uint256 proposalId, bool support, bytes calldata nfcProof) external {
        Proposal storage p = proposals[proposalId];
        require(block.timestamp >= p.voteStart && block.timestamp <= p.voteEnd, "Voting period inactive");
        require(sbtContract.verifyNFCSignature(msg.sender, nfcProof), "Invalid NFC proof");

        uint256 tokenId = sbtContract.tokenOfOwnerByIndex(msg.sender, 0);
        require(sbtContract.ownerOf(tokenId) == msg.sender, "Must hold active SBT");

        if (support) p.forVotes++;
        else p.againstVotes++;

        emit VoteCast(msg.sender, proposalId, support);
    }

    /**
     * @notice Execute approved proposal (chain1 authority only)
     */
    function executeProposal(uint256 proposalId) external onlyRole(EXECUTOR_ROLE) {
        Proposal storage p = proposals[proposalId];
        require(block.timestamp > p.voteEnd, "Voting still active");
        require(p.forVotes > p.againstVotes, "Proposal rejected");
        require(!p.executed, "Already executed");

        uint256 rtId = orchestrator.authorizeProposal(proposalId, p.advisoryHash, abi.encodePacked(block.timestamp));

        p.revertTokenId = rtId;
        p.executed = true;

        emit ProposalExecuted(proposalId, rtId);
    }

    function _authorizeUpgrade(address) internal override onlyRole(DEFAULT_ADMIN_ROLE) {}
}
