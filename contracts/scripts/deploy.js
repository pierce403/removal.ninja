const hre = require("hardhat");

async function main() {
  console.log("Deploying RemovalNinja contract...");

  const RemovalNinja = await hre.ethers.getContractFactory("RemovalNinja");
  const removalNinja = await RemovalNinja.deploy();

  await removalNinja.waitForDeployment();

  const address = await removalNinja.getAddress();
  console.log(`RemovalNinja deployed to: ${address}`);

  // Save deployment info
  const fs = require('fs');
  const deploymentInfo = {
    contractAddress: address,
    deploymentTime: new Date().toISOString(),
    network: hre.network.name
  };

  fs.writeFileSync('../server/contract-address.json', JSON.stringify(deploymentInfo, null, 2));
  console.log("Contract address saved to server/contract-address.json");
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });