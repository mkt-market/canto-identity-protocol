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
    uint256 public constant cidFeeBps = 1_000;

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

    /// @notice Array of uint256 values (NFT IDs) with additional position information NFT ID => (array pos. + 1)
    struct IndexedArray {
        uint256[] values;
        mapping(uint256 => uint256) positions;
    }

    /// @notice The different types of value that can be added for a given key
    enum ValueType {
        ORDERED,
        PRIMARY,
        ACTIVE
    }

    /// @notice Counter of the minted NFTs
    /// @dev Used to assign a new unique ID. The first ID that is assigned is 1, ID 0 is never minted.
    uint256 public numMinted;

    // TODO: Getters
    mapping(uint256 => mapping(string => mapping(uint256 => uint256))) internal CIDDataOrdered;

    mapping(uint256 => mapping(string => mapping(string => uint256))) internal CIDDataPrimary;

    mapping(uint256 => mapping(string => mapping(string => IndexedArray))) internal CIDDataActive;

    /*//////////////////////////////////////////////////////////////
                                 ERRORS
    //////////////////////////////////////////////////////////////*/

    error TokenNotMinted(uint256 tokenID);
    error AddCallAfterMintingFailed(uint256 index);
    error SubprotocolDoesNotExist(string subprotocolName);
    error ValueTypeNotSupportedForSubprotocol(ValueType valueType, string subprotocolName);
    error NotAuthorizedForCIDNFT(address caller, uint256 cidNFTID);
    error NotAuthorizedForSubprotocolNFT(address caller, uint256 subprotocolNFTID);
    error ActiveArrayAlreadyContainsID(uint256 cidNFTID, string subprotocolName, string key, uint256 NFTIDToAdd);
    error OrderedValueNotSet(uint256 cidNFTID, string subprotocolName, uint256 keyID);
    error PrimaryValueNotSet(uint256 cidNFTID, string subprotocolName, string key);
    error ActiveArrayDoesNotContainID(uint256 cidNFTID, string subprotocolName, string key, uint256 NFTIDToRemove);

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
    function tokenURI(uint256 _id) public view override returns (string memory) {
        if (ownerOf[_id] == address(0))
            // According to ERC721, this revert for non-existing tokens is required
            revert TokenNotMinted(_id);
        return string(abi.encodePacked(baseURI, _id, ".json"));
    }

    /// @param _addList An optional list of encoded parameters for add to add subprotocol NFTs directly after minting.
    /// The parameters should not include the function selector itself, the function select for add is always prepended.
    function mint(bytes[] calldata _addList) external {
        _mint(msg.sender, ++numMinted);
        bytes4 addSelector = this.add.selector;
        for (uint256 i = 0; i < _addList.length; ++i) {
            (
                bool success, /*bytes memory result*/

            ) = address(this).delegatecall(abi.encodePacked(addSelector, _addList[i]));
            if (!success) revert AddCallAfterMintingFailed(i);
        }
    }

    /// @param _key Key to set. This value is only relevant for the ValueType PRIMARY or ACTIVE (with strings as keys)
    /// @param _keyID ID (integer key) to set. This value is only relevant for the ValueType ORDERED (with integers as keys)
    /// @param _nftIDToAdd The ID of the NFT to add.
    function add(
        uint256 _cidNFTID,
        string calldata _key,
        uint256 _keyID,
        string calldata _subprotocolName,
        uint256 _nftIDToAdd,
        ValueType _type
    ) external {
        SubprotocolRegistry.SubprotocolData memory subprotocolData = subprotocolRegistry.getSubprotocol(
            _subprotocolName
        );
        address subprotocolOwner = subprotocolData.owner;
        if (subprotocolOwner == address(0)) revert SubprotocolDoesNotExist(_subprotocolName);
        if (ownerOf[_cidNFTID] != msg.sender)
            // TODO: Should delegated users be allowed to add?
            revert NotAuthorizedForCIDNFT(msg.sender, _cidNFTID);
        // The CID Protocol safeguards the NFTs of subprotocols. Note that these NFTs are usually pointers to other data / NFTs (e.g., to an image NFT for profile pictures)
        ERC721 nftToAdd = ERC721(subprotocolData.nftAddress);
        nftToAdd.safeTransferFrom(msg.sender, address(this), _cidNFTID);
        // Charge fee (subprotocol & CID fee) if configured
        uint96 subprotocolFee = subprotocolData.fee;
        if (subprotocolFee != 0) {
            uint256 cidFee = (subprotocolFee * cidFeeBps) / 10_000;
            SafeTransferLib.safeTransferFrom(note, msg.sender, cidFeeWallet, cidFee);
            SafeTransferLib.safeTransferFrom(note, msg.sender, subprotocolOwner, subprotocolFee - cidFee);
        }
        if (_type == ValueType.ORDERED) {
            if (!subprotocolData.ordered) revert ValueTypeNotSupportedForSubprotocol(_type, _subprotocolName);

            CIDDataOrdered[_cidNFTID][_subprotocolName][_keyID] = _nftIDToAdd; // TODO: Disallow adding 0? Would need to be a disallowed ID in identity subprotocols
        } else if (_type == ValueType.PRIMARY) {
            if (!subprotocolData.primary) revert ValueTypeNotSupportedForSubprotocol(_type, _subprotocolName);

            CIDDataPrimary[_cidNFTID][_subprotocolName][_key] = _nftIDToAdd;
        } else if (_type == ValueType.ACTIVE) {
            if (!subprotocolData.active) revert ValueTypeNotSupportedForSubprotocol(_type, _subprotocolName);
            IndexedArray storage keyData = CIDDataActive[_cidNFTID][_subprotocolName][_key];
            uint256 lengthBeforeAddition = keyData.values.length;
            if (lengthBeforeAddition == 0) {
                uint256[] memory nftIDsToAdd = new uint256[](1);
                nftIDsToAdd[0] = _nftIDToAdd;
                keyData.values = nftIDsToAdd; // TODO: Emit events
                keyData.positions[_nftIDToAdd] = 1; // Array index + 1
            } else {
                // Check for duplicates
                if (keyData.positions[_nftIDToAdd] != 0)
                    revert ActiveArrayAlreadyContainsID(_cidNFTID, _subprotocolName, _key, _nftIDToAdd);
                keyData.values.push(_nftIDToAdd);
                keyData.positions[_nftIDToAdd] = lengthBeforeAddition + 1;
            }
        }
    }

    /// @param _key Key to set. This value is only relevant for the ValueType PRIMARY or ACTIVE (with strings as keys)
    /// @param _keyID ID (integer key) to set. This value is only relevant for the ValueType ORDERED (with integers as keys)
    /// @param _nftIDToRemove The ID of the NFT to remove. Only needed for type ACTIVE, as the key is sufficent, otherwise
    function remove(
        uint256 _cidNFTID,
        string calldata _key,
        uint256 _keyID,
        string calldata _subprotocolName,
        uint256 _nftIDToRemove,
        ValueType _type
    ) external {
        SubprotocolRegistry.SubprotocolData memory subprotocolData = subprotocolRegistry.getSubprotocol(
            _subprotocolName
        );
        address subprotocolOwner = subprotocolData.owner;
        if (subprotocolOwner == address(0)) revert SubprotocolDoesNotExist(_subprotocolName);
        ERC721 nftToRemove = ERC721(subprotocolData.nftAddress);

        if (ownerOf[_cidNFTID] != msg.sender)
            // TODO: Should delegated users be allowed to remove?
            revert NotAuthorizedForCIDNFT(msg.sender, _cidNFTID);
        if (_type == ValueType.ORDERED) {
            // We do not have to check if ordered is supported by the subprotocol. If not, the value will not be unset (which is checked below)
            uint256 currNFTID = CIDDataOrdered[_cidNFTID][_subprotocolName][_keyID];
            if (currNFTID == 0)
                // This check is technically not necessary (because the NFT transfer would fail), but we include it to have more meaningful errors
                revert OrderedValueNotSet(_cidNFTID, _subprotocolName, _keyID);
            delete CIDDataOrdered[_cidNFTID][_subprotocolName][_keyID];
            nftToRemove.safeTransferFrom(address(this), msg.sender, currNFTID);
            // TODO: Event
        } else if (_type == ValueType.PRIMARY) {
            uint256 currNFTID = CIDDataPrimary[_cidNFTID][_subprotocolName][_key];
            if (currNFTID == 0) revert PrimaryValueNotSet(_cidNFTID, _subprotocolName, _key);
            delete CIDDataPrimary[_cidNFTID][_subprotocolName][_key];
            nftToRemove.safeTransferFrom(address(this), msg.sender, currNFTID);
        } else if (_type == ValueType.ACTIVE) {
            IndexedArray storage keyData = CIDDataActive[_cidNFTID][_subprotocolName][_key];
            uint256 arrayPosition = keyData.positions[_nftIDToRemove]; // Index + 1, 0 if non-existant
            if (arrayPosition == 0)
                revert ActiveArrayDoesNotContainID(_cidNFTID, _subprotocolName, _key, _nftIDToRemove);
            uint256 arrayLength = keyData.values.length;
            // Swap only necessary if not already the last element
            if (arrayPosition != arrayLength) {
                uint256 befSwapLastNFTID = keyData.values[arrayLength - 1];
                keyData.values[arrayPosition - 1] = befSwapLastNFTID;
                keyData.positions[befSwapLastNFTID] = arrayPosition;
            }
            keyData.values.pop();
            keyData.positions[_nftIDToRemove] = 0;
            nftToRemove.safeTransferFrom(address(this), msg.sender, _nftIDToRemove);
        }
    }

    // TODO: Need to define standard for "liveness" check. IF NFT is safeguarded, user should still be able to interact with it?
}
