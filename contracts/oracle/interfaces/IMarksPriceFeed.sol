// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

interface IMarksPriceFeed {
    function getPrice(address _token) external view returns (uint256);
    function getPriceUnsafe(address _token) external view returns (uint256);
    function isStale(address _token) external view returns (bool);
    function getLastUpdateTime(address _token) external view returns (uint256);
    function setPrice(address _token, uint256 _price) external;
    function setPrices(address[] memory _tokens, uint256[] memory _prices) external;
}