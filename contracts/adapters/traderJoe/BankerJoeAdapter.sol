// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.0 <0.9.0;

import "../base/AdapterBase.sol";
import "../../interfaces/traderJoe/IJoeLens/IJToken.sol";
import "../../interfaces/traderJoe/IJoeLens/IJoetroller.sol";
import "../../interfaces/traderJoe/IJoeLens/IJWrappedNativeDelegator.sol";
import "../../interfaces/traderJoe/IJoeLens/IPriceOracle.sol";
import "../../interfaces/traderJoe/IJoeLens/IMaximillion.sol";
import "../../interfaces/IWAVAX.sol";

interface IBankerJoeAdapter {
    function trustJTokenAddr(address tokenAddr) external view returns (address);
}

contract BankerJoeAdapter is AdapterBase {
    using SafeERC20 for IERC20;

    address public constant JoetrollerAddr =
        0xdc13687554205E5b89Ac783db14bb5bba4A1eDaC;
    IJoetroller internal Joetroller = IJoetroller(JoetrollerAddr);

    address public constant joeMaximillionAddr =
        0xe5cDdAFd0f7Af3DEAf4bd213bBaee7A5927AB7E7;

    mapping(address => address) public trustJTokenAddr;

    constructor(address _adapterManager, address _timelock)
        AdapterBase(_adapterManager, _timelock, "BankerJoe")
    {}

    event BankerJoeInitialize(address[] tokenAddr, address[] jTokenAddr);
    event TraderJoeSupplyEvent(
        address token,
        address joeToken,
        uint256 amount,
        address account
    );

    event TraderJoeWithdrawEvent(
        address token,
        address joeToken,
        uint256 amount,
        address account
    );

    event TraderJoeBorrowEvent(
        address joeToken,
        uint256 amount,
        address account
    );
    event TraderJoeRepayEvent(
        address joeToken,
        uint256 amount,
        address account
    );

    function initialize(
        address[] calldata tokenAddrs,
        address[] calldata jTokenAddrs
    ) external onlyTimelock {
        require(
            tokenAddrs.length > 0 && tokenAddrs.length == jTokenAddrs.length,
            "Set length mismatch."
        );
        for (uint256 i = 0; i < tokenAddrs.length; i++) {
            if (tokenAddrs[i] == avaxAddr) {
                require(
                    IJWrappedNativeDelegator(jTokenAddrs[i]).underlying() ==
                        wavaxAddr,
                    "Address mismatch."
                );
            } else {
                require(
                    IJToken(jTokenAddrs[i]).underlying() == tokenAddrs[i],
                    "Address mismatch."
                );
            }
            require(
                Joetroller.isMarketListed(jTokenAddrs[i]),
                "!Invalid jtoken"
            );
            trustJTokenAddr[tokenAddrs[i]] = jTokenAddrs[i];
        }

        emit BankerJoeInitialize(tokenAddrs, jTokenAddrs);
    }

    function deposit(address tokenAddr, uint256 tokenAmount)
        external
        onlyDelegation
    {
        address jtokenAddr = IBankerJoeAdapter(ADAPTER_ADDRESS).trustJTokenAddr(
            tokenAddr
        );
        require(jtokenAddr != address(0), "Token invalid.");
        if (tokenAddr == avaxAddr) {
            require(
                IJWrappedNativeDelegator(jtokenAddr).underlying() == wavaxAddr,
                "Not AVAX."
            );
            require(
                IJWrappedNativeDelegator(jtokenAddr).mintNative{
                    value: tokenAmount
                }() == 0,
                "!mint"
            );
        } else {
            require(
                tokenAddr == IJToken(jtokenAddr).underlying(),
                "Token invalid."
            );
            require(IJToken(jtokenAddr).mint(tokenAmount) == 0, "!mint");
        }

        emit TraderJoeSupplyEvent(
            tokenAddr,
            jtokenAddr,
            tokenAmount,
            address(this)
        );
    }

    //todo delete jtokenAddr arg
    function withdraw(address account, bytes calldata encodedData)
        external
        onlyAdapterManager
    {
        (address tokenAddr, uint256 jtokenAmount) = abi.decode(
            encodedData,
            (address, uint256)
        );
        address jtokenAddr = trustJTokenAddr[tokenAddr];
        require(jtokenAddr != address(0), "Token invalid.");

        uint256 amountDiff;
        if (tokenAddr == avaxAddr || tokenAddr == wavaxAddr) {
            require(
                IJWrappedNativeDelegator(jtokenAddr).underlying() == wavaxAddr,
                "Not AVAX."
            );
            pullAndApprove(jtokenAddr, account, jtokenAddr, jtokenAmount);
            uint256 amountBefore = address(this).balance;
            require(
                IJWrappedNativeDelegator(jtokenAddr).redeemNative(
                    jtokenAmount
                ) == 0,
                "!redeem"
            );
            amountDiff = address(this).balance - amountBefore;
            require(amountDiff >= 0, "amount error");
            if (tokenAddr == avaxAddr) {
                safeTransferAVAX(account, amountDiff);
            } else {
                IWAVAX(wavaxAddr).deposit{value: amountDiff}();
                IWAVAX(wavaxAddr).transfer(account, amountDiff);
            }
        } else {
            require(
                IJToken(jtokenAddr).underlying() == tokenAddr,
                "Not token."
            );
            pullAndApprove(jtokenAddr, account, jtokenAddr, jtokenAmount);
            IERC20 token = IERC20(tokenAddr);
            uint256 amountBefore = token.balanceOf(address(this));

            require(IJToken(jtokenAddr).redeem(jtokenAmount) == 0, "!redeem");
            amountDiff = token.balanceOf(address(this)) - amountBefore;
            require(amountDiff > 0, "amount error");
            token.safeTransfer(account, amountDiff);
        }
        emit TraderJoeWithdrawEvent(tokenAddr, jtokenAddr, amountDiff, account);
    }

    function enterMarkets(address[] memory jTokenAddr) external onlyDelegation {
        IJoetroller(JoetrollerAddr).enterMarkets(jTokenAddr);
    }

    function exitMarket(address jTokenAddr) external onlyDelegation {
        IJoetroller(JoetrollerAddr).exitMarket(jTokenAddr);
    }

    function borrow(address tokenAddr, uint256 amount) external onlyDelegation {
        address jtokenAddr = IBankerJoeAdapter(ADAPTER_ADDRESS).trustJTokenAddr(
            tokenAddr
        );
        require(jtokenAddr != address(0), "Token invalid.");

        if (tokenAddr == avaxAddr) {
            require(
                IJWrappedNativeDelegator(jtokenAddr).borrowNative(amount) == 0,
                "!borrow"
            );
        } else {
            require(IJToken(jtokenAddr).borrow(amount) == 0, "!borrow");
        }

        emit TraderJoeBorrowEvent(jtokenAddr, amount, address(this));
    }

    function repay(address tokenAddr, uint256 amount) external onlyDelegation {
        address jtokenAddr = IBankerJoeAdapter(ADAPTER_ADDRESS).trustJTokenAddr(
            tokenAddr
        );
        require(jtokenAddr != address(0), "Token invalid.");
        if (tokenAddr == avaxAddr) {
            if (amount == type(uint256).max) {
                uint256 repayValue = IJWrappedNativeDelegator(jtokenAddr)
                    .borrowBalanceCurrent(address(this));
                IMaximillion(joeMaximillionAddr).repayBehalf{value: repayValue}(
                    address(this)
                );
            } else {
                IJWrappedNativeDelegator(jtokenAddr).repayBorrowNative{
                    value: amount
                }();
            }
        } else {
            IJToken(jtokenAddr).repayBorrow(amount);
        }

        emit TraderJoeRepayEvent(jtokenAddr, amount, address(this));
    }

    function claimReward(uint8 rewardType, address holder)
        external
        onlyDelegation
    {
        IJoetroller(JoetrollerAddr).claimReward(rewardType, holder);
    }
}
