// SPDX-License-Identifier: GPL-3.0-only
pragma solidity >=0.8.0;

import "forge-std/Script.sol";
import "../src/AddressRegistry.sol";
import "../src/CidNFT.sol";
import "../src/SubprotocolRegistry.sol";

contract DeploymentScript is Script {
    // https://docs.canto.io/evm-development/contract-addresses
    address constant NOTE = address(0x4e71A2E537B7f9D9413D3991D37958c0b5e1e503);
    address constant FEE_WALLET = address(0); // TODO
    string cidNFTName = "Canto Identity Protocol";
    string cidNFTSymbol = "CID";

    function setUp() public {}

    function run() public {
        string memory seedPhrase = vm.readFile(".secret");
        uint256 privateKey = vm.deriveKey(seedPhrase, 0);
        vm.startBroadcast(privateKey);
        address subprotocolRegistry = _deploySubprotocolRegistry();
        CidNFT cidNFT = _deployCidNft(subprotocolRegistry);
        address addressRegistry = _deployAddressRegistry(address(cidNFT));
        _setAddressRegistryOnCID(cidNFT, addressRegistry);
        vm.stopBroadcast();
    }

    function _deploySubprotocolRegistry() private returns (address) {
        SubprotocolRegistry registry = new SubprotocolRegistry(NOTE, FEE_WALLET);
        return address(registry);
    }

    function _deployCidNft(address _subprotocolRegistry) private returns (CidNFT) {
        CidNFT cidNFT = new CidNFT(
            cidNFTName,
            cidNFTSymbol,
            "", // TODO: BaseURI
            FEE_WALLET,
            NOTE,
            _subprotocolRegistry
        );
        return cidNFT;
    }

    function _deployAddressRegistry(address _cidNFT) private returns (address) {
        AddressRegistry addressRegistry = new AddressRegistry(
            _cidNFT
        );
        return address(addressRegistry);
    }

    function _setAddressRegistryOnCID(CidNFT _cidNFT, address _addressRegistry) private {
        _cidNFT.setAddressRegistry(_addressRegistry);
    }
}
