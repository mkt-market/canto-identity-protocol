# Utilities
[Git Source](https://github.com/OpenCoreCH/canto-identity-protocol/blob/7f02f16c0527dc1a017305652e7286fe766dc1b6/src/test/utils/Utilities.sol)

**Inherits:**
DSTest


## State Variables
### vm

```solidity
Vm internal immutable vm = Vm(HEVM_ADDRESS);
```


### nextUser

```solidity
bytes32 internal nextUser = keccak256(abi.encodePacked("user address"));
```


## Functions
### getNextUserAddress


```solidity
function getNextUserAddress() external returns (address payable);
```

### createUsers


```solidity
function createUsers(uint256 userNum) external returns (address payable[] memory);
```

### mineBlocks


```solidity
function mineBlocks(uint256 numBlocks) external;
```

