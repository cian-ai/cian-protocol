// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity >=0.8.0 <0.9.0;

interface ITripleSlopeRateModelMajors {
    function baseRatePerSecond() external view returns (uint256);

    function getBorrowRate(
        uint256 cash,
        uint256 borrows,
        uint256 reserves
    ) external view returns (uint256);

    function getSupplyRate(
        uint256 cash,
        uint256 borrows,
        uint256 reserves,
        uint256 reserveFactorMantissa
    ) external view returns (uint256);

    function isInterestRateModel() external view returns (bool);

    function jumpMultiplierPerSecond() external view returns (uint256);

    function kink1() external view returns (uint256);

    function kink2() external view returns (uint256);

    function multiplierPerSecond() external view returns (uint256);

    function owner() external view returns (address);

    function roof() external view returns (uint256);

    function secondsPerYear() external view returns (uint256);

    function updateTripleRateModel(
        uint256 baseRatePerYear,
        uint256 multiplierPerYear,
        uint256 jumpMultiplierPerYear,
        uint256 kink1_,
        uint256 kink2_,
        uint256 roof_
    ) external;

    function utilizationRate(
        uint256 cash,
        uint256 borrows,
        uint256 reserves
    ) external view returns (uint256);
}
