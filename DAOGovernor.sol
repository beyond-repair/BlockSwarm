```solidity
pragma solidity ^0.8.20;

import "./GovernanceNFT.sol";
import "./interfaces/INFCOracle.sol";

contract DAOGovernor {
    using ECDSA for bytes32;

    GovernanceNFT public nftContract;
    INFCOracle public nfcOracle;
    
    struct Proposal {
        address target;
        bytes calldata;
        uint256 voteStart;
        uint256 voteEnd;
        uint256 forVotes;
        uint256 againstVotes;
        bool executed;
        uint256 timelockEnd;
    }
    
    uint256 public proposalCount;
    mapping(uint256 => Proposal) public proposals;
    mapping(uint256 => mapping(address => bool)) public hasVoted;
    uint256 public constant TIMELOCK_DURATION = 2 days;

    event ProposalCreated(uint256 proposalId, address proposer);
    event VoteCast(address indexed voter, uint256 proposalId, bool support);

    constructor(address _nft, address _oracle) {
        nftContract = GovernanceNFT(_nft);
        nfcOracle = INFCOracle(_oracle);
    }

    function propose(address target, bytes calldata data) external returns (uint256) {
        uint256 proposalId = proposalCount++;
        proposals[proposalId] = Proposal({
            target: target,
            calldata: data,
            voteStart: block.timestamp + 1 days,
            voteEnd: block.timestamp + 7 days,
            forVotes: 0,
            againstVotes: 0,
            executed: false,
            timelockEnd: block.timestamp + 7 days + TIMELOCK_DURATION
        });
        
        emit ProposalCreated(proposalId, msg.sender);
        return proposalId;
    }

    function castVote(uint256 proposalId, bool support, bytes calldata nfcProof) external {
        Proposal storage proposal = proposals[proposalId];
        require(block.timestamp >= proposal.voteStart, "Voting not started");
        require(block.timestamp <= proposal.voteEnd, "Voting ended");
        require(nfcOracle.verifyProof(msg.sender, nfcProof), "Invalid NFC proof");
        require(!hasVoted[proposalId][msg.sender], "Already voted");

        nftContract.lockForVote(proposalId, proposal.voteEnd - block.timestamp);
        hasVoted[proposalId][msg.sender] = true;

        if(support) proposal.forVotes++;
        else proposal.againstVotes++;

        emit VoteCast(msg.sender, proposalId, support);
    }

    function executeProposal(uint256 proposalId) external {
        Proposal storage proposal = proposals[proposalId];
        require(block.timestamp > proposal.voteEnd, "Voting ongoing");
        require(block.timestamp >= proposal.timelockEnd, "Timelock active");
        require(proposal.forVotes > proposal.againstVotes, "Proposal rejected");
        require(!proposal.executed, "Already executed");
        
        (bool success, ) = proposal.target.call(proposal.calldata);
        require(success, "Execution failed");
        proposal.executed = true;
    }
}
```