// SPDX-License-Identifier: GPL-3.0-only
pragma solidity >=0.8.0;

import {DSTest} from "ds-test/test.sol";
import {Utilities} from "./utils/Utilities.sol";
import {console} from "./utils/Console.sol";
import {Vm} from "forge-std/Vm.sol";
import "../AddressRegistry.sol";
import "../CidNFT.sol";

contract AddressRegistryTest is DSTest {
    Vm internal immutable vm = Vm(HEVM_ADDRESS);

    Utilities internal utils;
    address payable[] internal users;
    AddressRegistry internal addressRegistry;

    CidNFT cidNFT;

    function setUp() public {
        utils = new Utilities();
        users = utils.createUsers(5);
        

        cidNFT = new CidNFT(
            "MockCidNFT",
            "MCNFT",
            "base_uri/",
            users[0],
            address(0),
            address(0)
        );
        addressRegistry = new AddressRegistry(address(cidNFT));

    }

    function testRegisterNFTCallerNotOwner() public {

        uint256 nftId = 1;
        address owner = users[0];
        address hacker = users[1];

        // owner mint NFT
        vm.prank(owner);
        bytes[] memory addList;
        cidNFT.mint(addList);
        assertEq(cidNFT.ownerOf(nftId), owner);

        // hacker try try to register nft, revert
        vm.prank(hacker);
        vm.expectRevert(
            abi.encodeWithSelector(
                AddressRegistry.NFTNotOwnedByUser.selector, 
                nftId, 
                hacker
            )
        );
        addressRegistry.register(nftId);

    }

    function testRegisterNFTCallerIsOwner() public {

        uint256 nftId = 1;
        address owner = users[0];

        // owner mint NFT
        vm.prank(owner);
        bytes[] memory addList;
        cidNFT.mint(addList);
        assertEq(cidNFT.ownerOf(nftId), owner);

        // owner trys to register nft, succeed
        vm.prank(owner);
        addressRegistry.register(nftId);

        // validate the regisered CID
        uint256 cid = addressRegistry.getCID(owner);
        assertEq(cid, nftId);

    }

}
