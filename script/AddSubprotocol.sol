// SPDX-License-Identifier: GPL-3.0-only
pragma solidity >=0.8.0;

import "forge-std/Script.sol";
import "../src/AddressRegistry.sol";
import "../src/CidNFT.sol";
import "../src/SubprotocolRegistry.sol";

contract AddSubprotocols is Script {
    address constant SUBPROTOCOL_REGISTRY = address(0xf5f2B89beED50A0801DF49B24f7C2Bf6fA52Dc3B);
    address constant PFP_ADDRESS = address(0x4FA3F4E0Da71400A89C996bf70e2dcBd7a80409d);
    address constant BIO_ADDRESS = address(0x39f3fD98eCd504263125B6D48404211aad292e9D);
    address constant NAMESPACE_ADDRESS = address(0xeAA3a8BF17E151C2524B33fEEfD7106024733d83);
    address constant HENLO_ADDRESS = address(0x1977447ab43131d9f20905234995b83040c68EBE);

    function run() public {
        string memory seedPhrase = vm.readFile(".secret");
        uint256 privateKey = vm.deriveKey(seedPhrase, 0);
        vm.startBroadcast(privateKey);
        SubprotocolRegistry subprotocolRegistry = SubprotocolRegistry(SUBPROTOCOL_REGISTRY);
        // subprotocolRegistry.register(
        //     false, // ordered
        //     true, // primary
        //     false, // active
        //     PFP_ADDRESS,
        //     "profilepic",
        //     0 // fee
        // );

        // subprotocolRegistry.register(
        //     false, // ordered
        //     true, // primary
        //     false, // active
        //     BIO_ADDRESS,
        //     "bio",
        //     0 // fee
        // );

        // subprotocolRegistry.register(
        //     false, // ordered
        //     true, // primary
        //     false, // active
        //     NAMESPACE_ADDRESS,
        //     "namespaces",
        //     0 // fee
        // );

        subprotocolRegistry.register(
            false, // ordered
            true, // primary
            false, // active
            HENLO_ADDRESS,
            "henlo2",
            0 // fee
        );

        vm.stopBroadcast();
    }
}
