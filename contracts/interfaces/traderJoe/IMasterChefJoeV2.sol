// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity >=0.8.0 <0.9.0;

interface IMasterChefJoeV2 {
    function add(
        uint256 _allocPoint,
        address _lpToken,
        address _rewarder
    ) external;

    function deposit(uint256 _pid, uint256 _amount) external;

    function dev(address _devAddr) external;

    function devAddr() external view returns (address);

    function devPercent() external view returns (uint256);

    function emergencyWithdraw(uint256 _pid) external;

    function investorAddr() external view returns (address);

    function investorPercent() external view returns (uint256);

    function joe() external view returns (address);

    function joePerSec() external view returns (uint256);

    function massUpdatePools() external;

    function owner() external view returns (address);

    function pendingTokens(uint256 _pid, address _user)
        external
        view
        returns (
            uint256 pendingJoe,
            address bonusTokenAddress,
            string memory bonusTokenSymbol,
            uint256 pendingBonusToken
        );

    function poolInfo(uint256)
        external
        view
        returns (
            address lpToken,
            uint256 allocPoint,
            uint256 lastRewardTimestamp,
            uint256 accJoePerShare,
            address rewarder
        );

    function poolLength() external view returns (uint256);

    function renounceOwnership() external;

    function rewarderBonusTokenInfo(uint256 _pid)
        external
        view
        returns (address bonusTokenAddress, string memory bonusTokenSymbol);

    function set(
        uint256 _pid,
        uint256 _allocPoint,
        address _rewarder,
        bool overwrite
    ) external;

    function setDevPercent(uint256 _newDevPercent) external;

    function setInvestorAddr(address _investorAddr) external;

    function setInvestorPercent(uint256 _newInvestorPercent) external;

    function setTreasuryAddr(address _treasuryAddr) external;

    function setTreasuryPercent(uint256 _newTreasuryPercent) external;

    function startTimestamp() external view returns (uint256);

    function totalAllocPoint() external view returns (uint256);

    function transferOwnership(address newOwner) external;

    function treasuryAddr() external view returns (address);

    function treasuryPercent() external view returns (uint256);

    function updateEmissionRate(uint256 _joePerSec) external;

    function updatePool(uint256 _pid) external;

    function userInfo(uint256, address)
        external
        view
        returns (uint256 amount, uint256 rewardDebt);

    function withdraw(uint256 _pid, uint256 _amount) external;
}
