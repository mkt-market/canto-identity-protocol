# SubprotocolRegistry
[Git Source](https://github.com/OpenCoreCH/canto-identity-protocol/blob/7f02f16c0527dc1a017305652e7286fe766dc1b6/src/SubprotocolRegistry.sol)

Enables registration of new subprotocols


## State Variables
### subprotocols
Mapping (name => data) that contains all registered subprotocols


```solidity
mapping(string => SubprotocolData) private subprotocols;
```


## Functions
### register

Register a new subprotocol

*The options ordered, primary, active are not mutually exclusive. In practice, only one will be set for most subprotocols,
but if a subprotocol for instance supports int keys (mapped to one value) and a list of active NFTs, ordered and active is true.*


```solidity
function register(bool _ordered, bool _primary, bool _active, address _nftAddress, string calldata _name, uint96 _fee)
    external;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`_ordered`|`bool`|Ordering allows integers to be used as map keys, to one and only one value|
|`_primary`|`bool`|Primary maps string keys to zero or one value|
|`_active`|`bool`|Subprotocols that have a list of a active NFTs|
|`_nftAddress`|`address`|Address of the subprotocol NFT. Has to adhere to the CidSubprotocolNFT interface|
|`_name`|`string`|Name of the subprotocol, has to be unique|
|`_fee`|`uint96`|Fee (in $NOTE) for minting a new token of the subprotocol. Set to 0 if there is no fee. 10% is subtracted from this fee as a CID fee|


### getSubprotocol

Getter function to retrieve subprotocol data


```solidity
function getSubprotocol(string calldata _name) external view returns (SubprotocolData memory);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`_name`|`string`|Name of the subprotocol to query|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`SubprotocolData`|subprotocolData stored under _name. owner will be set to address(0) if subprotocol does not exist|


## Events
### SubprotocolRegistered

```solidity
event SubprotocolRegistered(
    address indexed registrar,
    string indexed name,
    address indexed nftAddress,
    bool ordered,
    bool primary,
    bool active,
    uint96 fee
);
```

## Errors
### SubprotocolAlreadyExists

```solidity
error SubprotocolAlreadyExists(string name, address owner);
```

### NoTypeSpecified

```solidity
error NoTypeSpecified(string name);
```

### NotASubprotocolNFT

```solidity
error NotASubprotocolNFT(address nftAddress);
```

## Structs
### SubprotocolData
Data that is associated with a subprotocol.

*Data types are chosen such that all data fits in one slot*


```solidity
struct SubprotocolData {
    address owner;
    uint96 fee;
    address nftAddress;
    bool ordered;
    bool primary;
    bool active;
}
```

