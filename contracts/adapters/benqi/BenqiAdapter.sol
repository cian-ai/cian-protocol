// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity >=0.8.0 <0.9.0;

import "../base/AdapterBase.sol";
import "../../interfaces/benqi/IQiToken.sol";
import "../../interfaces/benqi/IQiAVAX.sol";
import "../../interfaces/benqi/IComptroller.sol";
import "../../interfaces/traderJoe/IJoeLens/IPriceOracle.sol";
import "../../interfaces/benqi/IMaximillion.sol";
import "../../interfaces/IWAVAX.sol";

interface IBenqiAdapter {
    function trustQiTokenAddr(address tokenAddr)
        external
        view
        returns (address);
}

contract BenqiAdapter is AdapterBase {
    using SafeERC20 for IERC20;

    address public constant unitrollerAddr =
        0x486Af39519B4Dc9a7fCcd318217352830E8AD9b4;
    address public constant qiAvaxAddr =
        0x5C0401e81Bc07Ca70fAD469b451682c0d747Ef1c;
    address public constant qiMaximillionAddr =
        0xd78DEd803b28A5A9C860c2cc7A4d84F611aA4Ef8;

    mapping(address => address) public trustQiTokenAddr;
    event BenqiInitialize(address[] tokenAddr, address[] qiTokenAddr);
    event BenqiBorrow(address qiToken, uint256 amount, address account);
    event BenqiRepay(address qiToken, uint256 amount, address account);
    event BenqiDeposit(address token, uint256 amount, address account);
    event BenqiWithdraw(address token, uint256 amount, address account);

    constructor(address _adapterManager, address _timelock)
        AdapterBase(_adapterManager, _timelock, "Benqi")
    {}

    function initialize(
        address[] calldata tokenAddrs,
        address[] calldata qiTokenAddrs
    ) external onlyTimelock {
        require(
            tokenAddrs.length > 0 && tokenAddrs.length == qiTokenAddrs.length,
            "Set length mismatch."
        );
        for (uint256 i = 0; i < tokenAddrs.length; i++) {
            if (tokenAddrs[i] == avaxAddr || tokenAddrs[i] == wavaxAddr) {
                require(qiTokenAddrs[i] == qiAvaxAddr, "Token invalid.");
            } else {
                require(
                    IQiToken(qiTokenAddrs[i]).underlying() == tokenAddrs[i],
                    "Address mismatch."
                );
            }
            (bool isMarketListed, , ) = IComptroller(unitrollerAddr).markets(
                qiTokenAddrs[i]
            );
            require(isMarketListed, "!Invalid qitoken");
            trustQiTokenAddr[tokenAddrs[i]] = qiTokenAddrs[i];
        }

        emit BenqiInitialize(tokenAddrs, qiTokenAddrs);
    }

    function deposit(address tokenAddr, uint256 tokenAmount)
        external
        onlyDelegation
    {
        address qiTokenAddr = IBenqiAdapter(ADAPTER_ADDRESS).trustQiTokenAddr(
            tokenAddr
        );
        require(qiTokenAddr != address(0), "Token invalid.");
        if (tokenAddr == avaxAddr) {
            IQiAVAX(qiTokenAddr).mint{value: tokenAmount}();
        } else if (tokenAddr == wavaxAddr) {
            IWAVAX(wavaxAddr).withdraw(tokenAmount);
            IQiAVAX(qiTokenAddr).mint{value: tokenAmount}();
        } else {
            require(IQiToken(qiTokenAddr).mint(tokenAmount) == 0, "!mint");
        }
        emit BenqiDeposit(tokenAddr, tokenAmount, address(this));
    }

    function withdraw(address account, bytes calldata encodedData)
        external
        onlyAdapterManager
    {
        (address tokenAddr, uint256 qiTokenAmount) = abi.decode(
            encodedData,
            (address, uint256)
        );
        address qiTokenAddr = trustQiTokenAddr[tokenAddr];
        require(qiTokenAddr != address(0), "Token invalid.");
        pullAndApprove(qiTokenAddr, account, qiTokenAddr, qiTokenAmount);
        uint256 amountDiff;
        if (tokenAddr == avaxAddr) {
            uint256 amountBefore = address(this).balance;
            require(IQiAVAX(qiTokenAddr).redeem(qiTokenAmount) == 0, "!redeem");
            amountDiff = address(this).balance - amountBefore;
            require(amountDiff > 0, "amount error");
            safeTransferAVAX(account, amountDiff);
        } else {
            IERC20 token = IERC20(tokenAddr);
            if (tokenAddr == wavaxAddr) {
                uint256 amountBefore = address(this).balance;
                require(
                    IQiToken(qiTokenAddr).redeem(qiTokenAmount) == 0,
                    "!redeem"
                );
                amountDiff = address(this).balance - amountBefore;
                IWAVAX(wavaxAddr).deposit{value: amountDiff}();
            } else {
                uint256 amountBefore = token.balanceOf(address(this));
                require(
                    IQiToken(qiTokenAddr).redeem(qiTokenAmount) == 0,
                    "!redeem"
                );
                amountDiff = token.balanceOf(address(this)) - amountBefore;
            }

            require(amountDiff > 0, "amount error");
            token.safeTransfer(account, amountDiff);
        }

        emit BenqiWithdraw(tokenAddr, qiTokenAmount, account);
    }

    function enterMarkets(address[] memory qiTokenAddr)
        external
        onlyDelegation
    {
        IComptroller(unitrollerAddr).enterMarkets(qiTokenAddr);
    }

    function exitMarket(address qiTokenAddr) external onlyDelegation {
        IComptroller(unitrollerAddr).exitMarket(qiTokenAddr);
    }

    function borrow(address tokenAddr, uint256 amount) external onlyDelegation {
        address qiTokenAddr = IBenqiAdapter(ADAPTER_ADDRESS).trustQiTokenAddr(
            tokenAddr
        );
        require(qiTokenAddr != address(0), "Token invalid.");
        if (tokenAddr == avaxAddr) {
            IQiAVAX(qiTokenAddr).borrow(amount);
        } else {
            if (tokenAddr == wavaxAddr) {
                require(IQiAVAX(qiTokenAddr).borrow(amount) == 0, "!borrow");
                IWAVAX(wavaxAddr).deposit{value: amount}();
            } else {
                IQiToken(qiTokenAddr).borrow(amount);
            }
        }

        emit BenqiBorrow(qiTokenAddr, amount, address(this));
    }

    function repay(address tokenAddr, uint256 amount) external onlyDelegation {
        address qiTokenAddr = IBenqiAdapter(ADAPTER_ADDRESS).trustQiTokenAddr(
            tokenAddr
        );
        require(qiTokenAddr != address(0), "Token invalid.");
        if (tokenAddr == avaxAddr) {
            if (amount == type(uint256).max) {
                uint256 repayValue = IQiAVAX(qiTokenAddr).borrowBalanceCurrent(
                    address(this)
                );
                IMaximillion(qiMaximillionAddr).repayBehalf{value: repayValue}(
                    address(this)
                );
            } else {
                IQiAVAX(qiTokenAddr).repayBorrow{value: amount}();
            }
        } else if (tokenAddr == wavaxAddr) {
            if (amount == type(uint256).max) {
                uint256 repayValue = IQiAVAX(qiTokenAddr).borrowBalanceCurrent(
                    address(this)
                );
                IWAVAX(wavaxAddr).withdraw(repayValue);
                IMaximillion(qiMaximillionAddr).repayBehalf{value: repayValue}(
                    address(this)
                );
            } else {
                IWAVAX(wavaxAddr).withdraw(amount);
                IQiAVAX(qiTokenAddr).repayBorrow{value: amount}();
            }
        } else {
            IQiToken(qiTokenAddr).repayBorrow(amount);
        }
        emit BenqiRepay(qiTokenAddr, amount, address(this));
    }

    function claimRewards(uint8 rewardType) external onlyDelegation {
        IComptroller(unitrollerAddr).claimReward(rewardType, address(this));
    }
}
