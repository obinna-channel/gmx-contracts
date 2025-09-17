// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

/**
 * @title sNGN - Synthetic Nigerian Naira Token
 * @notice This is a stub token used purely as an identifier for the USDT/NGN market in the Marks Exchange system.
 * @dev This token has no transfer functionality and is not meant to be traded or held.
 * It exists solely to provide a unique address that GMX contracts can use to identify the NGN market.
 */
contract sNGN {
    string public constant name = "Synthetic Nigerian Naira";
    string public constant symbol = "sNGN";
    uint8 public constant decimals = 18;
    
    // Set total supply to 0 since this is just a stub
    uint256 public constant totalSupply = 0;
    
    // Events that might be expected by indexers
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    
    // Empty mappings to satisfy ERC20 interface
    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;
    
    constructor() public {
        // Emit a Transfer event from address(0) to address(0) with 0 value
        // This helps indexers recognize this as an ERC20 token
        emit Transfer(address(0), address(0), 0);
    }
    
    /**
     * @notice Transfer function - always reverts
     * @dev This token cannot be transferred as it's only a market identifier
     */
    function transfer(address, uint256) external pure returns (bool) {
        revert("sNGN: transfers are disabled");
    }
    
    /**
     * @notice TransferFrom function - always reverts
     * @dev This token cannot be transferred as it's only a market identifier
     */
    function transferFrom(address, address, uint256) external pure returns (bool) {
        revert("sNGN: transfers are disabled");
    }
    
    /**
     * @notice Approve function - always reverts
     * @dev No approvals needed as transfers are disabled
     */
    function approve(address, uint256) external pure returns (bool) {
        revert("sNGN: approvals are disabled");
    }
    
    /**
     * @notice Returns the token metadata for external queries
     * @dev Useful for wallets and explorers to identify this token
     */
    function tokenMetadata() external pure returns (
        string memory _name,
        string memory _symbol,
        uint8 _decimals,
        uint256 _totalSupply
    ) {
        return (name, symbol, decimals, totalSupply);
    }
}