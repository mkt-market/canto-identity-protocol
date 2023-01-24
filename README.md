# Code4rena CID Testing Contest
Besides the documentation that is provided here and in the code, work-in-progress documentation of the protocol is also available at https://tster.github.io/cid-docs-pages/
## Canto Identity Protocol (CID)

Canto Identity Protocol provides identity NFTs that associate different subprotocol NFTs with one CID NFT, which in turn is associated with a person / address. The core protocol consists of three parts:

### CID NFT
Everyone can mint a CID NFT by using the `mint` function. Then, subprotocol NFTs can be associated with this NFT using the `add` function. Depending on how the subprotocol was configured when it was added to the registry, the association of the CID NFT with the subprotocol NFT looks different:
- Ordered: In this association type, a mapping from integers (keys) to subprotocol NFTs is associated with a CID NFT / subprotocol.
- Primary: Primary means that there is one (or zero) values that are associated with a CID NFT / subprotocol combination.
- Active: In this case, a list of subprotocol NFTs can be associated with one CID NFT for the given subprotocol.
`remove` is used to remove an association again.

### Subprotocol Registry
The subprotocol registry is used to register new subprotocols. Every subprotocol is identified by a unique name. When adding it, the owner needs to define the allowed association types (see above) and if adding an NFT should cost a fee.

### Address Registry
The address registry allows user to associate their address with a CID NFT. Therefore, on-chain or off-chain applications can check this registry to get the CID NFT ID that is associated with a user.

### Subprotocols
There will be a common interface for subprotocols, an early draft is in the file `CidSubprotocolNFT.sol`. Note that subprotocols / this file are out of scope for this contest.

## Testing Scope

### Unit tests

| **File** | **Function** | **Tests** |
|----------|--------------|-----------|
| AddressRegistry.sol | `register` | <ul><li>Registering a CID NFT where the caller is not the owner of the CID NFT</li><li>Registering a CID NFT where the caller is the owner of the CID NFT</li><li>Registering another CID NFT where the caller is the owner when there was already one registered (overwriting)</li></ul>  |
|          | `remove` | <ul><li>Removing without a prior registration (should revert)</li><li>Removing with a prior registration</li><li>Calling remove two times (second time should revert)</li></ul> |
|          | `getCID` | Checking that the correct values from the `cidNFTs` mapping are returned |
| SubprotocolRegistry.sol | `register` | <ul><li>Registering with different association types/combinations (`_ordered`, `_primary`, `_active`), ensuring fee is taken</li><li>Registering with no type specified (should revert)</li><li>Trying to register already registered subprotocol (should revert)</li><li>Trying to register with NFT that is not subprotocol NFT (should revert)</li></ul>  |
|          | `getSubprotocol` | Ensuring that returned data matches `subprotocols` |
| CIDNFT.sol | `tokenURI` | Returns concatenated token URI for existing NFTs, reverts for non-existing NFTs |
| | `mint` | <ul><li>Minting without an add list</li><li>Minting with a single item add list</li><li>Minting with an add list that contains multiple items</li><li>Minting with an add list that contains multiple items where at least one of them reverts (whole `mint` calls should revert)</li></ul> |
| | `add` | <ul><li>Adding data for all three association types when it is supported by the subprotocol</li><li>Adding data for an association types when it is not supported by the subprotocol (should revert)</li><li>Trying to add data for non-existing subprotocol</li><li>Trying to add NFT ID 0 (should revert)</li><li>Adding as the CID NFT owner</li><li>Adding as the CID NFT approved address</li><li>Adding as the address that is `approvedForAll` for the NFT owner</li><li>Adding from an unauthorized caller (should revert)</li><li>Adding with and without a fee</li><li>Type `ACTIVE`: Adding multiple values</li><li>Type `ACTIVE`: Trying to add duplicate (should revert)</li></ul> |
| | `remove` | <ul><li>Trying to remove a previously added association for all three types, ensuring that it is removed</li><li>Same authorization checks as in `add` (owner, authorized, `authorizedForAll`)</li><li>Trying to remove from non-existing subprotocol</li><li>`ORDERED` & `ACTIVE`: Trying to remove when it is not set (should revert)</li><li>`ACTIVE`: Trying to remove non-existing entry (should revert)</li><li>`ACTIVE`: Trying to remove last item or item in the middle (should swap positions for item in the middle)</li></ul> |
| | `getOrderedData`, `getPrimaryData`, `getActiveData`, `activeDataIncludesNFT` | Ensuring that data corresponds to mapping data (might be combined with previous add tests) |

### Integration tests
The purpose of these tests is to not only test different parts in isolation, but have some realistic scenarios how the different parts will interact with each other in practice.

- Three different EOAs create three different subprotocols. Alice mints a CID NFT and registers it in the address registry. She then adds some subprotocol NFTs to her CID NFT and removes them again.
- Bob adds some subprotocol NFTs to his CID NFT that is registered in the address registry. Later on, he mints a new CID NFT, registers that one in the address registry and adds/removes some other subprotocol NFTs.