// SPDX-License-Identifier: GPL-3.0-only
pragma solidity >=0.8.0;

import {ERC721Enumerable, IERC721, ERC721} from "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "solmate/tokens/ERC20.sol";
import "solmate/utils/SafeTransferLib.sol";
import "solmate/auth/Owned.sol";
import {SubprotocolRegistry} from "./SubprotocolRegistry.sol";
import {AddressRegistry} from "./AddressRegistry.sol";
import {LibString} from "solady/utils/LibString.sol";
import {Base64} from "solady/utils/Base64.sol";
import "../interface/Turnstile.sol";

/// @title Canto Identity Protocol NFT
/// @notice CID NFTs are at the heart of the CID protocol. All key/values of subprotocols are associated with them.
contract CidNFT is ERC721Enumerable, Owned {
    /*//////////////////////////////////////////////////////////////
                                 CONSTANTS
    //////////////////////////////////////////////////////////////*/

    /// @notice Fee (in BPS) that is charged for every add call (as a percentage of the subprotocol fee). Fixed at 10%.
    uint256 public constant CID_FEE_BPS = 1_000;

    /// @notice SVG fallback logo for the NFT
    string private constant SVG_FALLBACK =
        '<svg xmlns="http://www.w3.org/2000/svg" fill-rule="evenodd" clip-rule="evenodd" image-rendering="optimizeQuality" shape-rendering="geometricPrecision" text-rendering="geometricPrecision" version="1.1" viewBox="0 0 1200 600"><path d="M92.5 92.5a26353.32 26353.32 0 0 1 397 1.5c6.64 6.094 11.14 13.594 13.5 22.5a414.058 414.058 0 0 1 1 55 4305.687 4305.687 0 0 0-77.5 78.5c-23.333.667-46.667.667-70 0-11.5-3.5-19-11-22.5-22.5l-.5-21.5a179.558 179.558 0 0 1 1.5-25.5 131.352 131.352 0 0 1 12-15c1.32-1.987 3.152-3.154 5.5-3.5l3.5-5.5a102.249 102.249 0 0 1 10-9c2.21-5.762.376-9.928-5.5-12.5-3.62-.841-6.954-.174-10 2a18778.45 18778.45 0 0 0-115 115.5c-1.275 3.373-1.108 6.707.5 10 12.95 8.57 18.284 20.57 16 36a88.011 88.011 0 0 1-6 11c-12.134 11.126-23.134 23.126-33 36-8.565 23.924-3.065 43.757 16.5 59.5 19.095 11.458 38.095 11.29 57-.5a10066.422 10066.422 0 0 0 85-84.5c15.634-3.786 21.467 2.048 17.5 17.5a4356.947 4356.947 0 0 0-74 74 28.931 28.931 0 0 1-1.5 4c1.645 4.81 4.81 8.144 9.5 10a1689.64 1689.64 0 0 1 7.5-4.5 6870.558 6870.558 0 0 0 98-99 18.924 18.924 0 0 0 5-3 214.134 214.134 0 0 1 39 1c15.813 4.479 25.979 14.646 30.5 30.5a511.61 511.61 0 0 1 1.5 42 364.356 364.356 0 0 1-1.5 37 1768.187 1768.187 0 0 0-49.5 50.5l-3 1a20.231 20.231 0 0 1-7.5 7.5c-.273 1.83-1.107 3.33-2.5 4.5a536.121 536.121 0 0 0-11 9c-112.667.667-225.333.667-338 0-13.816-12.039-18.65-27.206-14.5-45.5 2-6.833 4.5-13.5 7.5-20 3.083-1.917 5.25-4.584 6.5-8a23.918 23.918 0 0 0 7.5-7.5c3.167-.5 5-2.333 5.5-5.5a74.329 74.329 0 0 1 11.5-9.5 11.333 11.333 0 0 0 1.5-3.5 37532.8 37532.8 0 0 1 103-102c3.05-2.926 5.215-6.426 6.5-10.5-.902-4.147-3.235-7.147-7-9-2.068-.687-4.068-.52-6 .5a4463.19 4463.19 0 0 0-97 97.5 84.733 84.733 0 0 1-10 8c-8.016 3.589-16.016 2.923-24-2a55.861 55.861 0 0 0-4.5-5.5 8696.825 8696.825 0 0 1-1-263c2.464-9.973 7.63-17.973 15.5-24Z" fill="#000" opacity=".971"/><path d="M557.5 92.5c28.422-.483 56.755.017 85 1.5 11.959 11.393 15.959 25.226 12 41.5a2146.267 2146.267 0 0 1-39.5 38c-5.039 8.879-2.706 14.546 7 17a38.206 38.206 0 0 0 8.5-5.5c4.387-7.15 10.721-9.483 19-7 4.948 1.721 6.948 5.221 6 10.5l-.5 6-95.5 95.5c-7.585 3.323-13.418 1.49-17.5-5.5-.667-55-.667-110 0-165a103.188 103.188 0 0 1 7-18 41.047 41.047 0 0 0 8.5-9Z" fill="#000" opacity=".952"/><path d="M712.5 92.5c132-.167 264 0 396 .5 7.73 5.95 12.57 13.784 14.5 23.5.67 39.667.67 79.333 0 119-19.83 19.833-39.67 39.667-59.5 59.5l-124 1-10 5a3081.282 3081.282 0 0 1-65.5 66.5c-2.49 10.845 1.678 15.011 12.5 12.5a2862.062 2862.062 0 0 1 64-63c6.27-1.4 11.604.1 16 4.5 1.433 4.733 1.266 9.4-.5 14L789.5 502c-25.333.667-50.667.667-76 0-8.01-5.824-13.176-13.657-15.5-23.5a3842.33 3842.33 0 0 1 0-124c2.467-13.597 8.134-25.597 17-36l76-76c1.782-6.946-.885-11.612-8-14l-4.5 1.5a5106.766 5106.766 0 0 0-60 60.5c-6.19 3.958-12.357 3.958-18.5 0l-2-4c-.667-57-.667-114 0-171 .915-5.16 2.915-9.827 6-14 2.079-3.812 4.913-6.812 8.5-9Zm235 41c44.668-.167 89.33 0 134 .5 5.4 3.555 6.23 8.055 2.5 13.5A10987.464 10987.464 0 0 0 959.5 271c-43.75.989-87.417.656-131-1-5.95-4.986-6.45-10.486-1.5-16.5a20411.013 20411.013 0 0 1 120.5-120Z" fill="#000" opacity=".967"/><path d="M638.5 236.5c6.516-1.263 12.016.404 16.5 5 .986 81.37.653 162.702-1 244a75.761 75.761 0 0 1-12.5 16.5c-28.333.667-56.667.667-85 0-7.824-6.817-12.658-15.317-14.5-25.5-.667-40-.667-80 0-120 1.847-15.02 7.514-28.354 17-40a8930.283 8930.283 0 0 0 79.5-80Z" fill="#000" opacity=".969"/></svg>';

    /*//////////////////////////////////////////////////////////////
                                 ADDRESSES
    //////////////////////////////////////////////////////////////*/

    /// @notice Wallet that receives CID fees
    address public immutable cidFeeWallet;

    /// @notice Reference to the NOTE TOKEN
    ERC20 public note;

    /// @notice Reference to the subprotocol registry
    SubprotocolRegistry public immutable subprotocolRegistry;

    /// @notice Reference to the address registry. Must be set by the owner
    AddressRegistry public addressRegistry;

    /*//////////////////////////////////////////////////////////////
                                 STATE
    //////////////////////////////////////////////////////////////*/

    /// @notice Array of uint256 values (NFT IDs) with additional position information NFT ID => (array pos. + 1)
    struct IndexedArray {
        uint256[] values;
        mapping(uint256 => uint256) positions;
    }

    /// @notice Data that is associated with a CID NFT -> subprotocol name combination
    struct SubprotocolData {
        /// @notice Mapping (key => subprotocol NFT ID) for ordered type
        mapping(uint256 => uint256) ordered;
        /// @notice Value (subprotocol NFT ID) for primary type
        uint256 primary;
        /// @notice List (of subprotocol NFT IDs) for active type
        IndexedArray active;
    }

    /// @notice The different types of associations between CID NFTs and subprotocol NFTs
    enum AssociationType {
        /// @notice key => NFT mapping
        ORDERED,
        /// @notice Zero or one NFT
        PRIMARY,
        /// @notice List of NFTs
        ACTIVE
    }

    /// @notice Data that is associated with a subprotocol name -> subprotocol NFT ID combination (for reverse lookups)
    struct CIDNFTSubprotocolData {
        /// @notice Referenced CID NFT ID
        uint256 cidNFTID;
        /// @notice Key (for ordered) or array position (for active)
        uint256 position;
    }

    /// @notice Counter of the minted NFTs
    /// @dev Used to assign a new unique ID. The first ID that is assigned is 1, ID 0 is never minted.
    uint256 public numMinted;

    /// @notice Stores the references to subprotocol NFTs. Mapping nftID => subprotocol name => subprotocol data
    mapping(uint256 => mapping(string => SubprotocolData)) internal cidData;

    /// @notice Allows lookups of subprotocol NFTs to CID NFTs. Mapping subprotocol name => subprotocol NFT ID => AssociationType => (CID NFT ID, position or key)
    mapping(string => mapping(uint256 => mapping(AssociationType => CIDNFTSubprotocolData))) internal cidDataInverse;

    /// @notice Data that is passed to mint to directly add associations to the minted CID NFT
    struct MintAddData {
        string subprotocolName;
        uint256 key;
        uint256 nftIDToAdd;
        AssociationType associationType;
    }

    /// @notice Registered name of the canonical namespace subprotocol. Used for the tokenURI
    string public namespaceSubprotocolName;

    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/
    event OrderedDataAdded(
        uint256 indexed cidNFTID,
        string indexed subprotocolName,
        uint256 indexed key,
        uint256 subprotocolNFTID
    );
    event PrimaryDataAdded(uint256 indexed cidNFTID, string indexed subprotocolName, uint256 subprotocolNFTID);
    event ActiveDataAdded(
        uint256 indexed cidNFTID,
        string indexed subprotocolName,
        uint256 subprotocolNFTID,
        uint256 arrayIndex
    );
    event OrderedDataRemoved(
        uint256 indexed cidNFTID,
        string indexed subprotocolName,
        uint256 indexed key,
        uint256 subprotocolNFTID
    );
    event PrimaryDataRemoved(uint256 indexed cidNFTID, string indexed subprotocolName, uint256 subprotocolNFTID);
    event ActiveDataRemoved(uint256 indexed cidNFTID, string indexed subprotocolName, uint256 subprotocolNFTID);

    /*//////////////////////////////////////////////////////////////
                                 ERRORS
    //////////////////////////////////////////////////////////////*/
    error TokenNotMinted(uint256 tokenID);
    error SubprotocolDoesNotExist(string subprotocolName);
    error NFTIDZeroDisallowedForSubprotocols();
    error AssociationTypeNotSupportedForSubprotocol(AssociationType associationType, string subprotocolName);
    error NotAuthorizedForCIDNFT(address caller, uint256 cidNFTID, address cidNFTOwner);
    error NotAuthorizedForSubprotocolNFT(address caller, uint256 subprotocolNFTID);
    error ActiveArrayAlreadyContainsID(uint256 cidNFTID, string subprotocolName, uint256 nftIDToAdd);
    error OrderedValueNotSet(uint256 cidNFTID, string subprotocolName, uint256 key);
    error PrimaryValueNotSet(uint256 cidNFTID, string subprotocolName);
    error ActiveArrayDoesNotContainID(uint256 cidNFTID, string subprotocolName, uint256 nftIDToRemove);

    /// @notice Sets the name, symbol, baseURI, and the address of the auction factory
    /// @param _name Name of the NFT
    /// @param _symbol Symbol of the NFT
    /// @param _cidFeeWallet Address of the wallet that receives the fees
    /// @param _noteContract Address of the $NOTE contract
    /// @param _subprotocolRegistry Address of the subprotocol registry
    constructor(
        string memory _name,
        string memory _symbol,
        address _cidFeeWallet,
        address _noteContract,
        address _subprotocolRegistry
    ) ERC721(_name, _symbol) Owned(msg.sender) {
        cidFeeWallet = _cidFeeWallet;
        note = ERC20(_noteContract);
        subprotocolRegistry = SubprotocolRegistry(_subprotocolRegistry);
        if (block.chainid == 7700 || block.chainid == 7701) {
            // Register CSR on Canto main- and testnet
            Turnstile turnstile = Turnstile(0xEcf044C5B4b867CFda001101c617eCd347095B44);
            turnstile.register(tx.origin);
        }
    }

    /// @notice Get the token URI for the provided ID. Returns the namespace tokenURI (if one is associated with the CID), otherwise the logo as a fallback.
    /// @param _id ID to retrieve the URI for
    /// @return tokenURI The URI of the queried token (path to a JSON file)
    function tokenURI(uint256 _id) public view override returns (string memory) {
        if (!_exists(_id))
            // According to ERC721, this revert for non-existing tokens is required
            revert TokenNotMinted(_id);
        uint256 namespaceNFTID = cidData[_id][namespaceSubprotocolName].primary;
        if (namespaceNFTID == 0) {
            string memory json = Base64.encode(
                bytes(
                    string.concat(
                        '{"name": "CID #',
                        LibString.toString(_id),
                        '", "image": "data:image/svg+xml;base64,',
                        Base64.encode(SVG_FALLBACK),
                        '"}'
                    )
                )
            );
            return string.concat("data:application/json;base64,", json);
        } else {
            address subprotocolNFTAddress = subprotocolRegistry.getSubprotocol(namespaceSubprotocolName).nftAddress;
            return ERC721(subprotocolNFTAddress).tokenURI(namespaceNFTID);
        }
    }

    /// @notice Mint a new CID NFT
    /// @dev An address can mint multiple CID NFTs, but it can only set one as associated with it in the AddressRegistry
    /// @param _addList An optional list of parameters for add to add subprotocol NFTs directly after minting.
    function mint(MintAddData[] calldata _addList) external {
        uint256 tokenToMint = ++numMinted;
        _mint(msg.sender, tokenToMint); // We do not use _safeMint here on purpose. If a contract calls this method, he expects to get an NFT back
        for (uint256 i = 0; i < _addList.length; ++i) {
            MintAddData calldata addData = _addList[i];
            add(tokenToMint, addData.subprotocolName, addData.key, addData.nftIDToAdd, addData.associationType);
        }
    }

    /// @notice Add a new entry for the given subprotocol to the provided CID NFT
    /// @param _cidNFTID ID of the CID NFT to add the data to
    /// @param _subprotocolName Name of the subprotocol where the data will be added. Has to exist.
    /// @param _key Key to set. This value is only relevant for the AssociationType ORDERED (where a mapping int => nft ID is stored)
    /// @param _nftIDToAdd The ID of the NFT to add
    /// @param _type Association type (see AssociationType struct) to use for this data
    function add(
        uint256 _cidNFTID,
        string calldata _subprotocolName,
        uint256 _key,
        uint256 _nftIDToAdd,
        AssociationType _type
    ) public {
        SubprotocolRegistry.SubprotocolData memory subprotocolData = subprotocolRegistry.getSubprotocol(
            _subprotocolName
        );
        address subprotocolOwner = subprotocolData.owner;
        if (subprotocolOwner == address(0)) revert SubprotocolDoesNotExist(_subprotocolName);
        address cidNFTOwner = _ownerOf(_cidNFTID);
        if (
            cidNFTOwner != msg.sender &&
            getApproved(_cidNFTID) != msg.sender &&
            !isApprovedForAll(cidNFTOwner, msg.sender)
        ) revert NotAuthorizedForCIDNFT(msg.sender, _cidNFTID, cidNFTOwner);
        if (_nftIDToAdd == 0) revert NFTIDZeroDisallowedForSubprotocols(); // ID 0 is disallowed in subprotocols

        // The CID Protocol safeguards the NFTs of subprotocols. Note that these NFTs are usually pointers to other data / NFTs (e.g., to an image NFT for profile pictures)
        ERC721 nftToAdd = ERC721(subprotocolData.nftAddress);
        nftToAdd.transferFrom(msg.sender, address(this), _nftIDToAdd);
        // Charge fee (subprotocol & CID fee) if configured
        uint96 subprotocolFee = subprotocolData.fee;
        if (subprotocolFee != 0) {
            uint256 cidFee = (subprotocolFee * CID_FEE_BPS) / 10_000;
            SafeTransferLib.safeTransferFrom(note, msg.sender, cidFeeWallet, cidFee);
            SafeTransferLib.safeTransferFrom(note, msg.sender, subprotocolOwner, subprotocolFee - cidFee);
        }
        if (_type == AssociationType.ORDERED) {
            if (!subprotocolData.ordered) revert AssociationTypeNotSupportedForSubprotocol(_type, _subprotocolName);
            if (cidData[_cidNFTID][_subprotocolName].ordered[_key] != 0) {
                // Remove to ensure that user gets NFT back
                remove(_cidNFTID, _subprotocolName, _key, 0, _type);
            }
            cidData[_cidNFTID][_subprotocolName].ordered[_key] = _nftIDToAdd;
            cidDataInverse[_subprotocolName][_nftIDToAdd][AssociationType.ORDERED] = CIDNFTSubprotocolData(
                _cidNFTID,
                _key
            );
            emit OrderedDataAdded(_cidNFTID, _subprotocolName, _key, _nftIDToAdd);
        } else if (_type == AssociationType.PRIMARY) {
            if (!subprotocolData.primary) revert AssociationTypeNotSupportedForSubprotocol(_type, _subprotocolName);
            if (cidData[_cidNFTID][_subprotocolName].primary != 0) {
                // Remove to ensure that user gets NFT back
                remove(_cidNFTID, _subprotocolName, 0, 0, _type);
            }
            cidData[_cidNFTID][_subprotocolName].primary = _nftIDToAdd;
            cidDataInverse[_subprotocolName][_nftIDToAdd][AssociationType.PRIMARY] = CIDNFTSubprotocolData(
                _cidNFTID,
                0
            );
            emit PrimaryDataAdded(_cidNFTID, _subprotocolName, _nftIDToAdd);
        } else if (_type == AssociationType.ACTIVE) {
            if (!subprotocolData.active) revert AssociationTypeNotSupportedForSubprotocol(_type, _subprotocolName);
            IndexedArray storage activeData = cidData[_cidNFTID][_subprotocolName].active;
            uint256 lengthBeforeAddition = activeData.values.length;
            if (lengthBeforeAddition == 0) {
                uint256[] memory nftIDsToAdd = new uint256[](1);
                nftIDsToAdd[0] = _nftIDToAdd;
                activeData.values = nftIDsToAdd;
                activeData.positions[_nftIDToAdd] = 1; // Array index + 1
            } else {
                // Check for duplicates
                if (activeData.positions[_nftIDToAdd] != 0)
                    revert ActiveArrayAlreadyContainsID(_cidNFTID, _subprotocolName, _nftIDToAdd);
                activeData.values.push(_nftIDToAdd);
                activeData.positions[_nftIDToAdd] = lengthBeforeAddition + 1;
            }
            cidDataInverse[_subprotocolName][_nftIDToAdd][AssociationType.ACTIVE] = CIDNFTSubprotocolData(
                _cidNFTID,
                lengthBeforeAddition
            );
            emit ActiveDataAdded(_cidNFTID, _subprotocolName, _nftIDToAdd, lengthBeforeAddition);
        }
    }

    /// @notice Remove / unset a key for the given CID NFT and subprotocol
    /// @param _cidNFTID ID of the CID NFT to remove the data from
    /// @param _subprotocolName Name of the subprotocol where the data will be removed. Has to exist.
    /// @param _key Key to unset. This value is only relevant for the AssociationType ORDERED
    /// @param _nftIDToRemove The ID of the NFT to remove. Only needed for the AssociationType ACTIVE
    /// @param _type Association type (see AssociationType struct) to remove this data from
    function remove(
        uint256 _cidNFTID,
        string calldata _subprotocolName,
        uint256 _key,
        uint256 _nftIDToRemove,
        AssociationType _type
    ) public {
        SubprotocolRegistry.SubprotocolData memory subprotocolData = subprotocolRegistry.getSubprotocol(
            _subprotocolName
        );
        address subprotocolOwner = subprotocolData.owner;
        if (subprotocolOwner == address(0)) revert SubprotocolDoesNotExist(_subprotocolName);
        address cidNFTOwner = _ownerOf(_cidNFTID);
        if (
            cidNFTOwner != msg.sender &&
            getApproved(_cidNFTID) != msg.sender &&
            !isApprovedForAll(cidNFTOwner, msg.sender)
        ) revert NotAuthorizedForCIDNFT(msg.sender, _cidNFTID, cidNFTOwner);

        ERC721 nftToRemove = ERC721(subprotocolData.nftAddress);
        if (_type == AssociationType.ORDERED) {
            // We do not have to check if ordered is supported by the subprotocol. If not, the value will not be unset (which is checked below)
            uint256 currNFTID = cidData[_cidNFTID][_subprotocolName].ordered[_key];
            if (currNFTID == 0)
                // This check is technically not necessary (because the NFT transfer would fail), but we include it to have more meaningful errors
                revert OrderedValueNotSet(_cidNFTID, _subprotocolName, _key);
            delete cidData[_cidNFTID][_subprotocolName].ordered[_key];
            delete cidDataInverse[_subprotocolName][currNFTID][AssociationType.ORDERED];
            nftToRemove.transferFrom(address(this), msg.sender, currNFTID); // Use transferFrom here to prevent reentrancy possibility when remove is called from add
            emit OrderedDataRemoved(_cidNFTID, _subprotocolName, _key, currNFTID);
        } else if (_type == AssociationType.PRIMARY) {
            uint256 currNFTID = cidData[_cidNFTID][_subprotocolName].primary;
            if (currNFTID == 0) revert PrimaryValueNotSet(_cidNFTID, _subprotocolName);
            delete cidData[_cidNFTID][_subprotocolName].primary;
            delete cidDataInverse[_subprotocolName][currNFTID][AssociationType.PRIMARY];
            nftToRemove.transferFrom(address(this), msg.sender, currNFTID);
            emit PrimaryDataRemoved(_cidNFTID, _subprotocolName, currNFTID);
        } else if (_type == AssociationType.ACTIVE) {
            IndexedArray storage activeData = cidData[_cidNFTID][_subprotocolName].active;
            uint256 arrayPosition = activeData.positions[_nftIDToRemove]; // Index + 1, 0 if non-existant
            if (arrayPosition == 0) revert ActiveArrayDoesNotContainID(_cidNFTID, _subprotocolName, _nftIDToRemove);
            uint256 arrayLength = activeData.values.length;
            // Swap only necessary if not already the last element
            if (arrayPosition != arrayLength) {
                uint256 befSwapLastNFTID = activeData.values[arrayLength - 1];
                activeData.values[arrayPosition - 1] = befSwapLastNFTID;
                activeData.positions[befSwapLastNFTID] = arrayPosition;
                cidDataInverse[_subprotocolName][befSwapLastNFTID][AssociationType.ACTIVE].position = arrayPosition - 1;
            }
            activeData.values.pop();
            activeData.positions[_nftIDToRemove] = 0;
            nftToRemove.transferFrom(address(this), msg.sender, _nftIDToRemove);
            delete cidDataInverse[_subprotocolName][_nftIDToRemove][AssociationType.ACTIVE];
            emit ActiveDataRemoved(_cidNFTID, _subprotocolName, _nftIDToRemove);
        }
    }

    /// @notice Get the ordered data that is associated with a CID NFT / Subprotocol
    /// @param _cidNFTID ID of the CID NFT to query
    /// @param _subprotocolName Name of the subprotocol to query
    /// @param _key Key to query
    /// @return subprotocolNFTID The ID of the NFT at the queried key. 0 if it does not exist
    function getOrderedData(
        uint256 _cidNFTID,
        string calldata _subprotocolName,
        uint256 _key
    ) external view returns (uint256 subprotocolNFTID) {
        subprotocolNFTID = cidData[_cidNFTID][_subprotocolName].ordered[_key];
    }

    /// @notice Perform an inverse lookup for ordered associations. Given the subprotocol name and subprotocol NFT ID, return the CID NFT ID and the key
    /// @dev cidNFTID is 0 if no association exists
    /// @param _subprotocolName Subprotocl name to query
    /// @param _subprotocolNFTID Subprotocol NFT ID to query
    /// @return key The key with which _subprotocolNFTID is associated, cidNFTID The CID NFT with which the subprotocol NFT ID is associated (0 if none)
    function getOrderedCIDNFT(string calldata _subprotocolName, uint256 _subprotocolNFTID)
        external
        view
        returns (uint256 key, uint256 cidNFTID)
    {
        CIDNFTSubprotocolData storage inverseData = cidDataInverse[_subprotocolName][_subprotocolNFTID][
            AssociationType.ORDERED
        ];
        key = inverseData.position;
        cidNFTID = inverseData.cidNFTID;
    }

    /// @notice Get the primary data that is associated with a CID NFT / Subprotocol
    /// @param _cidNFTID ID of the CID NFT to query
    /// @param _subprotocolName Name of the subprotocol to query
    /// @return subprotocolNFTID The ID of the primary NFT at the queried subprotocl / CID NFT. 0 if it does not exist
    function getPrimaryData(uint256 _cidNFTID, string calldata _subprotocolName)
        external
        view
        returns (uint256 subprotocolNFTID)
    {
        subprotocolNFTID = cidData[_cidNFTID][_subprotocolName].primary;
    }

    /// @notice Perform an inverse lookup for primary associations. Given the subprotocol name and subprotocol NFT ID, return the CID NFT ID
    /// @dev cidNFTID is 0 if no association exists
    /// @param _subprotocolName Subprotocl name to query
    /// @param _subprotocolNFTID Subprotocol NFT ID to query
    /// @return cidNFTID The CID NFT with which the subprotocol NFT ID is associated (0 if none)
    function getPrimaryCIDNFT(string calldata _subprotocolName, uint256 _subprotocolNFTID)
        external
        view
        returns (uint256 cidNFTID)
    {
        CIDNFTSubprotocolData storage inverseData = cidDataInverse[_subprotocolName][_subprotocolNFTID][
            AssociationType.PRIMARY
        ];
        cidNFTID = inverseData.cidNFTID;
    }

    /// @notice Get the active data list that is associated with a CID NFT / Subprotocol
    /// @param _cidNFTID ID of the CID NFT to query
    /// @param _subprotocolName Name of the subprotocol to query
    /// @return subprotocolNFTIDs The ID of the primary NFT at the queried subprotocl / CID NFT. 0 if it does not exist
    function getActiveData(uint256 _cidNFTID, string calldata _subprotocolName)
        external
        view
        returns (uint256[] memory subprotocolNFTIDs)
    {
        subprotocolNFTIDs = cidData[_cidNFTID][_subprotocolName].active.values;
    }

    /// @notice Check if a provided NFT ID is included in the active data list that is associated with a CID NFT / Subprotocol
    /// @param _cidNFTID ID of the CID NFT to query
    /// @param _subprotocolName Name of the subprotocol to query
    /// @return nftIncluded True if the NFT ID is in the list
    function activeDataIncludesNFT(
        uint256 _cidNFTID,
        string calldata _subprotocolName,
        uint256 _nftIDToCheck
    ) external view returns (bool nftIncluded) {
        nftIncluded = cidData[_cidNFTID][_subprotocolName].active.positions[_nftIDToCheck] != 0;
    }

    /// @notice Perform an inverse lookup for active associations. Given the subprotocol name and subprotocol NFT ID, return the CID NFT ID and the array position
    /// @dev cidNFTID is 0 if no association exists
    /// @param _subprotocolName Subprotocl name to query
    /// @param _subprotocolNFTID Subprotocol NFT ID to query
    /// @return position The current position of _subprotocolNFTID. May change in the future because of swaps, cidNFTID The CID NFT with which the subprotocol NFT ID is associated (0 if none)
    function getActiveCIDNFT(string calldata _subprotocolName, uint256 _subprotocolNFTID)
        external
        view
        returns (uint256 position, uint256 cidNFTID)
    {
        CIDNFTSubprotocolData storage inverseData = cidDataInverse[_subprotocolName][_subprotocolNFTID][
            AssociationType.ACTIVE
        ];
        position = inverseData.position;
        cidNFTID = inverseData.cidNFTID;
    }

    /// @notice Used to set the address registry after deployment (because of circular dependencies)
    /// @param _addressRegistry Address of the address registry
    function setAddressRegistry(address _addressRegistry) external onlyOwner {
        if (address(addressRegistry) == address(0)) {
            addressRegistry = AddressRegistry(_addressRegistry);
        }
    }

    /// @notice Change the $NOTE address
    /// @param _noteAddress Address of the $NOTE token
    function changeNoteAddress(address _noteAddress) external onlyOwner {
        note = ERC20(_noteAddress);
    }

    /// @notice Change the namespace subprotocol name that is used within the tokenURI function
    /// @param _namespaceSubprotocolName Registered name of the namespace subprotocol name
    function changeNamespaceReference(string memory _namespaceSubprotocolName) external onlyOwner {
        namespaceSubprotocolName = _namespaceSubprotocolName;
    }

    /// @notice Override transferFrom to deregister CID NFT in address registry if registered
    function transferFrom(
        address from,
        address to,
        uint256 id
    ) public override(ERC721, IERC721) {
        super.transferFrom(from, to, id);
        addressRegistry.removeOnTransfer(from, id);
    }
}
