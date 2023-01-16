// SPDX-License-Identifier: GPL-3.0-only
pragma solidity >=0.8.0;

import "solmate/tokens/ERC721.sol";
import "SubprotocolRegistry.sol";

/// @title Canto Identity Protocol NFT
/// @notice CID NFTs are at the heart of the CID protocol. All key/values of subprotocols are associated with them.
contract CidNFT is ERC721 {
    /*//////////////////////////////////////////////////////////////
                                 CONSTANTS
    //////////////////////////////////////////////////////////////*/
    /// @notice Fee (in BPS) that is charged for every mint (as a percentage of the mint fee). Fixed at 10%.
    uint public constant cidFee = 1_000;


    /*//////////////////////////////////////////////////////////////
                                 ADDRESSES
    //////////////////////////////////////////////////////////////*/

    /// @notice Wallet that receives CID fees
    address public immutable cidFeeWallet;

    /// @notice NOTE contract address
    address public immutable noteContract;

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

    mapping (uint => mapping(uint => uint)) public CIDDataOrdered;

    mapping (uint => mapping(string => uint)) public CIDDataPrimary;

    mapping (uint => mapping(string => uint[])) public CIDDataActive;

    /*//////////////////////////////////////////////////////////////
                                 ERRORS
    //////////////////////////////////////////////////////////////*/

    error TokenNotMinted();
    error SubprotocolDoesNotExist(string subprotocolName);
    error InvalidValueTypeLengthCombination(ValueType valueType, uint nftIDsLength);

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
        noteContract = _noteContract;
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
    /// @param _nftIDsToAdd The IDs of the NFTs to add. For type PRIMARY or ORDERED, one value must be provided. For type ACTIVE, multiple values can be provided
    function add(uint _cidNftID, string _key, uint _keyID, string _subprotocolName, uint[] calldata _nftIDsToAdd, ValueType _type) external {
        SubprotocolData memory subprotocolData = subprotocolRegistry.subprotocols(_subprotocolName);
        if (subprotocolData.owner == address(0))
            revert SubprotocolDoesNotExist(_subprotocolName);
        if (((_type == ValueType.PRIMARY || _type == ValueType.ORDERED) && _nftIDsToAdd.length != 1) || 
            (_type == ValueType.ACTIVE && _nftIDsToAdd.length == 0))
            revert InvalidValueTypeLengthCombination(_type, _nftIDsToAdd.length);
    }
}
