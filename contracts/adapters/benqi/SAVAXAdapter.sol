// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity >=0.8.0 <0.9.0;

import "../base/AdapterBase.sol";
import "../../interfaces/benqi/ISAVAX.sol";
import "../../interfaces/IWAVAX.sol";

contract SAVAXAdapter is AdapterBase {
    address public constant SAVAX = 0x2b2C81e08f1Af8835a78Bb2A90AE924ACE0eA4bE;
    address public constant WAVAX = 0xB31f66AA3C1e785363F0875A1B74E27b85FD66c7;

    constructor(address _adapterManager, address _timelock)
        AdapterBase(_adapterManager, _timelock, "SAVAX")
    {}

    function stake(uint256 amount) external onlyDelegation {
        ISAVAX(SAVAX).submit{value: amount}();
    }

    function stakeWAVAX(uint256 amount) external onlyDelegation {
        IWAVAX(WAVAX).withdraw(amount);
        ISAVAX(SAVAX).submit{value: amount}();
    }

    function unstake(uint256 amount) external onlyDelegation {
        ISAVAX(SAVAX).requestUnlock(amount);
    }

    function redeem() external onlyDelegation {
        ISAVAX(SAVAX).redeem();
    }
}
