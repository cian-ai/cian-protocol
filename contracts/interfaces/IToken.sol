// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity >=0.8.0 <0.9.0;

interface IToken {
    function approve(address, uint256) external;

    function transfer(address, uint256) external;

    function mint() external payable;

    function mint(uint256 mintAmount) external payable;

    function transferFrom(
        address,
        address,
        uint256
    ) external;

    function deposit() external payable;

    function withdraw(uint256) external;

    function balanceOf(address) external view returns (uint256);

    function decimals() external view returns (uint256);

    function symbol() external view returns (string memory);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);
}
