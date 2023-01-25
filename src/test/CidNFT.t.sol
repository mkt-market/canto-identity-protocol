// SPDX-License-Identifier: GPL-3.0-only
pragma solidity >=0.8.0;

import {Vm} from "forge-std/Vm.sol";
import {DSTest} from "ds-test/test.sol";
import {Utilities} from "./utils/Utilities.sol";
import {console} from "./utils/Console.sol";
import "../CidNFT.sol";
import "../SubprotocolRegistry.sol";
import "./mock/MockERC20.sol";
import "./mock/SubprotocolNFT.sol";

contract CidNFTTest is DSTest {
    Vm internal immutable vm = Vm(HEVM_ADDRESS);

    Utilities internal utils;
    address payable[] internal users;

    address internal feeWallet;
    address internal user1;
    address internal user2;
    string internal constant BASE_URI = "tbd://base_uri/";

    MockToken internal note;
    SubprotocolRegistry internal subprotocolRegistry;
    SubprotocolNFT internal sub1;
    CidNFT internal cidNFT;

    function setUp() public {
        utils = new Utilities();
        users = utils.createUsers(5);
        (feeWallet, user1, user2) = (users[0], users[1], users[2]);

        note = new MockToken();
        subprotocolRegistry = new SubprotocolRegistry(address(note), feeWallet);
        cidNFT = new CidNFT("MockCidNFT", "MCNFT", BASE_URI, feeWallet, address(note), address(subprotocolRegistry));
        sub1 = new SubprotocolNFT();

        note.mint(user1, 10000 * 1e18);
        vm.startPrank(user1);
        note.approve(address(subprotocolRegistry), type(uint256).max);
        subprotocolRegistry.register(true, true, true, address(sub1), "sub1", 0);
        vm.stopPrank();
    }

    function testAddID0() public {
        // Should revert if trying to add NFT ID 0
        vm.expectRevert(abi.encodeWithSelector(CidNFT.NotAuthorizedForCIDNFT.selector, address(this), 0, address(0)));
        cidNFT.add(0, "sub1", 1, 1, CidNFT.AssociationType.ORDERED);
    }

    function testAddNonExistingSubprotocol() public {
        // Should revert if add data for non-existing subprotocol
        vm.expectRevert(abi.encodeWithSelector(CidNFT.SubprotocolDoesNotExist.selector, "NonExisting"));
        cidNFT.add(0, "NonExisting", 1, 1, CidNFT.AssociationType.ORDERED);
    }

    function testRemoveNonExistingSubprotocol() public {
        uint256 tokenId = cidNFT.numMinted() + 1;
        cidNFT.mint(new bytes[](0));
        // Should revert if remove with non-existing subprotocol
        vm.expectRevert(abi.encodeWithSelector(CidNFT.SubprotocolDoesNotExist.selector, "NonExisting"));
        cidNFT.remove(tokenId, "NonExisting", 1, 1, CidNFT.AssociationType.ORDERED);
    }

    function testMintWithoutAddList() public {
        // mint by this
        cidNFT.mint(new bytes[](0));
        uint256 tokenId = cidNFT.numMinted();
        assertEq(cidNFT.ownerOf(tokenId), address(this));

        // mint by user1
        vm.startPrank(user1);
        cidNFT.mint(new bytes[](0));
        tokenId = cidNFT.numMinted();
        assertEq(cidNFT.ownerOf(tokenId), user1);
        vm.stopPrank();
    }

    function testMintWithSingleAddList() public {
        uint256 tokenId = cidNFT.numMinted() + 1;
        // tokenId not minted yet
        assertEq(cidNFT.ownerOf(tokenId), address(0));

        // mint in subprotocol
        uint256 subId = tokenId;
        sub1.mint(address(this), subId);
        sub1.setApprovalForAll(address(cidNFT), true);

        bytes[] memory addList = new bytes[](1);
        addList[0] = abi.encode(tokenId, "sub1", 0, subId, CidNFT.AssociationType.ORDERED);
        cidNFT.mint(addList);
        // confirm mint
        assertEq(cidNFT.ownerOf(tokenId), address(this));
    }

    function testTokenURI() public {
        uint256 id1 = cidNFT.numMinted() + 1;
        uint256 id2 = cidNFT.numMinted() + 2;
        uint256 nonExistId = cidNFT.numMinted() + 3;
        // mint id1
        cidNFT.mint(new bytes[](0));
        // mint id2
        cidNFT.mint(new bytes[](0));

        // exist id
        assertEq(cidNFT.tokenURI(id1), string(abi.encodePacked(BASE_URI, id1, ".json")));
        assertEq(cidNFT.tokenURI(id2), string(abi.encodePacked(BASE_URI, id2, ".json")));

        // non-exist id
        vm.expectRevert(abi.encodeWithSelector(CidNFT.TokenNotMinted.selector, nonExistId));
        cidNFT.tokenURI(nonExistId);
    }
}
