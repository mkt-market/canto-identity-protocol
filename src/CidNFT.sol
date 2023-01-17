// SPDX-License-Identifier: GPL-3.0-only
pragma solidity >=0.8.0;

import "solmate/tokens/ERC721.sol";
import "solmate/tokens/ERC20.sol";
import "solmate/utils/SafeTransferLib.sol";
import "./SubprotocolRegistry.sol";

/// @title Canto Identity Protocol NFT
/// @notice CID NFTs are at the heart of the CID protocol. All key/values of subprotocols are associated with them.
contract CidNFT is ERC721 {
    /*//////////////////////////////////////////////////////////////
                                 CONSTANTS
    //////////////////////////////////////////////////////////////*/
    /// @notice Fee (in BPS) that is charged for every mint (as a percentage of the mint fee). Fixed at 10%.
    uint public constant cidFeeBps = 1_000;


    /*//////////////////////////////////////////////////////////////
                                 ADDRESSES
    //////////////////////////////////////////////////////////////*/

    /// @notice Wallet that receives CID fees
    address public immutable cidFeeWallet;

    /// @notice Reference to the NOTE TOKEN
    ERC20 public immutable note;

    /// @notice Base URI of the NFT
    string public baseURI;

    /// @notice Reference to the subprotocol registry
    SubprotocolRegistry immutable subprotocolRegistry;

    /*//////////////////////////////////////////////////////////////
                                 STATE
    //////////////////////////////////////////////////////////////*/

    /// @notice The different types of value that can be added for a given key 
    enum ValueType {
        ORDERED,
        PRIMARY,
        ACTIVE
    }
    
    /// @notice Counter of the minted NFTs
    /// @dev Used to assign a new unique ID. The first ID that is assigned is 1, ID 0 is never minted.
    uint public numMinted;

    mapping (uint => mapping(string => mapping(uint => uint))) public CIDDataOrdered;

    mapping (uint => mapping(string => mapping(string => uint))) public CIDDataPrimary;

    mapping (uint => mapping(string => mapping(string => uint[]))) public CIDDataActive;

    /*//////////////////////////////////////////////////////////////
                                 ERRORS
    //////////////////////////////////////////////////////////////*/

    error TokenNotMinted();
    error SubprotocolDoesNotExist(string subprotocolName);
    error ValueTypeNotSupportedForSubprotocol(ValueType valueType, string subprotocolName);
    error NotAuthorizedForCIDNFT(address caller, uint cidNFTID);

    /// @notice Sets the name, symbol, baseURI, and the address of the auction factory
    /// @param _name Name of the NFT
    /// @param _symbol Symbol of the NFT
    /// @param _baseURI NFT base URI. {id}.json is appended to this URI
    /// @param _cidFeeWallet Address of the wallet that receives the fees
    /// @param _noteContract Address of the NOTE contract
    /// @param _subprotocolRegistry Address of the subprotocol registry
    constructor(
        string memory _name,
        string memory _symbol,
        string memory _baseURI,
        address _cidFeeWallet,
        address _noteContract,
        address _subprotocolRegistry
    ) ERC721(_name, _symbol) {
        baseURI = _baseURI;
        cidFeeWallet = _cidFeeWallet;
        note = ERC20(_noteContract);
        subprotocolRegistry = SubprotocolRegistry(_subprotocolRegistry);
    }

    /// @notice Get the token URI for the provided ID
    /// @param _id ID to retrieve the URI for
    function tokenURI(uint256 _id)
        public
        view
        override
        returns (string memory)
    {
        if (ownerOf[_id] == address(0))
            // According to ERC721, this revert for non-existing tokens is required
            revert TokenNotMinted();
        return string(abi.encodePacked(baseURI, _id, ".json"));
    }

    function mint(bytes[] calldata _addList) external {
        _mint(msg.sender, ++numMinted);
        if (_addList.length != 0) {
            // TODO: call add with the provided calldata
        }
    }

    /// @param _key Key to set. This value is only relevant for the ValueType PRIMARY or ACTIVE (with strings as keys)
    /// @param _keyID ID (integer key) to set. This value is only relevant for the ValueType ORDERED (with integers as keys)
    /// @param _nftIDToAdd The ID of the NFT to add.
    function add(uint _cidNftID, string calldata _key, uint _keyID, string calldata _subprotocolName, uint _nftIDToAdd, ValueType _type) external {
        SubprotocolRegistry.SubprotocolData memory subprotocolData = subprotocolRegistry.getSubprotocol(_subprotocolName);
        address subprotocolOwner = subprotocolData.owner;
        if (subprotocolOwner == address(0))
            revert SubprotocolDoesNotExist(_subprotocolName);
        if (ownerOf[_cidNftID] != msg.sender) // TODO: Should delegated users be allowed to add?
            revert NotAuthorizedForCIDNFT(msg.sender, _cidNftID);
        // Charge fee (subprotocol & CID fee) if configured
        uint96 subprotocolFee = subprotocolData.fee;
        if (subprotocolFee != 0) {
            uint cidFee = subprotocolFee * cidFeeBps / 10_000;
            SafeTransferLib.safeTransferFrom(note, msg.sender, cidFeeWallet, cidFee);
            SafeTransferLib.safeTransferFrom(note, msg.sender, subprotocolOwner, subprotocolFee - cidFee);
        }
        if (_type == ValueType.ORDERED) {
            if (!subprotocolData.ordered)
                revert ValueTypeNotSupportedForSubprotocol(_type, _subprotocolName);
            
            CIDDataOrdered[_cidNftID][_subprotocolName][_keyID] = _nftIDToAdd; // TODO: Disallow adding 0? Would need to be a disallowed ID in identity subprotocols
        } else if (_type == ValueType.PRIMARY) {
            if (!subprotocolData.primary)
                revert ValueTypeNotSupportedForSubprotocol(_type, _subprotocolName);
            
            CIDDataPrimary[_cidNftID][_subprotocolName][_key] = _nftIDToAdd;
        } else if (_type == ValueType.ACTIVE) {
            if (!subprotocolData.active)
                revert ValueTypeNotSupportedForSubprotocol(_type, _subprotocolName);

            if (CIDDataActive[_cidNftID][_subprotocolName][_key].length == 0) {
                uint[] memory nftIDs = new uint[](1);
                nftIDs[0] = _nftIDToAdd;
                CIDDataActive[_cidNftID][_subprotocolName][_key] = nftIDs;
            } else {
                // In theory, this could introduce duplicates or result in a very large array (causing out of gas)
                CIDDataActive[_cidNftID][_subprotocolName][_key].push(_nftIDToAdd);
            }
        }
    }
}
