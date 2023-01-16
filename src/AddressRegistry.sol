// SPDX-License-Identifier: GPL-3.0-only
pragma solidity >=0.8.0;

import "solmate/tokens/ERC721.sol";

/// @title Address Registry
/// @notice Allows users to register their CID NFT
contract AddressRegistry {
    /*//////////////////////////////////////////////////////////////
                                 ADDRESSES
    //////////////////////////////////////////////////////////////*/

    /// @notice Address of the CID NFT
    address public immutable cidNFT;

    /*//////////////////////////////////////////////////////////////
                                 STATE
    //////////////////////////////////////////////////////////////*/

    /// @notice Stores the mappings of users to their CID NFTR
    mapping (address => uint) private cidNFTs;

    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/
    event CIDNFTAdded(address indexed user, uint indexed cidNFTID);
    event CIDNFTRemoved(address indexed user, uint indexed cidNFTID);


    /*//////////////////////////////////////////////////////////////
                                 ERRORS
    //////////////////////////////////////////////////////////////*/
    error NftNotOwnedByUser(uint cidNFTID, address caller);
    error NoCIDNFTRegisteredForUser(address caller);

    constructor(address _cidNFT) {
        cidNFT = _cidNFT;
    }

    function register(uint _cidNFTID) external {
        if (ERC721(cidNFT).ownerOf(_cidNFTID) != msg.sender) // ownerOf reverts if non-existing ID is provided
            revert NftNotOwnedByUser(_cidNFTID, msg.sender);
        cidNFTs[msg.sender] = _cidNFTID;
        emit CIDNFTAdded(msg.sender, _cidNFTID);
    }

    function remove() external {
        uint cidNFTID = cidNFTs[msg.sender];
        if (cidNFTID == 0)
            revert NoCIDNFTRegisteredForUser(msg.sender);
        delete cidNFTs[msg.sender];
        emit CIDNFTRemoved(msg.sender, cidNFTID);
    }

    /// @dev Returns 0 when no CID NFT is registered for the given user
    function getCID(address _user) external {
        return cidNFTs[_user];
    }

}
