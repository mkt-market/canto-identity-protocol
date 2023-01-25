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

    event OrderedDataAdded(
        uint256 indexed cidNFTID,
        string indexed subprotocolName,
        uint256 indexed key,
        uint256 subprotocolNFTID
    );

    Utilities internal utils;
    address payable[] internal users;

    address internal feeWallet;
    address internal user1;
    address internal user2;
    string internal constant BASE_URI = "tbd://base_uri/";

    MockToken internal note;
    SubprotocolRegistry internal subprotocolRegistry;
    SubprotocolNFT internal sub1;
    SubprotocolNFT internal sub2;
    CidNFT internal cidNFT;

    function setUp() public {
        utils = new Utilities();
        users = utils.createUsers(5);
        (feeWallet, user1, user2) = (users[0], users[1], users[2]);

        note = new MockToken();
        subprotocolRegistry = new SubprotocolRegistry(address(note), feeWallet);
        cidNFT = new CidNFT("MockCidNFT", "MCNFT", BASE_URI, feeWallet, address(note), address(subprotocolRegistry));
        sub1 = new SubprotocolNFT();
        sub2 = new SubprotocolNFT();

        note.mint(user1, 10000 * 1e18);
        vm.startPrank(user1);
        note.approve(address(subprotocolRegistry), type(uint256).max);
        subprotocolRegistry.register(true, true, true, address(sub1), "sub1", 0);
        subprotocolRegistry.register(true, true, true, address(sub2), "sub2", 0);
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

    function testMintWithMultiAddItems() public {
        uint256 tokenId = cidNFT.numMinted() + 1;

        // mint in subprotocol
        // todo: change the sub ids when CidNFT.add safeTransferFrom the correct id
        uint256 sub1Id = tokenId;
        uint256 sub2Id = tokenId;
        sub1.mint(address(this), sub1Id);
        sub1.approve(address(cidNFT), sub1Id);
        sub2.mint(address(this), sub2Id);
        sub2.approve(address(cidNFT), sub2Id);
        (uint256 key1, uint256 key2) = (0, 1);

        // todo: test more add items after bug fixed in CidNFT.add (safeTransferFrom id)
        bytes[] memory addList = new bytes[](2);
        addList[0] = abi.encode(tokenId, "sub1", key1, sub1Id, CidNFT.AssociationType.ORDERED);
        addList[1] = abi.encode(tokenId, "sub2", key2, sub2Id, CidNFT.AssociationType.ORDERED);
        cidNFT.mint(addList);
        // confirm mint
        assertEq(cidNFT.ownerOf(tokenId), address(this));
        // confirm data
        assertEq(cidNFT.getOrderedData(tokenId, "sub1", key1), sub1Id);
        assertEq(cidNFT.getOrderedData(tokenId, "sub2", key2), sub2Id);
    }

    function prepareAddOne(address subOwner) internal returns (uint256 tokenId, uint256 sub1Id, uint256 key1) {
        // mint without add
        tokenId = cidNFT.numMinted() + 1;
        assertEq(cidNFT.ownerOf(tokenId), address(0));
        cidNFT.mint(new bytes[](0));

        // mint in subprotocol
        // todo: change the sub id when CidNFT.add safeTransferFrom the correct id
        sub1Id = tokenId;
        sub1.mint(subOwner, sub1Id);
        vm.prank(subOwner);
        sub1.approve(address(cidNFT), sub1Id);
        key1 = 1;
    }

    function testAddAsCidOwner() public {
        (uint256 tokenId, uint256 sub1Id, uint256 key1) = prepareAddOne(address(this));

        // add as owner
        assertEq(cidNFT.ownerOf(tokenId), address(this));
        vm.expectEmit(true, true, true, true);
        emit OrderedDataAdded(tokenId, "sub1", key1, sub1Id);
        cidNFT.add(tokenId, "sub1", key1, sub1Id, CidNFT.AssociationType.ORDERED);

        // confirm data
        assertEq(cidNFT.getOrderedData(tokenId, "sub1", key1), sub1Id);
    }

    function testAddAsCidApprovedAccount() public {
        (uint256 tokenId, uint256 sub1Id, uint256 key1) = prepareAddOne(user1);
        cidNFT.approve(user1, tokenId);

        // add as approved account (user1)
        vm.startPrank(user1);
        vm.expectEmit(true, true, true, true);
        emit OrderedDataAdded(tokenId, "sub1", key1, sub1Id);
        cidNFT.add(tokenId, "sub1", key1, sub1Id, CidNFT.AssociationType.ORDERED);
        vm.stopPrank();

        // confirm data
        assertEq(cidNFT.getOrderedData(tokenId, "sub1", key1), sub1Id);
    }

    function testAddAsCidApprovedAllAccount() public {
        (uint256 tokenId, uint256 sub1Id, uint256 key1) = prepareAddOne(user2);
        cidNFT.setApprovalForAll(user2, true);

        // add as approved account (user1)
        vm.startPrank(user2);
        vm.expectEmit(true, true, true, true);
        emit OrderedDataAdded(tokenId, "sub1", key1, sub1Id);
        cidNFT.add(tokenId, "sub1", key1, sub1Id, CidNFT.AssociationType.ORDERED);
        vm.stopPrank();

        // confirm data
        assertEq(cidNFT.getOrderedData(tokenId, "sub1", key1), sub1Id);
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
