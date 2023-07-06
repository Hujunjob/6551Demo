// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721BurnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721EnumerableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlEnumerableUpgradeable.sol";
import "hardhat/console.sol";

contract NFT2 is
    ERC721EnumerableUpgradeable,
    ERC721BurnableUpgradeable,
    AccessControlEnumerableUpgradeable
{
    function initialize(string memory name_, string memory symbol_)
        public
        initializer
    {
        __ERC721Burnable_init();
        __ERC721_init(name_, symbol_);
        __AccessControlEnumerable_init();
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
    }

    function mint() public {
        uint256 id = totalSupply() + 1;
        _safeMint(_msgSender(), id);
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
        //can't transfer
        // if (!transferable) {
        //     if (from == address(0) || to == address(0)) {} else {
        //         revert("Player is not transferable.");
        //     }
        // }
    }
}
