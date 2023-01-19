// SPDX-License-Identifier: GPL-3.0-only
pragma solidity >=0.8.0;

/// @title Subprotocol Registry
/// @notice Enables registration of new subprotocols
contract SubprotocolRegistry {
    /*//////////////////////////////////////////////////////////////
                                 STATE
    //////////////////////////////////////////////////////////////*/

    /// @notice Data that is associated with a subprotocol.
    /// @dev Data types are chosen such that all data fits in one slot
    struct SubprotocolData {
        /// @notice Owner (registrant) of the subprotocol
        address owner;
        /// @notice Optional cost in NOTE to add an NFT
        /// @dev Maximum value is (2^96 - 1) / 10^18 =~ 80 billion. Zero for no fee
        uint96 fee;
        address nftAddress;
        bool ordered;
        bool primary;
        bool active;
    }

    /// @notice Mapping (name => data) that contains all registered subprotocols
    mapping(string => SubprotocolData) private subprotocols;

    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/
    event SubprotocolRegistered(
        address indexed registrar,
        string indexed name,
        address indexed nftAddress,
        bool ordered,
        bool primary,
        bool active,
        uint96 fee
    );

    /*//////////////////////////////////////////////////////////////
                                 ERRORS
    //////////////////////////////////////////////////////////////*/
    error SubprotocolAlreadyExists(string name, address owner);
    error NoTypeSpecified(string name);

    /// @notice Register a new subprotocol
    /// @dev The options ordered, primary, active are not mutually exclusive. In practice, only one will be set for most subprotocols,
    /// but if a subprotocol for instance supports int keys (mapped to one value) and a list of active NFTs, ordered and active is true.
    /// @param _ordered Ordering allows integers to be used as map keys, to one and only one value
    /// @param _primary Primary maps string keys to zero or one value
    /// @param _active Subprotocols that have a list of a active NFTs
    /// @param _name Name of the subprotocol, has to be unique
    /// @param _nftAddress Address of the subprotocol NFT. Has to adhere to the CidSubprotocolNFT interface
    /// @param _fee Fee (in $NOTE) for minting a new token of the subprotocol. Set to 0 if there is no fee. 10% is subtracted from this fee as a CID fee
    function register(
        bool _ordered,
        bool _primary,
        bool _active,
        address _nftAddress,
        string calldata _name,
        uint96 _fee
    ) external {
        if (!(_ordered || _primary || _active)) revert NoTypeSpecified(_name);
        SubprotocolData memory subprotocolData = subprotocols[_name];
        if (subprotocolData.owner != address(0)) revert SubprotocolAlreadyExists(_name, subprotocolData.owner);
        subprotocolData.owner = msg.sender;
        subprotocolData.fee = _fee;
        subprotocolData.nftAddress = _nftAddress; // TODO: Verify that is subprotocol NFT?
        subprotocolData.ordered = _ordered;
        subprotocolData.primary = _primary;
        subprotocolData.active = _active;
        subprotocols[_name] = subprotocolData;
        emit SubprotocolRegistered(msg.sender, _name, _nftAddress, _ordered, _primary, _active, _fee);
    }

    function getSubprotocol(string calldata _name) external view returns (SubprotocolData memory) {
        return subprotocols[_name];
    }
}
