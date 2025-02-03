```solidity
pragma solidity ^0.8.20;

contract AIExecutor {
    address public dao;
    address public aiAgent;

    constructor(address _dao) {
        dao = _dao;
        aiAgent = msg.sender;
    }

    function executeProposal(uint256 proposalId, address target, bytes memory data) external {
        require(msg.sender == aiAgent, "Unauthorized");
        (bool success, ) = target.call(data);
        require(success, "Execution failed");
    }
}
```