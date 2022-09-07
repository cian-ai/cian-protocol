// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.0 <0.9.0;

import "../base/AdapterBase.sol";
import "../../interfaces/traderJoe/IJoeLens/IJToken.sol";
import "../../interfaces/traderJoe/IMasterChefJoeV2.sol";
import "../../interfaces/traderJoe/IJoeBar.sol";
import "../../interfaces/traderJoe/IJoeFactory.sol";
import "../../interfaces/traderJoe/IJoeRouter02.sol";
import "../../interfaces/traderJoe/IJoePair.sol";
import "../../interfaces/IWAVAX.sol";
import "../../utils/HomoraMath.sol";

interface ITraderJoeAdapter {
    function isTrustMasterChef(address tokenAddr) external view returns (bool);
}

contract TraderJoeAdapter is AdapterBase {
    using SafeERC20 for IERC20;

    address public constant routerAddr =
        0x60aE616a2155Ee3d9A68541Ba4544862310933d4;
    IJoeRouter02 internal constant router = IJoeRouter02(routerAddr);

    mapping(address => bool) public isTrustMasterChef;

    constructor(address _adapterManager, address _timelock)
        AdapterBase(_adapterManager, _timelock, "TraderJoe")
    {}

    event TraderJoeInitialize(address[] masterChefs);

    event TraderJoeFarmEvent(
        address farmAddress,
        address account,
        uint256 amount,
        uint256 pid
    );

    event TraderJoeUnFarmEvent(
        address farmAddress,
        address account,
        uint256 amount,
        uint256 pid
    );

    event TraderJoeEmergencyWithdrawEvent(
        address farmAddress,
        address account,
        uint256 pid
    );

    event TraderJoeAddLiquidityEvent(
        uint256 liquidity,
        address token0,
        address token1,
        uint256 amount0,
        uint256 amount1,
        address account
    );

    event TraderJoeRemoveLiquidityEvent(
        address token0,
        address token1,
        uint256 amount,
        uint256 amount0,
        uint256 amount1,
        address account
    );

    function initialize(address[] calldata masterChefs) external onlyTimelock {
        for (uint256 i = 0; i < masterChefs.length; i++) {
            isTrustMasterChef[masterChefs[i]] = true;
        }

        emit TraderJoeInitialize(masterChefs);
    }

    function swapTokensForExactTokens(
        address account,
        bytes calldata encodedData
    ) external onlyAdapterManager {
        (uint256 amountOut, uint256 amountInMax, address[] memory path) = abi
            .decode(encodedData, (uint256, uint256, address[]));
        pullAndApprove(path[0], account, routerAddr, amountInMax);
        uint256[] memory amounts = router.swapTokensForExactTokens(
            amountOut,
            amountInMax,
            path,
            account,
            block.timestamp
        );
        returnAsset(path[0], account, amountInMax - amounts[0]);
    }

    function swapExactTokensForTokens(
        address account,
        bytes calldata encodedData
    ) external onlyAdapterManager {
        (uint256 amountIn, uint256 amountOutMin, address[] memory path) = abi
            .decode(encodedData, (uint256, uint256, address[]));
        pullAndApprove(path[0], account, routerAddr, amountIn);
        router.swapExactTokensForTokens(
            amountIn,
            amountOutMin,
            path,
            account,
            block.timestamp
        );
    }

    struct addLiquidityInfo {
        address tokenA;
        address tokenB;
        uint256 amountA;
        uint256 amountB;
        uint256 minAmountA;
        uint256 minAmountB;
    }

    function addLiquidity(address account, bytes calldata encodedData)
        external
        onlyAdapterManager
    {
        addLiquidityInfo memory addInfo = abi.decode(
            encodedData,
            (addLiquidityInfo)
        );
        pullAndApprove(addInfo.tokenA, account, routerAddr, addInfo.amountA);
        pullAndApprove(addInfo.tokenB, account, routerAddr, addInfo.amountB);
        (uint256 _amountA, uint256 _amountB, uint256 _liquidity) = router
            .addLiquidity(
                addInfo.tokenA,
                addInfo.tokenB,
                addInfo.amountA,
                addInfo.amountB,
                addInfo.minAmountA,
                addInfo.minAmountB,
                account,
                block.timestamp
            );
        returnAsset(addInfo.tokenA, account, addInfo.amountA - _amountA);
        returnAsset(addInfo.tokenB, account, addInfo.amountB - _amountB);

        emit TraderJoeAddLiquidityEvent(
            _liquidity,
            addInfo.tokenA,
            addInfo.tokenB,
            _amountA,
            _amountB,
            account
        );
    }

    struct removeLiquidityInfo {
        address tokenA;
        address tokenB;
        uint256 amount;
        uint256 minAmountA;
        uint256 minAmountB;
    }

    function removeLiquidity(address account, bytes calldata encodedData)
        external
        onlyAdapterManager
    {
        removeLiquidityInfo memory removeInfo = abi.decode(
            encodedData,
            (removeLiquidityInfo)
        );
        address lpTokenAddr = IJoeFactory(router.factory()).getPair(
            removeInfo.tokenA,
            removeInfo.tokenB
        );
        require(lpTokenAddr != address(0), "pair-not-found.");
        pullAndApprove(lpTokenAddr, account, routerAddr, removeInfo.amount);
        (uint256 _amountA, uint256 _amountB) = router.removeLiquidity(
            removeInfo.tokenA,
            removeInfo.tokenB,
            removeInfo.amount,
            removeInfo.minAmountA,
            removeInfo.minAmountB,
            account,
            block.timestamp
        );
        emit TraderJoeRemoveLiquidityEvent(
            removeInfo.tokenA,
            removeInfo.tokenB,
            removeInfo.amount,
            _amountA,
            _amountB,
            account
        );
    }

    struct addLiquidityAVAXInfo {
        address tokenAddr;
        uint256 amountTokenDesired;
        uint256 amountTokenMin;
        uint256 amountAVAXMin;
    }

    /// @dev using AVAX to add liquidity
    function addLiquidityAVAX(address account, bytes calldata encodedData)
        external
        payable
        onlyAdapterManager
    {
        addLiquidityAVAXInfo memory addInfo = abi.decode(
            encodedData,
            (addLiquidityAVAXInfo)
        );
        pullAndApprove(
            addInfo.tokenAddr,
            account,
            routerAddr,
            addInfo.amountTokenDesired
        );
        (uint256 _amountToken, uint256 _amountAVAX, uint256 _liquidity) = router
            .addLiquidityAVAX{value: msg.value}(
            addInfo.tokenAddr,
            addInfo.amountTokenDesired,
            addInfo.amountTokenMin,
            addInfo.amountAVAXMin,
            account,
            block.timestamp
        );
        returnAsset(
            addInfo.tokenAddr,
            account,
            addInfo.amountTokenDesired - _amountToken
        );
        returnAsset(avaxAddr, account, msg.value - _amountAVAX);

        emit TraderJoeAddLiquidityEvent(
            _liquidity,
            addInfo.tokenAddr,
            avaxAddr,
            _amountToken,
            _amountAVAX,
            account
        );
    }

    struct removeLiquidityAVAXInfo {
        address tokenA;
        uint256 liquidity;
        uint256 amountTokenMin;
        uint256 amountAVAXMin;
    }

    /// @dev remove liquidity to get AVAX
    function removeLiquidityAVAX(address account, bytes calldata encodedData)
        external
        onlyAdapterManager
    {
        removeLiquidityAVAXInfo memory removeInfo = abi.decode(
            encodedData,
            (removeLiquidityAVAXInfo)
        );
        address lpTokenAddr = IJoeFactory(router.factory()).getPair(
            removeInfo.tokenA,
            wavaxAddr
        );
        pullAndApprove(lpTokenAddr, account, routerAddr, removeInfo.liquidity);
        (uint256 amountToken, uint256 amountAVAX) = router.removeLiquidityAVAX(
            removeInfo.tokenA,
            removeInfo.liquidity,
            removeInfo.amountTokenMin,
            removeInfo.amountAVAXMin,
            account,
            block.timestamp
        );
        emit TraderJoeRemoveLiquidityEvent(
            removeInfo.tokenA,
            avaxAddr,
            removeInfo.liquidity,
            amountToken,
            amountAVAX,
            account
        );
    }

    /// @dev traderJoe uses the same function to deposit and claim rewards, if deposit amount is 0, you will claim your rewards
    function depositLpToken(
        address masterChefAddr,
        uint256 pid,
        uint256 amount
    ) external onlyDelegation {
        require(
            ITraderJoeAdapter(ADAPTER_ADDRESS).isTrustMasterChef(
                masterChefAddr
            ),
            "!trustMasterChef"
        );
        IMasterChefJoeV2(masterChefAddr).deposit(pid, amount);
        emit TraderJoeFarmEvent(masterChefAddr, address(this), amount, pid);
    }

    function emergencyWithdraw(address masterChefAddr, uint256 pid)
        external
        onlyDelegation
    {
        require(
            ITraderJoeAdapter(ADAPTER_ADDRESS).isTrustMasterChef(
                masterChefAddr
            ),
            "!trustMasterChef"
        );
        IMasterChefJoeV2(masterChefAddr).emergencyWithdraw(pid);
        emit TraderJoeEmergencyWithdrawEvent(
            masterChefAddr,
            address(this),
            pid
        );
    }

    function withdrawLpToken(
        address masterChefAddr,
        uint256 pid,
        uint256 amount
    ) external onlyDelegation {
        require(
            ITraderJoeAdapter(ADAPTER_ADDRESS).isTrustMasterChef(
                masterChefAddr
            ),
            "!trustMasterChef"
        );
        IMasterChefJoeV2(masterChefAddr).withdraw(pid, amount);
        emit TraderJoeUnFarmEvent(masterChefAddr, address(this), amount, pid);
    }

    struct LiquidityCustomized {
        address tokenA;
        address tokenB;
        uint256 amtAUser; // Supplied tokenA amount
        uint256 amtBUser; // Supplied tokenB amount
        uint256 amtAMin; // Desired tokenA amount (slippage control)
        uint256 amtBMin; // Desired tokenB amount (slippage control)
    }

    function addLiquidityInternal(
        address account,
        uint256 balA,
        uint256 balB,
        LiquidityCustomized memory liquidity
    ) internal returns (uint256 _amountA, uint256 _amountB) {
        (_amountA, _amountB, ) = router.addLiquidity(
            liquidity.tokenA,
            liquidity.tokenB,
            balA,
            balB,
            liquidity.amtAMin,
            liquidity.amtBMin,
            account,
            block.timestamp
        );
    }

    function addLiquidityCustomized(address account, bytes calldata encodedData)
        external
        payable
        onlyAdapterManager
    {
        LiquidityCustomized memory liquidity = abi.decode(
            encodedData,
            (LiquidityCustomized)
        );
        pullTokensIfNeeded(liquidity.tokenA, account, liquidity.amtAUser);
        pullTokensIfNeeded(liquidity.tokenB, account, liquidity.amtBUser);

        (uint256 swapAmt, uint256 swapAmtGet, bool isReversed) = autoSwap(
            liquidity
        );

        (uint256 balA, uint256 balB) = isReversed
            ? (liquidity.amtAUser + swapAmtGet, liquidity.amtBUser - swapAmt)
            : (liquidity.amtAUser - swapAmt, liquidity.amtBUser + swapAmtGet);

        approveToken(liquidity.tokenA, routerAddr, balA);
        approveToken(liquidity.tokenB, routerAddr, balB);
        (uint256 amountA, uint256 amountB) = addLiquidityInternal(
            account,
            balA,
            balB,
            liquidity
        );
        returnAsset(liquidity.tokenA, account, balA - amountA);
        returnAsset(liquidity.tokenB, account, balB - amountB);
    }

    function autoSwap(LiquidityCustomized memory liquidity)
        internal
        returns (
            uint256 swapAmt,
            uint256 swapAmtGet,
            bool isReversed
        )
    {
        uint256 resA;
        uint256 resB;
        address lp = IJoeFactory(router.factory()).getPair(
            liquidity.tokenA,
            liquidity.tokenB
        );
        if (IJoePair(lp).token0() == liquidity.tokenA) {
            (resA, resB, ) = IJoePair(lp).getReserves();
        } else {
            (resB, resA, ) = IJoePair(lp).getReserves();
        }
        (swapAmt, isReversed) = optimalDeposit(
            liquidity.amtAUser,
            liquidity.amtBUser,
            resA,
            resB
        );

        if (swapAmt > 0) {
            address[] memory path = new address[](2);
            (path[0], path[1]) = isReversed
                ? (liquidity.tokenB, liquidity.tokenA)
                : (liquidity.tokenA, liquidity.tokenB);
            approveToken(path[0], routerAddr, swapAmt);
            uint256[] memory tokenAmounts = router.swapExactTokensForTokens(
                swapAmt,
                0,
                path,
                address(this),
                block.timestamp
            );
            swapAmtGet = tokenAmounts[1];
        }
    }

    /// @dev Compute optimal deposit amount
    /// @param amtA amount of token A desired to deposit
    /// @param amtB amount of token B desired to deposit
    /// @param resA amount of token A in reserve
    /// @param resB amount of token B in reserve
    function optimalDeposit(
        uint256 amtA,
        uint256 amtB,
        uint256 resA,
        uint256 resB
    ) internal pure returns (uint256 swapAmt, bool isReversed) {
        if (amtA * resB >= amtB * resA) {
            swapAmt = _optimalDepositA(amtA, amtB, resA, resB);
            isReversed = false;
        } else {
            swapAmt = _optimalDepositA(amtB, amtA, resB, resA);
            isReversed = true;
        }
    }

    /// @dev Compute optimal deposit amount helper.
    /// @param amtA amount of token A desired to deposit
    /// @param amtB amount of token B desired to deposit
    /// @param resA amount of token A in reserve
    /// @param resB amount of token B in reserve
    /// Formula: https://blog.alphafinance.io/byot/
    function _optimalDepositA(
        uint256 amtA,
        uint256 amtB,
        uint256 resA,
        uint256 resB
    ) internal pure returns (uint256) {
        require(amtA * resB >= amtB * resA, "Reversed");
        uint256 a = 997;
        uint256 b = uint256(1997) * resA;
        uint256 _c = (amtA * resB) - (amtB * resA);
        uint256 c = ((_c * 1000) / (amtB + resB)) * resA;
        uint256 d = a * c * 4;
        uint256 e = HomoraMath.sqrt(b * b + d);
        uint256 numerator = e - b;
        uint256 denominator = a * 2;
        return numerator / denominator;
    }

    struct LiquidityFromOneToken {
        address sourceToken;
        address tokenA;
        address[] pathA;
        address tokenB;
        address[] pathB;
        uint256 amtSource;
        uint256 amtAMin; // Desired tokenA amount (slippage control)
        uint256 amtBMin; // Desired tokenB amount (slippage control)
    }

    function addLiquidityFromOneToken(
        address account,
        bytes calldata encodedData
    ) external payable onlyAdapterManager {
        LiquidityFromOneToken memory liquidity = abi.decode(
            encodedData,
            (LiquidityFromOneToken)
        );
        if (msg.value != 0 && liquidity.sourceToken == wavaxAddr) {
            IWAVAX(wavaxAddr).deposit{value: msg.value}();
            pullTokensIfNeeded(wavaxAddr, account, liquidity.amtSource);
            liquidity.amtSource += msg.value;
            approveToken(wavaxAddr, routerAddr, liquidity.amtSource);
        } else {
            pullAndApprove(
                liquidity.sourceToken,
                account,
                routerAddr,
                liquidity.amtSource
            );
        }

        (uint256 tokenAget, uint256 tokenBget) = autoSwapFromOneToken(
            liquidity
        );

        approveToken(liquidity.tokenA, routerAddr, tokenAget);
        approveToken(liquidity.tokenB, routerAddr, tokenBget);

        if (tokenAget > 0 || tokenBget > 0) {
            (uint256 amountA, uint256 amountB, ) = router.addLiquidity(
                liquidity.tokenA,
                liquidity.tokenB,
                tokenAget,
                tokenBget,
                liquidity.amtAMin,
                liquidity.amtBMin,
                account,
                block.timestamp
            );
            returnAsset(liquidity.tokenA, account, tokenAget - amountA);
            returnAsset(liquidity.tokenB, account, tokenBget - amountB);
        }
    }

    function autoSwapFromOneToken(LiquidityFromOneToken memory liquidity)
        internal
        returns (uint256 tokenAget, uint256 tokenBget)
    {
        uint256 swapAmt = liquidity.amtSource / 2;
        require(
            liquidity.pathA[0] == liquidity.sourceToken &&
                liquidity.pathB[0] == liquidity.sourceToken,
            "sourceToken error!"
        );
        uint256[] memory amountsA = router.swapExactTokensForTokens(
            swapAmt,
            0,
            liquidity.pathA,
            address(this),
            block.timestamp
        );
        tokenAget = amountsA[amountsA.length - 1];

        uint256[] memory amountsB = router.swapExactTokensForTokens(
            swapAmt,
            0,
            liquidity.pathB,
            address(this),
            block.timestamp
        );
        tokenBget = amountsB[amountsB.length - 1];
    }
}
