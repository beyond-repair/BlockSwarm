```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

contract GovernanceNFT is ERC721 {
    using ECDSA for bytes32;

    struct VoteLock {
        uint256 proposalId;
        uint256 unlockTime;
    }

    uint256 public tokenCounter;
    mapping(bytes32 => bool) public usedNFCIds;
    mapping(address => VoteLock) public lockedTokens;
    mapping(address => bytes32) public nfcRegistry;
    mapping(address => uint256) public fraudCount;

    event FraudDetected(address indexed user, bytes32 nfcHash);

    constructor() ERC721("BlockSwarmID", "BSID") {}

    function mintWithNFC(address to, bytes32 nfcHash, bytes calldata sig) external {
        require(!usedNFCIds[nfcHash], "NFC already registered");
        require(verifyNFCSignature(nfcHash, sig), "Invalid NFC signature");
        
        usedNFCIds[nfcHash] = true;
        nfcRegistry[to] = nfcHash;
        _safeMint(to, tokenCounter++);
    }

    function verifyNFCSignature(bytes32 hash, bytes memory sig) public pure returns (bool) {
        return hash.recover(sig) == msg.sender;
    }

    function reportFraud(address user, bytes32 nfcHash) external {
        require(nfcRegistry[user] == nfcHash, "Invalid fraud report");
        fraudCount[user]++;
        emit FraudDetected(user, nfcHash);
    }

    function slashUser(address user) external {
        require(fraudCount[user] >= 3, "Insufficient fraud reports");
        _burn(tokenOfOwnerByIndex(user, 0));
    }
}
```