// scripts/core/deployPriceFeedAdapters.js
const { deployContract, contractAt, sendTxn, writeTmpAddresses, readTmpAddresses } = require("../shared/helpers")

const network = (process.env.HARDHAT_NETWORK || 'mainnet');

// MarksPriceFeed address on Arbitrum Sepolia
const MARKS_PRICE_FEED = "0x93ffbf0e0c4b5662b4564b38654a20f2565fe30a";

async function main() {
  console.log("Deploying Price Feed Adapters for Marks Exchange...");
  console.log("Using MarksPriceFeed at:", MARKS_PRICE_FEED);
  
  // Verify MarksPriceFeed is accessible
  const marksPriceFeed = await contractAt("MarksPriceFeed", MARKS_PRICE_FEED);
  console.log("\nVerifying MarksPriceFeed connection...");
  
  // Test getting NGN price
  const NGN_ADDRESS = "0x0000000000000000000000000000000000000001";
  try {
    const ngnPrice = await marksPriceFeed.getPrice(NGN_ADDRESS);
    console.log("Current NGN price from MarksPriceFeed:", ngnPrice.toString());
    console.log("Price in human readable format:", (ngnPrice.toNumber() / 1e8).toFixed(2), "NGN/USDT");
  } catch (error) {
    console.log("Warning: Could not fetch NGN price. Continuing with deployment...");
  }
  
  // Deploy NGNPriceFeedAdapter
  console.log("\nDeploying NGNPriceFeedAdapter...");
  const ngnAdapter = await deployContract("NGNPriceFeedAdapter", [MARKS_PRICE_FEED]);
  console.log("NGNPriceFeedAdapter deployed at:", ngnAdapter.address);
  
  // Verify the adapter works
  console.log("\nVerifying adapter functionality...");
  const latestAnswer = await ngnAdapter.latestAnswer();
  const decimals = await ngnAdapter.decimals();
  const description = await ngnAdapter.description();
  
  console.log("  Latest Answer:", latestAnswer.toString());
  console.log("  Decimals:", decimals);
  console.log("  Description:", description);
  console.log("  Price in human readable:", (latestAnswer.toNumber() / 1e8).toFixed(2), "NGN/USDT");
  
  // Test Chainlink interface methods
  const latestRound = await ngnAdapter.latestRound();
  console.log("  Latest Round (block number):", latestRound.toString());
  
  const roundData = await ngnAdapter.latestRoundData();
  console.log("  Round Data - Round ID:", roundData.roundId.toString());
  console.log("  Round Data - Answer:", roundData.answer.toString());
  console.log("  Round Data - Updated At:", new Date(roundData.updatedAt.toNumber() * 1000).toISOString());
  
  // Save addresses
  const addresses = {
    marksPriceFeed: MARKS_PRICE_FEED,
    ngnPriceFeedAdapter: ngnAdapter.address,
    // Add other adapters as they're deployed
    // arsPriceFeedAdapter: arsAdapter.address,
    // pkrPriceFeedAdapter: pkrAdapter.address,
  };
  
  writeTmpAddresses(addresses);
  
  console.log("\n========================================");
  console.log("Price Feed Adapter Deployment Complete!");
  console.log("========================================");
  console.log("\nDeployed Addresses:");
  console.log("  MarksPriceFeed:", MARKS_PRICE_FEED);
  console.log("  NGNPriceFeedAdapter:", ngnAdapter.address);
  
  console.log("\nNext Steps:");
  console.log("1. Deploy modified Vault contract");
  console.log("2. Deploy VaultPriceFeed");
  console.log("3. Configure VaultPriceFeed to use this adapter for sNGN token");
  
  return addresses;
}

// Allow this script to be imported by other scripts
module.exports = { deployPriceFeedAdapters: main };

// Run the script if called directly
if (require.main === module) {
  main()
    .then(() => process.exit(0))
    .catch(error => {
      console.error(error)
      process.exit(1)
    })
}