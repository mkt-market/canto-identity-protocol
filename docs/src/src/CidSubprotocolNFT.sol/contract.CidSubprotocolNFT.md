# CidSubprotocolNFT
[Git Source](https://github.com/OpenCoreCH/canto-identity-protocol/blob/7f02f16c0527dc1a017305652e7286fe766dc1b6/src/CidSubprotocolNFT.sol)

**Inherits:**
ERC721


## State Variables
### CID_SUBPROTOCOL_INTERFACE_ID

```solidity
bytes4 internal constant CID_SUBPROTOCOL_INTERFACE_ID = type(CidSubprotocolNFT).interfaceId;
```


## Functions
### isActive

Returns if a subprotocol NFT is still active. Subprotocol NFTs may be a pointer to a different entity (e.g., another NFT)
and this entity may no longer exist or may no longer be owned by the owner of the subprotocol NFT, in which case false should be returned.

*Has to revert if the given NFT ID does not exist*


```solidity
function isActive(uint256 _nftID) public virtual returns (bool active);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`_nftID`|`uint256`|Subprotocol NFT ID to query|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`active`|`bool`|True if the Subprotocol NFT should be considered active|


### supportsInterface


```solidity
function supportsInterface(bytes4 interfaceId) public pure override returns (bool);
```

