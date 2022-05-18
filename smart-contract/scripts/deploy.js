const hre = require("hardhat");

async function main() {
  const Exchange = await hre.ethers.getContractFactory("Exchange");
  const exchange = await Exchange.deploy('0x315d812Eb76Fac89E88B2c5a6bEAeFFbC1fE4652');

  await exchange.deployed();

  console.log("Exchange deployed to:", exchange.address);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
