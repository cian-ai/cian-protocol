// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity >=0.8.0 <0.9.0;

interface ISAVAX {
    function DEFAULT_ADMIN_ROLE() external view returns (bytes32);

    function ROLE_ACCRUE_REWARDS() external view returns (bytes32);

    function ROLE_DEPOSIT() external view returns (bytes32);

    function ROLE_PAUSE() external view returns (bytes32);

    function ROLE_PAUSE_MINTING() external view returns (bytes32);

    function ROLE_RESUME() external view returns (bytes32);

    function ROLE_RESUME_MINTING() external view returns (bytes32);

    function ROLE_SET_TOTAL_POOLED_AVAX_CAP() external view returns (bytes32);

    function ROLE_WITHDRAW() external view returns (bytes32);

    function accrueRewards(uint256 amount) external;

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function balanceOf(address account) external view returns (uint256);

    function cancelPendingUnlockRequests() external;

    function cancelRedeemableUnlockRequests() external;

    function cancelUnlockRequest(uint256 unlockIndex) external;

    function cooldownPeriod() external view returns (uint256);

    function decimals() external pure returns (uint8);

    function deposit() external;

    // function getPaginatedUnlockRequests(
    //     address user,
    //     uint256 from,
    //     uint256 to
    // ) external view returns (tuple[], uint256[]);

    function getPooledAvaxByShares(uint256 shareAmount)
        external
        view
        returns (uint256);

    function getRoleAdmin(bytes32 role) external view returns (bytes32);

    function getRoleMember(bytes32 role, uint256 index)
        external
        view
        returns (address);

    function getRoleMemberCount(bytes32 role) external view returns (uint256);

    function getSharesByPooledAvax(uint256 avaxAmount)
        external
        view
        returns (uint256);

    function getUnlockRequestCount(address user)
        external
        view
        returns (uint256);

    function grantRole(bytes32 role, address account) external;

    function hasRole(bytes32 role, address account)
        external
        view
        returns (bool);

    function historicalExchangeRateTimestamps(uint256)
        external
        view
        returns (uint256);

    function historicalExchangeRatesByTimestamp(uint256)
        external
        view
        returns (uint256);

    function initialize(uint256 _cooldownPeriod, uint256 _redeemPeriod)
        external;

    function mintingPaused() external view returns (bool);

    function name() external pure returns (string memory);

    function pause() external;

    function pauseMinting() external;

    function paused() external view returns (bool);

    function redeem() external;

    function redeem(uint256 unlockIndex) external;

    function redeemOverdueShares() external;

    function redeemOverdueShares(uint256 unlockIndex) external;

    function redeemPeriod() external view returns (uint256);

    function renounceRole(bytes32 role, address account) external;

    function requestUnlock(uint256 shareAmount) external;

    function resume() external;

    function resumeMinting() external;

    function revokeRole(bytes32 role, address account) external;

    function setCooldownPeriod(uint256 newCooldownPeriod) external;

    // function setHistoricalExchangeRatesByTimestamp(
    //     uint256[] timestamps,
    //     uint256[] exchangeRates
    // ) external;

    function setRedeemPeriod(uint256 newRedeemPeriod) external;

    function setTotalPooledAvaxCap(uint256 newTotalPooledAvaxCap) external;

    function stakerCount() external view returns (uint256);

    function submit() external payable returns (uint256);

    function symbol() external pure returns (string memory);

    function totalPooledAvax() external view returns (uint256);

    function totalPooledAvaxCap() external view returns (uint256);

    function totalShares() external view returns (uint256);

    function totalSupply() external view returns (uint256);

    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    function userSharesInCustody(address) external view returns (uint256);

    function userUnlockRequests(address, uint256)
        external
        view
        returns (uint256 startedAt, uint256 shareAmount);

    function withdraw(uint256 amount) external;
}
