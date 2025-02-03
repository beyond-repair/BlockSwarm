```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

contract GovernanceNFT is ERC721 {
    address public dao;
    uint256 public tokenCount;
    mapping(bytes32 => bool) public nfcUsed;
    mapping(address => bytes32) public nfcRegistry;

    constructor() ERC721("BlockSwarmID", "BSID") {
        dao = msg.sender;
    }

    function mintWithNFC(address to, bytes32 nfcHash) external {
        require(!nfcUsed[nfcHash], "NFC already registered");
        nfcUsed[nfcHash] = true;
        nfcRegistry[to] = nfcHash;
        _safeMint(to, tokenCount++);
    }

    function _beforeTokenTransfer(address from, address to, uint256) internal pure override {
        require(from == address(0) || to == address(0), "Soulbound: Non-transferable");
    }
}