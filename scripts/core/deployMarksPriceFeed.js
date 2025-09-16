const { deployContract, contractAt, sendTxn, writeTmpAddresses } = require("../shared/helpers")
const { expandDecimals } = require("../../test/shared/utilities")

const network = (process.env.HARDHAT_NETWORK || 'mainnet');

// Define currency identifiers - using simple addresses as identifiers
const CURRENCY_IDENTIFIERS = {
  NGN: "0x0000000000000000000000000000000000000001",
  ARS: "0x0000000000000000000000000000000000000002", 
  PKR: "0x0000000000000000000000000000000000000003",
  GHS: "0x0000000000000000000000000000000000000004",
  COP: "0x0000000000000000000000000000000000000008",
}

// Price bounds configuration (in 8 decimals like Chainlink)
// Example: 1500 NGN = 1500 * 10^8
const PRICE_BOUNDS = {
  NGN: { min: expandDecimals(100, 8), max: expandDecimals(10000, 8) },     // 100-10,000
  ARS: { min: expandDecimals(100, 8), max: expandDecimals(10000, 8) },      // 100-10,000
  PKR: { min: expandDecimals(100, 8), max: expandDecimals(1000, 8) },      // 100-1,000
  GHS: { min: expandDecimals(5, 8), max: expandDecimals(100, 8) },         // 1-100
  COP: { min: expandDecimals(2000, 8), max: expandDecimals(10000, 8) },    // 2000-10,000
}

async function main() {
  console.log("Deploying MarksPriceFeed...")
  console.log("Network:", network)
  
  // Deploy MarksPriceFeed
  const marksPriceFeed = await deployContract("MarksPriceFeed", [])
  console.log("MarksPriceFeed deployed at:", marksPriceFeed.address)
  
  // Set the price updater address
  // TODO: Replace with your actual updater address (the wallet that will push prices from marks-server)
  const priceUpdaterAddress = "0xBaB0D0892Bf8563B731f8e8970fE856ce9308292" // CHANGE THIS
  
  if (priceUpdaterAddress === "0x0000000000000000000000000000000000000000") {
    console.warn("\n⚠️  WARNING: You need to set a valid priceUpdaterAddress in this script!")
    console.warn("This should be the wallet address that your marks-server will use to update prices.\n")
  } else {
    await sendTxn(
      marksPriceFeed.setPriceUpdater(priceUpdaterAddress),
      "marksPriceFeed.setPriceUpdater"
    )
  }
  
  // Set price bounds for each currency
  console.log("\nSetting price bounds for currencies...")
  for (const [symbol, address] of Object.entries(CURRENCY_IDENTIFIERS)) {
    const bounds = PRICE_BOUNDS[symbol]
    if (bounds) {
      await sendTxn(
        marksPriceFeed.setPriceBounds(address, bounds.min, bounds.max),
        `marksPriceFeed.setPriceBounds(${symbol})`
      )
      console.log(`  ✓ ${symbol}: ${bounds.min.div(expandDecimals(1, 8)).toString()}-${bounds.max.div(expandDecimals(1, 8)).toString()}`)
    }
  }
  
  // Optional: Adjust staleness threshold if needed (default is 5 minutes)
  // await sendTxn(marksPriceFeed.setMaxPriceAge(10 * 60), "marksPriceFeed.setMaxPriceAge") // 10 minutes
  
  // Optional: Adjust max price change if needed (default is 10%)
  // await sendTxn(marksPriceFeed.setMaxPriceChange(2000), "marksPriceFeed.setMaxPriceChange") // 20%
  
  // Write addresses to temporary file for reference
  writeTmpAddresses({
    marksPriceFeed: marksPriceFeed.address,
    currencyIdentifiers: CURRENCY_IDENTIFIERS
  })
  
  console.log("\n✅ Deployment complete!")
  console.log("\nAddresses:")
  console.log("  MarksPriceFeed:", marksPriceFeed.address)
  console.log("\nCurrency Identifiers:")
  for (const [symbol, address] of Object.entries(CURRENCY_IDENTIFIERS)) {
    console.log(`  ${symbol}: ${address}`)
  }
  
  console.log("\n📝 Next steps:")
  console.log("1. Update the priceUpdaterAddress in this script with your marks-server wallet")
  console.log("2. Fund the updater wallet with ETH for gas")
  console.log("3. Configure marks-server to push prices to:", marksPriceFeed.address)
  console.log("4. Deploy and configure VaultPriceFeed to use this MarksPriceFeed")
}

main()
  .then(() => process.exit(0))
  .catch(error => {
    console.error(error)
    process.exit(1)
  })