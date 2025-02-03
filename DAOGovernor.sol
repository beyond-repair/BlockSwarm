```solidity
pragma solidity ^0.8.20;

import "./GovernanceNFT.sol";

contract DAOGovernor {
    GovernanceNFT public nftContract;
    mapping(uint256 => Proposal) public proposals;
    uint256 public proposalCount;

    struct Proposal {
        uint256 nfcLockDeadline;
        uint256 voteEnd;
        uint256 forVotes;
        uint256 againstVotes;
        bool executed;
    }

    constructor(address _nft) {
        nftContract = GovernanceNFT(_nft);
    }

    function propose() external returns (uint256) {
        uint256 proposalId = proposalCount++;
        proposals[proposalId] = Proposal({
            nfcLockDeadline: block.timestamp + 3 days,
            voteEnd: block.timestamp + 7 days,
            forVotes: 0,
            againstVotes: 0,
            executed: false
        });
        return proposalId;
    }

    function castVote(uint256 proposalId, bool support) external {
        require(nftContract.balanceOf(msg.sender) > 0, "No voting rights");
        Proposal storage proposal = proposals[proposalId];
        require(block.timestamp < proposal.voteEnd, "Voting ended");

        if (support) proposal.forVotes++;
        else proposal.againstVotes++;
    }
}
```