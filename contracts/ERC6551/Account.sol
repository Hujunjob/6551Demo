// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/interfaces/IERC1271.sol";
import "@openzeppelin/contracts/utils/cryptography/SignatureChecker.sol";
import "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155Receiver.sol";

import "hardhat/console.sol";
import "./lib/MinimalReceiver.sol";
import "./interfaces/IAccount.sol";
import "./lib/MinimalProxyStore.sol";

/**
 * @title A smart contract wallet owned by a single ERC721 token
 * @author Jayden Windle (jaydenwindle)
 */
contract Account is IERC165, IERC1271, IAccount, MinimalReceiver {
    error NotAuthorized();
    error AccountLocked();
    error ExceedsMaxLockTime();

    /**
     * @dev Timestamp at which Account will unlock
     */
    uint256 public unlockTimestamp;

    /**
     * @dev Mapping from owner address to executor address
     */
    mapping(address => address) public executor;

    /**
     * @dev Emitted whenever the lock status of a account is updated
     */
    event LockUpdated(uint256 timestamp);

    /**
     * @dev Emitted whenever the executor for a account is updated
     */
    event ExecutorUpdated(address owner, address executor);

    constructor() {}

    /**
     * @dev Ensures execution can only continue if the account is not locked
     */
    modifier onlyUnlocked() {
        if (unlockTimestamp > block.timestamp) revert AccountLocked();
        _;
    }

    /**
     * @dev If account is unlocked and an executor is set, pass call to executor
     */
    fallback(bytes calldata data)
        external
        payable
        onlyUnlocked
        returns (bytes memory result)
    {
        address _owner = owner();
        address _executor = executor[_owner];

        // accept funds if executor is undefined or cannot be called
        if (_executor.code.length == 0) return "";

        return _call(_executor, 0, data);
    }

    /**
     * @dev Executes a transaction from the Account. Must be called by an account owner.
     *
     * @param to      Destination address of the transaction
     * @param value   Ether value of the transaction
     * @param data    Encoded payload of the transaction
     */
    function executeCall(
        address to,
        uint256 value,
        bytes calldata data
    ) external override payable onlyUnlocked returns (bytes memory result) {
        console.log("executeCall to %s",to);
        address _owner = owner();
        if (msg.sender != _owner) revert NotAuthorized();

        return _call(to, value, data);
    }

    /**
     * @dev Executes a transaction from the Account. Must be called by an authorized executor.
     *
     * @param to      Destination address of the transaction
     * @param value   Ether value of the transaction
     * @param data    Encoded payload of the transaction
     */
    function executeTrustedCall(
        address to,
        uint256 value,
        bytes calldata data
    ) external payable onlyUnlocked returns (bytes memory result) {
        address _executor = executor[owner()];
        if (msg.sender != _executor) revert NotAuthorized();

        return _call(to, value, data);
    }

    function getCode() public view returns(bytes memory){
        return address(this).code;
    }

    /**
     * @dev Executes a transaction from the Account. Must be called by a trusted cross-chain executor.
     * Can only be called if account is owned by a token on another chain.
     *
     * @param to      Destination address of the transaction
     * @param value   Ether value of the transaction
     * @param data    Encoded payload of the transaction
     */
    // function executeCrossChainCall(
    //     address to,
    //     uint256 value,
    //     bytes calldata data
    // ) external payable onlyUnlocked returns (bytes memory result) {
    //     (uint256 chainId, , ) = context();

    //     if (chainId == block.chainid) {
    //         revert NotAuthorized();
    //     }

    //     if (!crossChainExecutorList.isCrossChainExecutor(chainId, msg.sender)) {
    //         revert NotAuthorized();
    //     }

    //     return _call(to, value, data);
    // }

    /**
     * @dev Sets executor address for Account, allowing owner to use a custom implementation if they choose to.
     * When the token controlling the account is transferred, the implementation address will reset
     *
     * @param _executionModule the address of the execution module
     */
    function setExecutor(address _executionModule) external onlyUnlocked {
        address _owner = owner();
        if (_owner != msg.sender) revert NotAuthorized();

        executor[_owner] = _executionModule;

        emit ExecutorUpdated(_owner, _executionModule);
    }

    /**
     * @dev Locks Account, preventing transactions from being executed until a certain time
     *
     * @param _unlockTimestamp timestamp when the account will become unlocked
     */
    function lock(uint256 _unlockTimestamp) external onlyUnlocked {
        if (_unlockTimestamp > block.timestamp + 365 days)
            revert ExceedsMaxLockTime();

        address _owner = owner();
        if (_owner != msg.sender) revert NotAuthorized();

        unlockTimestamp = _unlockTimestamp;

        emit LockUpdated(_unlockTimestamp);
    }

    /**
     * @dev Returns Account lock status
     *
     * @return true if Account is locked, false otherwise
     */
    function isLocked() external view returns (bool) {
        return unlockTimestamp > block.timestamp;
    }

    /**
     * @dev Returns true if caller is authorized to execute actions on this account
     *
     * @param caller the address to query authorization for
     * @return true if caller is authorized, false otherwise
     */
    // function isAuthorized(address caller) external view returns (bool) {
    //     (uint256 chainId, address tokenCollection, uint256 tokenId) = context();

    //     if (chainId != block.chainid) {
    //         return crossChainExecutorList.isCrossChainExecutor(chainId, caller);
    //     }

    //     address _owner = IERC721(tokenCollection).ownerOf(tokenId);
    //     if (caller == _owner) return true;

    //     address _executor = executor[_owner];
    //     if (caller == _executor) return true;

    //     return false;
    // }

    /**
     * @dev Implements EIP-1271 signature validation
     *
     * @param hash      Hash of the signed data
     * @param signature Signature to validate
     */
    function isValidSignature(bytes32 hash, bytes memory signature)
        external
        view
        override
        returns (bytes4 magicValue)
    {
        // If account is locked, disable signing
        if (unlockTimestamp > block.timestamp) return "";

        // If account has an executor, check if executor signature is valid
        address _owner = owner();
        address _executor = executor[_owner];

        if (
            _executor != address(0) &&
            SignatureChecker.isValidSignatureNow(_executor, hash, signature)
        ) {
            return IERC1271.isValidSignature.selector;
        }

        // Default - check if signature is valid for account owner
        if (SignatureChecker.isValidSignatureNow(_owner, hash, signature)) {
            return IERC1271.isValidSignature.selector;
        }

        return "";
    }

    /**
     * @dev Implements EIP-165 standard interface detection
     *
     * @param interfaceId the interfaceId to check support for
     * @return true if the interface is supported, false otherwise
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(IERC165, ERC1155Receiver)
        returns (bool)
    {
        // default interface support
        if (
            interfaceId == type(IAccount).interfaceId ||
            interfaceId == type(IERC1155Receiver).interfaceId ||
            interfaceId == type(IERC165).interfaceId
        ) {
            return true;
        }

        address _executor = executor[owner()];

        if (_executor == address(0) || _executor.code.length == 0) {
            return false;
        }

        // if interface is not supported by default, check executor
        try IERC165(_executor).supportsInterface(interfaceId) returns (
            bool _supportsInterface
        ) {
            return _supportsInterface;
        } catch {
            return false;
        }
    }

    /**
     * @dev Returns the owner of the token that controls this Account (public for Ownable compatibility)
     *
     * @return the address of the Account owner
     */
    function owner() public view override returns (address) {
        (uint256 salt, uint256 chainId, address tokenCollection, uint256 tokenId) = context();
        console.log("owner chainid:%s,nft:%s,tokenid:%s",chainId,tokenCollection,tokenId);
        if (chainId != block.chainid) {
            return address(0);
        }

        return IERC721(tokenCollection).ownerOf(tokenId);
    }

    /**
     * @dev Returns information about the token that owns this account
     *
     * @return tokenCollection the contract address of the  ERC721 token which owns this account
     * @return tokenId the tokenId of the  ERC721 token which owns this account
     */
    function token()
        public
        view
        override
        returns (address tokenCollection, uint256 tokenId)
    {
        (,, tokenCollection, tokenId) = context();
    }

    function context()
        internal
        view
        returns (
            uint256,
            uint256,
            address,
            uint256
        )
    {
        bytes memory rawContext = MinimalProxyStore.getContext(address(this));
        
        if (rawContext.length == 0) return (0,0, address(0), 0);
        bytes1 zeroByte = 0x00;
        bytes memory data =  abi.encodePacked(zeroByte, rawContext);
        // console.log("context length:%s,code: %s",data.length, toHexString(data));
        return abi.decode(data, (uint256,uint256, address, uint256));
    }

    function toHexString(bytes memory data) public pure returns (string memory) {
        bytes memory alphabet = "0123456789abcdef";

        bytes memory str = new bytes(2 + data.length * 2);
        str[0] = "0";
        str[1] = "x";
        for (uint i = 0; i < data.length; i++) {
            str[2+i*2] = alphabet[uint(uint8(data[i] >> 4))];
            str[3+i*2] = alphabet[uint(uint8(data[i] & 0x0f))];
        }
        return string(str);
    }

    /**
     * @dev Executes a low-level call
     */
    function _call(
        address to,
        uint256 value,
        bytes calldata data
    ) internal returns (bytes memory result) {
        bool success;
        (success, result) = to.call{value: value}(data);

        if (!success) {
            assembly {
                revert(add(result, 32), mload(result))
            }
        }
    }
}