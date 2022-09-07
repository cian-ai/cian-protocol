// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity >=0.8.0 <0.9.0;

interface ISimpleRewardPerSecond {
    function MCJ() external view returns (address);

    function balance() external view returns (uint256);

    function claimOwnership() external;

    function emergencyWithdraw() external;

    function isNative() external view returns (bool);

    function lpToken() external view returns (address);

    function onJoeReward(address _user, uint256 _lpAmount) external;

    function owner() external view returns (address);

    function pendingOwner() external view returns (address);

    function pendingTokens(address _user)
        external
        view
        returns (uint256 pending);

    function poolInfo()
        external
        view
        returns (uint256 accTokenPerShare, uint256 lastRewardTimestamp);

    function rewardToken() external view returns (address);

    function setRewardRate(uint256 _tokenPerSec) external;

    function tokenPerSec() external view returns (uint256);

    function transferOwnership(
        address newOwner,
        bool direct,
        bool renounce
    ) external;

    //   function updatePool (  ) external returns ( tuple pool );
    function userInfo(address)
        external
        view
        returns (uint256 amount, uint256 rewardDebt);
}
