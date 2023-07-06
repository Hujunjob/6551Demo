// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721BurnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721EnumerableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlEnumerableUpgradeable.sol";
import "hardhat/console.sol";

import "./ERC6551/interfaces/IERC6551Registry.sol";

contract NFT is
    ERC721EnumerableUpgradeable,
    ERC721BurnableUpgradeable,
    AccessControlEnumerableUpgradeable
{
    IERC6551Registry public erc6551Registry;
    address public accountImplementation;
    function initialize(string memory name_, string memory symbol_,address erc6551Registry_,address accountImplementation_)
        public
        initializer
    {
        __ERC721Burnable_init();
        __ERC721_init(name_, symbol_);
        __AccessControlEnumerable_init();
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        erc6551Registry = IERC6551Registry(erc6551Registry_);
        accountImplementation = accountImplementation_;
    }

    function mint() public {
        uint256 id = totalSupply() + 1;
        _safeMint(_msgSender(), id);
        bytes memory emptyBytes;
        erc6551Registry.createAccount(accountImplementation, block.chainid, address(this), id, 0, emptyBytes);
    }

    function erc6551Account(uint256 id) public view returns(address){
        return erc6551Registry.account(accountImplementation, block.chainid, address(this), id, 0);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(
            AccessControlEnumerableUpgradeable,
            ERC721Upgradeable,
            ERC721EnumerableUpgradeable
        )
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
    
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 firstTokenId,
        uint256 batchSize
    )
        internal
        virtual
        override(ERC721EnumerableUpgradeable, ERC721Upgradeable)
    {
        super._beforeTokenTransfer(from, to, firstTokenId, batchSize);
    }
}
