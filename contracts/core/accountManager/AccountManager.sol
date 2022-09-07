// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity >=0.8.0 <0.9.0;

import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "../controller/IAccount.sol";
import "../verifier/IERC2612Verifier.sol";
import "../verifier/ITokenApprovalVerifier.sol";

contract AccountManager is Ownable {
    using EnumerableSet for EnumerableSet.AddressSet;

    enum OPERATIONS {
        CREATE_SUBACCOUNT,
        EXECUTE_ON_ADAPTER,
        MULTICALL,
        SET_ADVANCED_OPTION,
        CALL_ON_SUBACCOUNT,
        WITHDRAW_ASSETS,
        APPROVE_TOKENS,
        APPROVE_ERC2612_VERIFIER,
        APPROVE_TOKEN_VERIFIER,
        LENGTH
    }
    uint256 public constant MINIMUM_DEADLINE = 1 days;
    uint256 public constant MAXIMUM_DEADLINE = 365 days;

    uint256 public min_delay;
    uint256 public max_delay;

    address public erc2612Verifier;
    address public tokenApprovalVerifier;

    EnumerableSet.AddressSet private accounts;
    mapping(address => mapping(address => bytes32)) public authorizationInfo;
    mapping(address => mapping(address => uint256)) public deadline;

    event SetDelay(uint256 min_delay, uint256 max_delay);
    event SetVerifier(address erc2612Verifier, address tokenApprovalVerifier);
    event AddAccounts(address[] accounts);
    event DelAccounts(address[] accounts);

    event SetAuthorization(
        address account,
        address executor,
        bytes32 authorization,
        uint256 deadline
    );
    event Revoke(address account, address executor);

    constructor(
        uint256 _min_delay,
        uint256 _max_delay,
        address _erc2612Verifier,
        address _tokenApprovalVerifier
    ) {
        require(
            _min_delay <= _max_delay,
            "AccountManager:Invalid delay time in constructor."
        );
        require(
            _min_delay >= MINIMUM_DEADLINE && _max_delay <= MAXIMUM_DEADLINE,
            "AccountManager:Delay time out of range in constructor."
        );
        require(
            _erc2612Verifier != address(0) &&
                _tokenApprovalVerifier != address(0),
            "AccountManager:Invalid verifier."
        );

        min_delay = _min_delay;
        max_delay = _max_delay;
        _setVerifier(_erc2612Verifier, _tokenApprovalVerifier);

        emit SetDelay(min_delay, max_delay);
        emit SetVerifier(erc2612Verifier, tokenApprovalVerifier);
    }

    function _setVerifier(
        address _erc2612Verifier,
        address _tokenApprovalVerifier
    ) internal {
        require(
            _erc2612Verifier != address(0) &&
                _tokenApprovalVerifier != address(0),
            "AccountManager:Verifier address should not be zero!"
        );
        erc2612Verifier = _erc2612Verifier;
        tokenApprovalVerifier = _tokenApprovalVerifier;
    }

    function setDelay(uint256 _min_delay, uint256 _max_delay)
        external
        onlyOwner
    {
        require(_min_delay <= _max_delay, "AccountManager:Invalid delay time.");
        require(
            _min_delay >= MINIMUM_DEADLINE && _max_delay <= MAXIMUM_DEADLINE,
            "AccountManager:Delay time out of range."
        );

        min_delay = _min_delay;
        max_delay = _max_delay;

        emit SetDelay(min_delay, max_delay);
    }

    function setVerifier(
        address _erc2612Verifier,
        address _tokenApprovalVerifier
    ) external onlyOwner {
        _setVerifier(_erc2612Verifier, _tokenApprovalVerifier);

        emit SetVerifier(erc2612Verifier, tokenApprovalVerifier);
    }

    function accountExist(address _account) public view returns (bool) {
        return accounts.contains(_account);
    }

    function addAccounts(address[] calldata _accounts) external onlyOwner {
        require(
            _accounts.length > 0,
            "AccountManager:account cannot be empty."
        );
        for (uint256 i; i < _accounts.length; i++) {
            require(
                _accounts[i] != address(0),
                "AccountManager:cannot cannot be zero."
            );
            require(
                Ownable(_accounts[i]).owner() == address(this),
                "AccountManager:Not my account."
            );
            require(
                !accountExist(_accounts[i]),
                "AccountManager:account already exists."
            );
            accounts.add(_accounts[i]);
        }
        emit AddAccounts(_accounts);
    }

    function delAccounts(address[] calldata _accounts) external onlyOwner {
        require(
            _accounts.length > 0,
            "AccountManager:account cannot be empty."
        );
        for (uint256 i; i < _accounts.length; i++) {
            require(
                _accounts[i] != address(0),
                "AccountManager:account cannot be empty."
            );
            require(
                accountExist(_accounts[i]),
                "AccountManager:account does not exist."
            );
            Ownable(_accounts[i]).transferOwnership(owner());
            accounts.remove(_accounts[i]);
        }
        emit DelAccounts(_accounts);
    }

    function getAccountsLength() external view returns (uint256) {
        return accounts.length();
    }

    function getAccount(uint256 i) external view returns (address) {
        return accounts.at(i);
    }

    function setAuthorization(
        address _account,
        address _executor,
        bytes32 _authorization,
        uint256 _deadline
    ) external onlyOwner {
        require(
            accountExist(_account),
            "AccountManager:Account is out of control."
        );
        require(
            uint256(_authorization) < (1 << uint256(OPERATIONS.LENGTH)),
            "AccountManager:Invalid operation bytes."
        );
        if (_deadline != 0) {
            require(
                _deadline >= block.timestamp + min_delay &&
                    _deadline <= block.timestamp + max_delay,
                "AccountManager:Set time out of range."
            );
        }
        authorizationInfo[_account][_executor] = _authorization;
        deadline[_account][_executor] = _deadline;
        emit SetAuthorization(_account, _executor, _authorization, _deadline);
    }

    function revoke(address _account, address _executor) external onlyOwner {
        require(
            authorizationInfo[_account][_executor] != bytes32(0) &&
                deadline[_account][_executor] >= block.timestamp,
            "AccountManager:The executor does not have permission."
        );
        authorizationInfo[_account][_executor] = bytes32(0);
        deadline[_account][_executor] = 0;

        emit Revoke(_account, _executor);
    }

    function authorizationCheck(address _account, OPERATIONS _operationIndex)
        public
        view
    {
        require(
            accountExist(_account),
            "AccountManager:Account is out of control."
        );
        uint256 types = uint256(authorizationInfo[_account][msg.sender]);
        require(
            (types >> uint256(_operationIndex)) & uint256(1) == uint256(1),
            "AccountManager:Operation: not allowed."
        );
        require(
            deadline[_account][msg.sender] >= block.timestamp,
            "AccountManager:Operation: authorization expires."
        );
    }

    function createSubAccount(
        address _account,
        bytes calldata _callBytes,
        uint256 _costETH
    ) external {
        authorizationCheck(_account, OPERATIONS.CREATE_SUBACCOUNT);
        IAccount(_account).createSubAccount(_callBytes, _costETH);
    }

    function executeOnAdapter(
        address _account,
        bytes calldata _callBytes,
        bool _callType
    ) external {
        authorizationCheck(_account, OPERATIONS.EXECUTE_ON_ADAPTER);
        IAccount(_account).executeOnAdapter(_callBytes, _callType);
    }

    function executeMultiCall(
        address _account,
        bool[] calldata _callType,
        bytes[] calldata _callBytes,
        bool[] calldata _isNeedCallback
    ) external {
        authorizationCheck(_account, OPERATIONS.MULTICALL);
        IAccount(_account).multiCall(_callType, _callBytes, _isNeedCallback);
    }

    function setAdvancedOption(address _account, bool _val) external {
        authorizationCheck(_account, OPERATIONS.SET_ADVANCED_OPTION);
        IAccount(_account).setAdvancedOption(_val);
    }

    function callOnSubAccount(
        address _account,
        address _target,
        bytes calldata _callArgs,
        uint256 _amountETH
    ) external {
        authorizationCheck(_account, OPERATIONS.CALL_ON_SUBACCOUNT);
        IAccount(_account).callOnSubAccount(_target, _callArgs, _amountETH);
    }

    function withdrawAssets(
        address _account,
        address[] calldata _tokens,
        address _receiver,
        uint256[] calldata _amounts
    ) external {
        authorizationCheck(_account, OPERATIONS.WITHDRAW_ASSETS);
        require(
            _receiver == owner() || IAccount(_account).isSubAccount(_receiver),
            "AccountManager:Invalid receiver."
        );
        IAccount(_account).withdrawAssets(_tokens, _receiver, _amounts);
    }

    function approveTokens(
        address _account,
        address[] calldata _tokens,
        address[] calldata _spenders,
        uint256[] calldata _amounts
    ) external {
        authorizationCheck(_account, OPERATIONS.APPROVE_TOKENS);
        IAccount(_account).approveTokens(_tokens, _spenders, _amounts);
    }

    function approveERC2612Verifier(
        address _account,
        address _operator,
        bytes32 _approvalType,
        uint256 _deadline
    ) external {
        authorizationCheck(_account, OPERATIONS.APPROVE_ERC2612_VERIFIER);
        IERC2612Verifier(erc2612Verifier).approve(
            _account,
            _operator,
            _approvalType,
            _deadline
        );
    }

    function approveTokenApprovalVerifier(
        address _account,
        address[] memory _spenders,
        bool _enable,
        uint256 _deadline
    ) external {
        authorizationCheck(_account, OPERATIONS.APPROVE_TOKEN_VERIFIER);
        ITokenApprovalVerifier(tokenApprovalVerifier).approve(
            _account,
            _spenders,
            _enable,
            _deadline
        );
    }
}
