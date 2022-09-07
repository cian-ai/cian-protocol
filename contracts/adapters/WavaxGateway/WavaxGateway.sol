// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity >=0.8.0 <0.9.0;

import "../base/AdapterBase.sol";
import "../../interfaces/IWAVAX.sol";

contract WavaxGateway is AdapterBase {
    constructor(address _adapterManager, address _timelock)
        AdapterBase(_adapterManager, _timelock, "WavaxGateway")
    {}

    function deposit(uint256 amount) external onlyDelegation {
        require(amount > 0, "deposit amount error.");
        IWAVAX(payable(wavaxAddr)).deposit{value: amount}();
    }

    function withdraw(uint256 amount) external onlyDelegation {
        require(amount > 0, "withdraw amount error.");
        IWAVAX(wavaxAddr).withdraw(amount);
    }
}
