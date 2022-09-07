// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity >=0.8.0 <0.9.0;

abstract contract Basic {
    /**
     * @dev Return ethereum address
     */
    address public constant avaxAddr =
        0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

    /// @dev Return Wrapped AVAX address
    address public constant wavaxAddr =
        0xB31f66AA3C1e785363F0875A1B74E27b85FD66c7;

    function safeTransferAVAX(address to, uint256 value) internal {
        if (value != 0) {
            (bool success, ) = to.call{value: value}(new bytes(0));
            require(success, "helper::safeTransferAVAX: AVAX transfer failed");
        }
    }
}
