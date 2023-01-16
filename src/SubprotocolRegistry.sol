// SPDX-License-Identifier: GPL-3.0-only
pragma solidity >=0.8.0;

/// @title Subprotocol Registry
/// @notice Allows to register new subprotocols
contract SubprotocolRegistry {
    /*//////////////////////////////////////////////////////////////
                                 ADDRESSES
    //////////////////////////////////////////////////////////////*/


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
    mapping(string => SubprotocolData) public subprotocols;

    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/


    /*//////////////////////////////////////////////////////////////
                                 ERRORS
    //////////////////////////////////////////////////////////////*/
    error SubprotocolAlreadyExists(string name, address owner);


    function register(bool ordered, bool primary, bool active, address nftAddress, string calldata name, uint96 fee) external {
        SubprotocolData memory subprotocolData = subprotocols[name];
        if (subprotocolData.owner != address(0))
            revert SubprotocolAlreadyExists(name, subprotocolData.owner);
        subprotocolData.owner = msg.sender;
        subprotocolData.fee = fee;
        subprotocolData.nftAddress = nftAddress;
        subprotocolData.ordered = ordered;
        subprotocolData.primary = primary;
        subprotocolData.active = active;
        subprotocols[name] = subprotocolData;
    }

}
