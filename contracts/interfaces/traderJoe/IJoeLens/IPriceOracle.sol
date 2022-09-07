// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity >=0.8.0 <0.9.0;

interface IPriceOracle {
    function _setAdmin(address _admin) external;

    function _setAggregators(
        address[] memory jTokenAddresses,
        address[] memory sources
    ) external;

    function _setGuardian(address _guardian) external;

    function _setUnderlyingPrice(
        address jToken,
        uint256 underlyingPriceMantissa
    ) external;

    function admin() external view returns (address);

    function aggregators(address) external view returns (address);

    function getUnderlyingPrice(address jToken) external view returns (uint256);

    function guardian() external view returns (address);

    function setDirectPrice(address asset, uint256 price) external;
}
