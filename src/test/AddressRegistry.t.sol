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

        cidNFT = new CidNFT("MockCidNFT", "MCNFT", "base_uri/", users[0], address(0), address(0));
        addressRegistry = new AddressRegistry(address(cidNFT));
    }

    function testRegisterNFTCallerNotOwner() public {
        uint256 nftIdOne = 1;
        address owner = users[0];
        address hacker = users[1];

        // owner mint NFT
        vm.prank(owner);
        CidNFT.MintAddData[] memory addList;
        cidNFT.mint(addList);
        assertEq(cidNFT.ownerOf(nftIdOne), owner);

        // hacker try try to register nft, revert
        vm.prank(hacker);
        vm.expectRevert(abi.encodeWithSelector(AddressRegistry.NFTNotOwnedByUser.selector, nftIdOne, hacker));
        addressRegistry.register(nftIdOne);
    }

    function testRegisterNFTCallerIsOwner() public {
        uint256 nftIdOne = 1;
        address owner = users[0];

        // owner mint NFT
        vm.startPrank(owner);
        CidNFT.MintAddData[] memory addList;
        cidNFT.mint(addList);
        assertEq(cidNFT.ownerOf(nftIdOne), owner);

        // owner trys to register nft, succeed
        addressRegistry.register(nftIdOne);

        // validate the regisered CID
        uint256 cid = addressRegistry.getCID(owner);
        assertEq(cid, nftIdOne);
    }

    function testOwnerOverwriteRegisteredCID() public {
        uint256 nftIdOne = 1;
        uint256 nftIdTwo = 2;
        address owner = users[0];

        // owner mint NFT
        vm.startPrank(owner);
        CidNFT.MintAddData[] memory addList;
        cidNFT.mint(addList);
        assertEq(cidNFT.ownerOf(nftIdOne), owner);

        // owner trys to register nft, succeed
        addressRegistry.register(nftIdOne);

        // validate the regisered CID
        uint256 cid = addressRegistry.getCID(owner);
        assertEq(cid, nftIdOne);

        // mint another NFT and overrite the CID
        cidNFT.mint(addList);
        addressRegistry.register(nftIdTwo);

        // validate the regisered CID
        cid = addressRegistry.getCID(owner);
        assertEq(cid, nftIdTwo);
    }

    function testRemoveWithoutRegister() public {
        address owner = users[0];
        vm.prank(owner);
        vm.expectRevert(abi.encodeWithSelector(AddressRegistry.NoCIDNFTRegisteredForUser.selector, owner));
        addressRegistry.remove();
    }

    function testRemovePriorRegistration() public {
        uint256 nftIdOne = 1;
        address owner = users[0];

        // owner mint NFT
        vm.startPrank(owner);
        CidNFT.MintAddData[] memory addList;
        cidNFT.mint(addList);
        assertEq(cidNFT.ownerOf(nftIdOne), owner);

        // owner trys to register nft, succeed
        addressRegistry.register(nftIdOne);

        // validate the regisered CID
        uint256 cid = addressRegistry.getCID(owner);
        assertEq(cid, nftIdOne);

        // remove CID and validate the removal
        addressRegistry.remove();
        cid = addressRegistry.getCID(owner);
        assertEq(cid, 0);
    }

    function testRemoveSecondTime() public {
        uint256 nftIdOne = 1;
        address owner = users[0];

        // owner mint NFT
        vm.startPrank(owner);
        CidNFT.MintAddData[] memory addList;
        cidNFT.mint(addList);
        assertEq(cidNFT.ownerOf(nftIdOne), owner);

        // owner trys to register nft, succeed
        addressRegistry.register(nftIdOne);

        // validate the regisered CID
        uint256 cid = addressRegistry.getCID(owner);
        assertEq(cid, nftIdOne);

        // remove CID and validate the removal
        addressRegistry.remove();
        cid = addressRegistry.getCID(owner);
        assertEq(cid, 0);

        vm.expectRevert(abi.encodeWithSelector(AddressRegistry.NoCIDNFTRegisteredForUser.selector, owner));
        addressRegistry.remove();
    }
}
