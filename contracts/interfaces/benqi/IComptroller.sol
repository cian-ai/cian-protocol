// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity >=0.8.0 <0.9.0;

interface IComptroller {
    function accountAssets(address, uint256) external view returns (address);

    function admin() external view returns (address);

    function allMarkets(uint256) external view returns (address);

    function borrowAllowed(
        address qiToken,
        address borrower,
        uint256 borrowAmount
    ) external returns (uint256);

    function borrowCapGuardian() external view returns (address);

    function borrowCaps(address) external view returns (uint256);

    function borrowVerify(
        address qiToken,
        address borrower,
        uint256 borrowAmount
    ) external;

    function checkMembership(address account, address qiToken)
        external
        view
        returns (bool);

    function claimReward(uint8 rewardType, address holder) external;

    function claimReward(
        uint8 rewardType,
        address holder,
        address[] calldata qiTokens
    ) external;

    function claimReward(
        uint8 rewardType,
        address[] calldata holders,
        address[] calldata qiTokens,
        bool borrowers,
        bool suppliers
    ) external payable;

    function closeFactorMantissa() external view returns (uint256);

    function comptrollerImplementation() external view returns (address);

    function enterMarkets(address[] calldata qiTokens)
        external
        returns (uint256[] calldata);

    function exitMarket(address qiTokenAddress) external returns (uint256);

    function getAccountLiquidity(address account)
        external
        view
        returns (
            uint256,
            uint256,
            uint256
        );

    function getAllMarkets() external view returns (address[] calldata);

    function getAssetsIn(address account)
        external
        view
        returns (address[] calldata);

    function getBlockTimestamp() external view returns (uint256);

    function getHypotheticalAccountLiquidity(
        address account,
        address qiTokenModify,
        uint256 redeemTokens,
        uint256 borrowAmount
    )
        external
        view
        returns (
            uint256,
            uint256,
            uint256
        );

    function initialIndexConstant() external view returns (uint224);

    function isComptroller() external view returns (bool);

    function liquidateBorrowAllowed(
        address qiTokenBorrowed,
        address qiTokenCollateral,
        address liquidator,
        address borrower,
        uint256 repayAmount
    ) external returns (uint256);

    function liquidateBorrowVerify(
        address qiTokenBorrowed,
        address qiTokenCollateral,
        address liquidator,
        address borrower,
        uint256 actualRepayAmount,
        uint256 seizeTokens
    ) external;

    function liquidateCalculateSeizeTokens(
        address qiTokenBorrowed,
        address qiTokenCollateral,
        uint256 actualRepayAmount
    ) external view returns (uint256, uint256);

    function liquidationIncentiveMantissa() external view returns (uint256);

    function markets(address)
        external
        view
        returns (
            bool isListed,
            uint256 collateralFactorMantissa,
            bool isQied
        );

    function maxAssets() external view returns (uint256);

    function mintAllowed(
        address qiToken,
        address minter,
        uint256 mintAmount
    ) external returns (uint256);

    function mintGuardianPaused(address) external view returns (bool);

    function mintVerify(
        address qiToken,
        address minter,
        uint256 actualMintAmount,
        uint256 mintTokens
    ) external;

    function oracle() external view returns (address);

    function pauseGuardian() external view returns (address);

    function pendingAdmin() external view returns (address);

    function pendingComptrollerImplementation() external view returns (address);

    function qiAddress() external view returns (address);

    function redeemAllowed(
        address qiToken,
        address redeemer,
        uint256 redeemTokens
    ) external returns (uint256);

    function redeemVerify(
        address qiToken,
        address redeemer,
        uint256 redeemAmount,
        uint256 redeemTokens
    ) external;

    function repayBorrowAllowed(
        address qiToken,
        address payer,
        address borrower,
        uint256 repayAmount
    ) external returns (uint256);

    function repayBorrowVerify(
        address qiToken,
        address payer,
        address borrower,
        uint256 actualRepayAmount,
        uint256 borrowerIndex
    ) external;

    function rewardAccrued(uint8, address) external view returns (uint256);

    function rewardAvax() external view returns (uint8);

    function rewardBorrowState(uint8, address)
        external
        view
        returns (uint224 index, uint32 timestamp);

    function rewardBorrowerIndex(
        uint8,
        address,
        address
    ) external view returns (uint256);

    function rewardQi() external view returns (uint8);

    function rewardSpeeds(uint8, address) external view returns (uint256);

    function rewardSupplierIndex(
        uint8,
        address,
        address
    ) external view returns (uint256);

    function rewardSupplyState(uint8, address)
        external
        view
        returns (uint224 index, uint32 timestamp);

    function seizeAllowed(
        address qiTokenCollateral,
        address qiTokenBorrowed,
        address liquidator,
        address borrower,
        uint256 seizeTokens
    ) external returns (uint256);

    function seizeGuardianPaused() external view returns (bool);

    function seizeVerify(
        address qiTokenCollateral,
        address qiTokenBorrowed,
        address liquidator,
        address borrower,
        uint256 seizeTokens
    ) external;

    function setQiAddress(address newQiAddress) external;

    function transferAllowed(
        address qiToken,
        address src,
        address dst,
        uint256 transferTokens
    ) external returns (uint256);

    function transferGuardianPaused() external view returns (bool);

    function transferVerify(
        address qiToken,
        address src,
        address dst,
        uint256 transferTokens
    ) external;
}
