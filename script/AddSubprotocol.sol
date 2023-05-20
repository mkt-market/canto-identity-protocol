// SPDX-License-Identifier: GPL-3.0-only
pragma solidity >=0.8.0;

import "forge-std/Script.sol";
import "../src/AddressRegistry.sol";
import "../src/CidNFT.sol";
import "../src/SubprotocolRegistry.sol";

contract AddSubprotocols is Script {
    address constant SUBPROTOCOL_REGISTRY = address(0xf5f2B89beED50A0801DF49B24f7C2Bf6fA52Dc3B);
    address constant PFP_ADDRESS = address(0x8164b7BD64b74037F4985E85C0e06475E47d01C1);
    address constant BIO_ADDRESS = address(0x39f3fD98eCd504263125B6D48404211aad292e9D);
    address constant NAMESPACE_ADDRESS = address(0x4C92862BC06cA9F0a086bF3a16394F1D9C43374A);

    function run() public {
        string memory seedPhrase = vm.readFile(".secret");
        uint256 privateKey = vm.deriveKey(seedPhrase, 0);
        vm.startBroadcast(privateKey);
        SubprotocolRegistry subprotocolRegistry = SubprotocolRegistry(SUBPROTOCOL_REGISTRY);
        subprotocolRegistry.register(
            false, // ordered
            true, // primary
            false, // active
            PFP_ADDRESS,
            "pfp",
            0 // fee
        );

        subprotocolRegistry.register(
            false, // ordered
            true, // primary
            false, // active
            BIO_ADDRESS,
            "bio",
            0 // fee
        );

        subprotocolRegistry.register(
            false, // ordered
            true, // primary
            false, // active
            NAMESPACE_ADDRESS,
            "namespace",
            0 // fee
        );

        vm.stopBroadcast();
    }
}
