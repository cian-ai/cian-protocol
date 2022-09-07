// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity >=0.8.0 <0.9.0;

import "../base/AdapterBase.sol";
import "./VerifierBasic.sol";
import "../../interfaces/benqi/ISAVAX.sol";
import "../../core/controller/IAccount.sol";

/*
Users deposit some savax as gas fee to support automatic contract calls in the background
*/
contract Verifier is VerifierBasic {
    function getMessageHash(
        address _account,
        address _token,
        uint256 _amount,
        bool _access,
        uint256 _deadline,
        uint256 _nonce
    ) public pure returns (bytes32) {
        return
            keccak256(
                abi.encodePacked(
                    _account,
                    _token,
                    _amount,
                    _access,
                    _deadline,
                    _nonce
                )
            );
    }

    function verify(
        address _signer,
        address _account,
        address _token,
        uint256 _amount,
        bool _access,
        uint256 _deadline,
        bytes memory signature
    ) internal returns (bool) {
        require(_deadline >= block.timestamp, "Signature expired");
        bytes32 messageHash = getMessageHash(
            _account,
            _token,
            _amount,
            _access,
            _deadline,
            nonces[_account]++
        );
        bytes32 ethSignedMessageHash = getEthSignedMessageHash(messageHash);

        return recoverSigner(ethSignedMessageHash, signature) == _signer;
    }
}

contract FeeBoxSAVAX is Verifier, AdapterBase {
    using SafeERC20 for IERC20;

    event FeeBoxSAVAXDeposit(
        address account,
        uint256 amount,
        uint256 consumedAmount
    );
    event FeeBoxSAVAXWithdraw(
        address account,
        uint256 amount,
        uint256 consumedAmount
    );

    address public balanceController;
    address public feeReceiver;
    address public constant sAVAX = 0x2b2C81e08f1Af8835a78Bb2A90AE924ACE0eA4bE;

    mapping(address => uint256) public tokenBalance;

    event Initialize(address _balanceController, address _feeReceiver);
    event SetAdapterManager(address newAdapterManager);

    constructor(address _adapterManager, address _timelock)
        AdapterBase(_adapterManager, _timelock, "feeBoxSAVAX")
    {}

    function initialize(address _balanceController, address _feeReceiver)
        external
        onlyTimelock
    {
        balanceController = _balanceController;
        feeReceiver = _feeReceiver;
        emit Initialize(balanceController, feeReceiver);
    }

    function setAdapterManager(address newAdapterManger) external onlyTimelock {
        ADAPTER_MANAGER = newAdapterManger;
        emit SetAdapterManager(ADAPTER_MANAGER);
    }

    modifier onlySigner() {
        require(balanceController == msg.sender, "!Signer");
        _;
    }

    function setBalance(address[] memory users, uint256[] memory balance)
        external
        onlySigner
    {
        require(users.length == balance.length, "length error!");
        for (uint256 i = 0; i < users.length; i++) {
            tokenBalance[users[i]] = balance[i];
        }
    }

    function _paymentCheck(address account, uint256 consumedAmount) internal {
        if (consumedAmount != 0) {
            require(tokenBalance[account] >= consumedAmount, "Insolvent!");
            ISAVAX(sAVAX).transfer(feeReceiver, consumedAmount);
            tokenBalance[account] -= consumedAmount;
        }
    }

    function paymentCheck(address account, uint256 consumedAmount)
        external
        onlySigner
    {
        _paymentCheck(account, consumedAmount);
    }

    function depositWithPermit(address account, bytes calldata encodedData)
        external
        onlyAdapterManager
    {
        require(tx.origin == IAccount(account).owner(), "!EOA");
        (
            uint256 amount,
            uint256 consumedAmount,
            bool access,
            uint256 deadline,
            bytes memory signature
        ) = abi.decode(encodedData, (uint256, uint256, bool, uint256, bytes));
        require(access, "Not deposit method.");
        require(
            verify(
                balanceController,
                account,
                sAVAX,
                consumedAmount,
                access,
                deadline,
                signature
            ),
            "Verify failed!"
        );

        pullTokensIfNeeded(sAVAX, account, amount);
        tokenBalance[account] += amount;
        _paymentCheck(account, consumedAmount);
        emit FeeBoxSAVAXDeposit(account, amount, consumedAmount);
    }

    function withdrawWithPermit(address account, bytes calldata encodedData)
        external
        onlyAdapterManager
    {
        (
            uint256 amount,
            uint256 consumedAmount,
            bool access,
            uint256 deadline,
            bytes memory signature
        ) = abi.decode(encodedData, (uint256, uint256, bool, uint256, bytes));
        require(!access, "Not withdraw method.");
        require(
            verify(
                balanceController,
                account,
                sAVAX,
                consumedAmount,
                access,
                deadline,
                signature
            ),
            "Verify failed!"
        );

        require(tokenBalance[account] >= amount, "Insolvent!");
        tokenBalance[account] -= amount;
        _paymentCheck(account, consumedAmount);
        IERC20(sAVAX).safeTransfer(account, amount);
        emit FeeBoxSAVAXWithdraw(account, amount, consumedAmount);
    }
}
