// scripts/core/deployStubTokens.js
const { deployContract, contractAt, sendTxn, writeTmpAddresses } = require("../shared/helpers")

const network = (process.env.HARDHAT_NETWORK || 'mainnet');

async function main() {
  console.log("Deploying stub tokens for Marks Exchange FX markets...");
  
  // Deploy sNGN - Synthetic Nigerian Naira
  const sNGN = await deployContract("sNGN", []);
  console.log("sNGN deployed at:", sNGN.address);
  
  // You can add more stub tokens here as needed:
  // const sARS = await deployContract("sARS", []);
  // const sPKR = await deployContract("sPKR", []);
  // const sGHS = await deployContract("sGHS", []);
  // const sCOP = await deployContract("sCOP", []);
  
  // Verify the token was deployed correctly
  const name = await sNGN.name();
  const symbol = await sNGN.symbol();
  const decimals = await sNGN.decimals();
  const totalSupply = await sNGN.totalSupply();
  
  console.log("\nsNGN Token Details:");
  console.log("  Name:", name);
  console.log("  Symbol:", symbol);
  console.log("  Decimals:", decimals);
  console.log("  Total Supply:", totalSupply.toString());
  
  // Save addresses for use in other deployment scripts
  writeTmpAddresses({
    sNGN: sNGN.address,
    // sARS: sARS.address,
    // sPKR: sPKR.address,
    // Add other tokens as deployed
  });
  
  console.log("\nStub token deployment complete!");
  console.log("\nIMPORTANT: These are stub tokens with no transfer functionality.");
  console.log("They serve only as market identifiers for the GMX system.");
  
  // Return the addresses for use in other scripts
  return {
    sNGN: sNGN.address,
    // Add other tokens as needed
  };
}

// Allow this script to be imported by other scripts
module.exports = { deployStubTokens: main };

// Run the script if called directly
if (require.main === module) {
  main()
    .then(() => process.exit(0))
    .catch(error => {
      console.error(error)
      process.exit(1)
    })
}