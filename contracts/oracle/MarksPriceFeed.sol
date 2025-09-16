// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "../libraries/math/SafeMath.sol";
import "../access/Governable.sol";

contract MarksPriceFeed is Governable {
    using SafeMath for uint256;

    // Price precision - using 8 decimals like Chainlink
    uint256 public constant PRICE_PRECISION = 10 ** 8;
    uint256 public constant BASIS_POINTS_DIVISOR = 10000;
    
    // Staleness and update parameters
    uint256 public maxPriceAge = 5 minutes; // 5 minute staleness threshold
    uint256 public maxPriceChangePerUpdate = 1000; // 10% = 1000 basis points
    uint256 public minTimeBetweenUpdates = 30 seconds; // Prevent spam
    
    // Price data structure
    struct PriceData {
        uint256 price;
        uint256 timestamp;
        uint256 minPrice;  // Minimum allowed price for this token
        uint256 maxPrice;  // Maximum allowed price for this token
    }
    
    // Mapping from token identifier to price data
    mapping(address => PriceData) public prices;
    
    // Authorized price updater
    address public priceUpdater;
    
    // Events
    event PriceUpdated(address indexed token, uint256 price, uint256 timestamp);
    event UpdaterSet(address indexed updater);
    event PriceBoundsSet(address indexed token, uint256 minPrice, uint256 maxPrice);
    event MaxPriceAgeUpdated(uint256 maxPriceAge);
    event MaxPriceChangeUpdated(uint256 maxPriceChange);
    
    modifier onlyUpdater() {
        require(msg.sender == priceUpdater, "MarksPriceFeed: forbidden");
        _;
    }
    
    constructor() public {
        // Gov is set to msg.sender in Governable constructor
    }
    
    // Admin functions
    
    function setPriceUpdater(address _updater) external onlyGov {
        require(_updater != address(0), "MarksPriceFeed: invalid updater");
        priceUpdater = _updater;
        emit UpdaterSet(_updater);
    }
    
    function setMaxPriceAge(uint256 _maxPriceAge) external onlyGov {
        require(_maxPriceAge > 0, "MarksPriceFeed: invalid max age");
        maxPriceAge = _maxPriceAge;
        emit MaxPriceAgeUpdated(_maxPriceAge);
    }
    
    function setMaxPriceChange(uint256 _maxPriceChange) external onlyGov {
        require(_maxPriceChange > 0 && _maxPriceChange <= 5000, "MarksPriceFeed: invalid max change");
        maxPriceChangePerUpdate = _maxPriceChange;
        emit MaxPriceChangeUpdated(_maxPriceChange);
    }
    
    function setPriceBounds(
        address _token,
        uint256 _minPrice,
        uint256 _maxPrice
    ) external onlyGov {
        require(_minPrice > 0 && _maxPrice > _minPrice, "MarksPriceFeed: invalid bounds");
        prices[_token].minPrice = _minPrice;
        prices[_token].maxPrice = _maxPrice;
        emit PriceBoundsSet(_token, _minPrice, _maxPrice);
    }
    
    // Price update functions
    
    function setPrice(address _token, uint256 _price) external onlyUpdater {
        _setPrice(_token, _price);
    }
    
    function setPrices(
        address[] memory _tokens,
        uint256[] memory _prices
    ) external onlyUpdater {
        require(_tokens.length == _prices.length, "MarksPriceFeed: length mismatch");
        
        for (uint256 i = 0; i < _tokens.length; i++) {
            _setPrice(_tokens[i], _prices[i]);
        }
    }
    
    function _setPrice(address _token, uint256 _price) private {
        require(_price > 0, "MarksPriceFeed: invalid price");
        
        PriceData storage data = prices[_token];
        
        // Check minimum time between updates (except for first update)
        if (data.timestamp > 0) {
            require(
                block.timestamp >= data.timestamp.add(minTimeBetweenUpdates),
                "MarksPriceFeed: too frequent"
            );
        }
        
        // Check price bounds if they are set
        if (data.minPrice > 0 && data.maxPrice > 0) {
            require(
                _price >= data.minPrice && _price <= data.maxPrice,
                "MarksPriceFeed: price out of bounds"
            );
        }
        
        // Check max price change if there's an existing price
        if (data.price > 0) {
            uint256 priceDiff = _price > data.price ? 
                _price.sub(data.price) : 
                data.price.sub(_price);
            
            uint256 maxChange = data.price.mul(maxPriceChangePerUpdate).div(BASIS_POINTS_DIVISOR);
            
            require(priceDiff <= maxChange, "MarksPriceFeed: price change too large");
        }
        
        // Update price
        data.price = _price;
        data.timestamp = block.timestamp;
        
        emit PriceUpdated(_token, _price, block.timestamp);
    }
    
    // Emergency admin function to force set price (bypasses checks)
    function emergencySetPrice(address _token, uint256 _price) external onlyGov {
        require(_price > 0, "MarksPriceFeed: invalid price");
        prices[_token].price = _price;
        prices[_token].timestamp = block.timestamp;
        emit PriceUpdated(_token, _price, block.timestamp);
    }
    
    // Query functions
    
    function getPrice(address _token) external view returns (uint256) {
        PriceData memory data = prices[_token];
        require(data.price > 0, "MarksPriceFeed: no price");
        require(!isStale(_token), "MarksPriceFeed: stale price");
        return data.price;
    }
    
    function getPriceUnsafe(address _token) external view returns (uint256) {
        // Returns price even if stale (for monitoring/debugging)
        return prices[_token].price;
    }
    
    function isStale(address _token) public view returns (bool) {
        PriceData memory data = prices[_token];
        if (data.timestamp == 0) return true;
        return block.timestamp > data.timestamp.add(maxPriceAge);
    }
    
    function getLastUpdateTime(address _token) external view returns (uint256) {
        return prices[_token].timestamp;
    }
    
    // Chainlink compatibility functions
    
    function latestAnswer() external view returns (int256) {
        // Default implementation for compatibility
        // Should be overridden per token in token-specific contracts
        revert("MarksPriceFeed: use token-specific price");
    }
    
    function latestRound() external view returns (uint80) {
        // Return a dummy round ID based on timestamp for compatibility
        return uint80(block.timestamp / 60); // New "round" every minute
    }
    
    function getRoundData(uint80 /* _roundId */)
        external
        view
        returns (
            uint80 /* roundId */,
            int256 /* answer */,
            uint256 /* startedAt */,
            uint256 /* updatedAt */,
            uint80 /* answeredInRound */
        )
    {
        revert("MarksPriceFeed: getRoundData not supported");
    }
}