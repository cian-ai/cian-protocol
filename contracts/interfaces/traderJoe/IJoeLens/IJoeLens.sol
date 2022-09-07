// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity >=0.8.0 <0.9.0;

interface IJoeLens {
    enum Version {
        VANILLA,
        COLLATERALCAP,
        WRAPPEDNATIVE
    }
    struct JTokenMetadata {
        address jToken;
        uint256 exchangeRateCurrent;
        uint256 supplyRatePerSecond;
        uint256 borrowRatePerSecond;
        uint256 reserveFactorMantissa;
        uint256 totalBorrows;
        uint256 totalReserves;
        uint256 totalSupply;
        uint256 totalCash;
        uint256 totalCollateralTokens;
        bool isListed;
        uint256 collateralFactorMantissa;
        address underlyingAssetAddress;
        uint256 jTokenDecimals;
        uint256 underlyingDecimals;
        Version version;
        uint256 collateralCap;
        uint256 underlyingPrice;
        bool supplyPaused;
        bool borrowPaused;
        uint256 supplyCap;
        uint256 borrowCap;
    }

    function getAccountLimits(address joetroller, address account)
        external
        returns (bytes calldata);

    function getClaimableRewards(
        uint8 rewardType,
        address joetroller,
        address joe,
        address account
    ) external returns (uint256);

    function jTokenBalances(address jToken, address account)
        external
        returns (bytes calldata);

    function jTokenBalancesAll(address[] calldata jTokens, address account)
        external
        returns (bytes[] calldata);

    function jTokenMetadata(address jToken)
        external
        returns (JTokenMetadata calldata);

    function jTokenMetadataAll(address[] calldata jTokens)
        external
        returns (JTokenMetadata[] calldata);

    function nativeSymbol() external view returns (string calldata);
}
