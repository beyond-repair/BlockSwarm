// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

contract GovernanceNFT is ERC721Upgradeable, UUPSUpgradeable, AccessControlUpgradeable {
    using ECDSA for bytes32;

    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant SLASHER_ROLE = keccak256("SLASHER_ROLE");

    uint256 public tokenCounter;

    mapping(bytes32 => bool) public usedNFCIds;
    mapping(address => bytes32) public nfcRegistry;
    mapping(address => uint256) public fraudCount;
    mapping(address => bytes32) public consentScopes;
    mapping(address => uint256) public tokenByOwner;

    event NFCMinted(address indexed to, bytes32 nfcHash, bytes32 consentScope);
    event FraudReported(address indexed user, bytes32 nfcHash);
    event UserSlashed(address indexed user, uint256 tokenId);

    constructor() {
        _disableInitializers();
    }

    function initialize(address _governance) public initializer {
        __ERC721_init("BlockSwarm Sovereign ID", "BSID");
        __UUPSUpgradeable_init();
        __AccessControl_init();

        _grantRole(DEFAULT_ADMIN_ROLE, _governance);
        _grantRole(MINTER_ROLE, _governance);
        _grantRole(SLASHER_ROLE, _governance);
    }

    /**
     * @notice Mint true Soulbound NFC SBT (Invariant 6.1)
     */
    function mintWithNFC(
        address to,
        bytes32 nfcHash,
        bytes calldata signature,
        bytes32 consentScope
    ) external onlyRole(MINTER_ROLE) {
        require(!usedNFCIds[nfcHash], "NFC already registered");
        require(verifyNFCSignature(nfcHash, signature), "Invalid NFC signature");

        usedNFCIds[nfcHash] = true;
        nfcRegistry[to] = nfcHash;
        consentScopes[to] = consentScope;

        uint256 tid = tokenCounter++;
        _safeMint(to, tid);
        tokenByOwner[to] = tid;
        emit NFCMinted(to, nfcHash, consentScope);
    }

    function verifyNFCSignature(bytes32 hash, bytes memory sig) public view returns (bool) {
        return hash.recover(sig) == msg.sender;
    }

    function verifyNFCSignature(address user, bytes memory sig) public view returns (bool) {
        bytes32 nfcHash = nfcRegistry[user];
        if (nfcHash == bytes32(0)) return false;
        return nfcHash.recover(sig) == user;
    }

    function tokenOfOwnerByIndex(address owner, uint256) external view returns (uint256) {
        return tokenByOwner[owner];
    }

    // === SOULBOUND ENFORCEMENT (Invariant 6.1) ===
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 /* tokenId */,
        uint256 /* batchSize */
    ) internal pure override {
        require(from == address(0) || to == address(0), "Soulbound: transfers prohibited");
    }

    function reportFraud(address user, bytes32 nfcHash) external {
        require(nfcRegistry[user] == nfcHash, "Invalid fraud report");
        fraudCount[user]++;
        emit FraudReported(user, nfcHash);

        if (fraudCount[user] >= 3) {
            _slashUser(user);
        }
    }

    function _slashUser(address user) internal {
        uint256 tokenId = tokenByOwner[user];
        _burn(tokenId);
        delete tokenByOwner[user];
        emit UserSlashed(user, tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721Upgradeable, AccessControlUpgradeable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function _authorizeUpgrade(address) internal override onlyRole(DEFAULT_ADMIN_ROLE) {}
}
