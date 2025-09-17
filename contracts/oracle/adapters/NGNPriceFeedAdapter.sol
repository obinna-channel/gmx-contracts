// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

interface IMarksPriceFeed {
    function getPrice(address _token) external view returns (uint256);
    function getLastUpdateTime(address _token) external view returns (uint256);
}

/**
 * @title NGNPriceFeedAdapter
 * @notice Adapts MarksPriceFeed prices for NGN to be compatible with Chainlink's IPriceFeed interface
 * @dev This adapter allows GMX's VaultPriceFeed to read NGN prices from MarksPriceFeed
 */
contract NGNPriceFeedAdapter {
    
    // The MarksPriceFeed contract
    IMarksPriceFeed public immutable marksPriceFeed;
    
    // NGN token address in MarksPriceFeed (using placeholder address)
    address public constant NGN_TOKEN = 0x0000000000000000000000000000000000000001;
    
    // Chainlink compatible interface variables
    uint8 public constant decimals = 8;
    string public constant description = "NGN / USD";
    uint256 public constant version = 1;
    
    // Access control
    address public gov;
    
    // Events
    event GovSet(address newGov);
    
    /**
     * @notice Constructor
     * @param _marksPriceFeed Address of the MarksPriceFeed contract
     */
    constructor(address _marksPriceFeed) public {
        require(_marksPriceFeed != address(0), "NGNPriceFeedAdapter: invalid price feed");
        marksPriceFeed = IMarksPriceFeed(_marksPriceFeed);
        gov = msg.sender;
    }
    
    /**
     * @notice Returns the latest price from MarksPriceFeed
     * @dev Main function that GMX VaultPriceFeed will call
     * @return price The latest price as int256 (8 decimals)
     */
    function latestAnswer() external view returns (int256) {
        uint256 price = marksPriceFeed.getPrice(NGN_TOKEN);
        require(price > 0, "NGNPriceFeedAdapter: invalid price");
        require(price <= uint256(type(int256).max), "NGNPriceFeedAdapter: price overflow");
        return int256(price);
    }
    
    /**
     * @notice Returns the latest round ID (using block number)
     * @dev GMX may call this for round-based price sampling
     * @return roundId The current block number as round ID
     */
    function latestRound() external view returns (uint80) {
        return uint80(block.number);
    }
    
    /**
     * @notice Returns the timestamp of the latest price update
     * @dev Uses the getLastUpdateTime from MarksPriceFeed
     * @return timestamp The timestamp of the last update
     */
    function latestTimestamp() external view returns (uint256) {
        return marksPriceFeed.getLastUpdateTime(NGN_TOKEN);
    }
    
    /**
     * @notice Gets the price data for a specific round
     * @dev For compatibility - returns current price for any round requested
     * @param _roundId The round ID (ignored, always returns latest)
     * @return roundId The requested round ID
     * @return answer The price at that round (always latest price)
     * @return startedAt The timestamp when round started (block timestamp)
     * @return updatedAt The timestamp when price was updated
     * @return answeredInRound The round ID in which the answer was computed
     */
    function getRoundData(uint80 _roundId) 
        external 
        view 
        returns (
            uint80 roundId,
            int256 answer,
            uint256 startedAt,
            uint256 updatedAt,
            uint80 answeredInRound
        ) 
    {
        uint256 price = marksPriceFeed.getPrice(NGN_TOKEN);
        require(price > 0, "NGNPriceFeedAdapter: invalid price");
        require(price <= uint256(type(int256).max), "NGNPriceFeedAdapter: price overflow");
        
        return (
            _roundId,
            int256(price),
            marksPriceFeed.getLastUpdateTime(NGN_TOKEN),
            marksPriceFeed.getLastUpdateTime(NGN_TOKEN),
            _roundId
        );
    }
    
    /**
     * @notice Returns the latest price and round data
     * @dev Combines latestAnswer and latestRound functionality
     * @return roundId The current block number as round ID  
     * @return answer The latest price as int256
     * @return startedAt The timestamp when round started
     * @return updatedAt The timestamp when price was updated
     * @return answeredInRound The round ID in which the answer was computed
     */
    function latestRoundData()
        external
        view
        returns (
            uint80 roundId,
            int256 answer,
            uint256 startedAt,
            uint256 updatedAt,
            uint80 answeredInRound
        )
    {
        uint256 price = marksPriceFeed.getPrice(NGN_TOKEN);
        require(price > 0, "NGNPriceFeedAdapter: invalid price");
        require(price <= uint256(type(int256).max), "NGNPriceFeedAdapter: price overflow");
        
        uint80 currentRound = uint80(block.number);
        uint256 timestamp = marksPriceFeed.getLastUpdateTime(NGN_TOKEN);
        
        return (
            currentRound,
            int256(price),
            timestamp,
            timestamp,
            currentRound
        );
    }
    
    /**
     * @notice Set new governance address
     * @dev Only callable by current governance
     * @param _gov New governance address
     */
    function setGov(address _gov) external {
        require(msg.sender == gov, "NGNPriceFeedAdapter: forbidden");
        require(_gov != address(0), "NGNPriceFeedAdapter: invalid gov");
        gov = _gov;
        emit GovSet(_gov);
    }
    
    /**
     * @notice Get the underlying MarksPriceFeed price directly
     * @dev Utility function for debugging/verification
     * @return price The current NGN price from MarksPriceFeed
     */
    function getUnderlyingPrice() external view returns (uint256) {
        return marksPriceFeed.getPrice(NGN_TOKEN);
    }
}