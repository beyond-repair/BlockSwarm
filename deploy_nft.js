```javascript
const hre = require("hardhat");

async function main() {
    const GovernanceNFT = await hre.ethers.getContractFactory("GovernanceNFT");
    const nft = await GovernanceNFT.deploy();
    await nft.deployed();
    console.log("GovernanceNFT deployed to:", nft.address);
}

main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
});
```