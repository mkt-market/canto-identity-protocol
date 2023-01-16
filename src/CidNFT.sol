// SPDX-License-Identifier: GPL-3.0-only
pragma solidity >=0.8.0;

import "solmate/tokens/ERC721.sol";

/// @title Canto Identity Protocol NFT
/// @notice CID NFTs are at the heart of the CID protocol. All key/values of subprotocols are associated with them.
contract CidNFT is ERC721 {
    /*//////////////////////////////////////////////////////////////
                                 ADDRESSES
    //////////////////////////////////////////////////////////////*/

    /// @notice Wallet that receives CID fees
    address public immutable cidFeeWallet;

    /// @notice Base URI of the NFT
    string public immutable baseURI;

    /*//////////////////////////////////////////////////////////////
                                 ERRORS
    //////////////////////////////////////////////////////////////*/

    error OnlyFactoryCanMint();
    error TokenNotMinted();

    /// @notice Sets the name, symbol, baseURI, and the address of the auction factory
    /// @param _name Name of the NFT
    /// @param _symbol Symbol of the NFT
    /// @param _baseURI NFT base URI. {id}.json is appended to this URI
    /// @param _cidFeeWallet Address of the wallet that receives the fees
    constructor(
        string memory _name,
        string memory _symbol,
        string memory _baseURI,
        address _factory,
        address _cidFeeWallet
    ) ERC721(_name, _symbol) {
        baseURI = _baseURI;
    }

    /// @notice Get the token URI for the provided ID
    /// @param _id ID to retrieve the URI for
    function tokenURI(uint256 _id)
        public
        view
        override
        returns (string memory)
    {
        if (_ownerOf[_id] == address(0))
            // According to ERC721, this revert for non-existing tokens is required
            revert TokenNotMinted();
        return string(abi.encodePacked(baseURI, _id, ".json"));
    }
}
