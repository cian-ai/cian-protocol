// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity >=0.8.0 <0.9.0;

interface IJoetroller {
    function _acceptAdmin() external returns (uint256);

    function _acceptImplementation() external returns (uint256);

    function _setPendingAdmin(address newPendingAdmin)
        external
        returns (uint256);

    function _setPendingImplementation(address newPendingImplementation)
        external
        returns (uint256);

    function admin() external view returns (address);

    function implementation() external view returns (address);

    function pendingAdmin() external view returns (address);

    function pendingImplementation() external view returns (address);

    /*** Assets You Are In ***/

    function enterMarkets(address[] calldata jTokens)
        external
        returns (uint256[] memory);

    function exitMarket(address jToken) external returns (uint256);

    /*** Policy Hooks ***/

    function mintAllowed(
        address jToken,
        address minter,
        uint256 mintAmount
    ) external returns (uint256);

    function mintVerify(
        address jToken,
        address minter,
        uint256 mintAmount,
        uint256 mintTokens
    ) external;

    function redeemAllowed(
        address jToken,
        address redeemer,
        uint256 redeemTokens
    ) external returns (uint256);

    function redeemVerify(
        address jToken,
        address redeemer,
        uint256 redeemAmount,
        uint256 redeemTokens
    ) external;

    function borrowAllowed(
        address jToken,
        address borrower,
        uint256 borrowAmount
    ) external returns (uint256);

    function borrowVerify(
        address jToken,
        address borrower,
        uint256 borrowAmount
    ) external;

    function repayBorrowAllowed(
        address jToken,
        address payer,
        address borrower,
        uint256 repayAmount
    ) external returns (uint256);

    function repayBorrowVerify(
        address jToken,
        address payer,
        address borrower,
        uint256 repayAmount,
        uint256 borrowerIndex
    ) external;

    function liquidateBorrowAllowed(
        address jTokenBorrowed,
        address jTokenCollateral,
        address liquidator,
        address borrower,
        uint256 repayAmount
    ) external returns (uint256);

    function liquidateBorrowVerify(
        address jTokenBorrowed,
        address jTokenCollateral,
        address liquidator,
        address borrower,
        uint256 repayAmount,
        uint256 seizeTokens
    ) external;

    function seizeAllowed(
        address jTokenCollateral,
        address jTokenBorrowed,
        address liquidator,
        address borrower,
        uint256 seizeTokens
    ) external returns (uint256);

    function seizeVerify(
        address jTokenCollateral,
        address jTokenBorrowed,
        address liquidator,
        address borrower,
        uint256 seizeTokens
    ) external;

    function transferAllowed(
        address jToken,
        address src,
        address dst,
        uint256 transferTokens
    ) external returns (uint256);

    function transferVerify(
        address jToken,
        address src,
        address dst,
        uint256 transferTokens
    ) external;

    /*** Liquidity/Liquidation Calculations ***/

    function liquidateCalculateSeizeTokens(
        address jTokenBorrowed,
        address jTokenCollateral,
        uint256 repayAmount
    ) external view returns (uint256, uint256);

    function getAssetsIn(address user) external view returns (address[] memory);

    function oracle() external view returns (address);

    function markets(address jToken)
        external
        view
        returns (
            bool,
            uint256,
            uint8
        );

    function claimReward(uint8 rewardType, address holder) external;

    function claimReward(
        uint8 rewardType,
        address holder,
        address[] calldata jTokens
    ) external;

    function claimReward(
        uint8 rewardType,
        address[] calldata holders,
        address[] calldata jTokens,
        bool borrowers,
        bool suppliers
    ) external payable;

    function getAllMarkets() external view returns (address[] memory);

    function checkMembership(address account, address jToken)
        external
        view
        returns (bool);

    function getAccountLiquidity(address account)
        external
        view
        returns (
            uint256,
            uint256,
            uint256
        );

    function isMarketListed(address jToken) external returns (bool);
}
