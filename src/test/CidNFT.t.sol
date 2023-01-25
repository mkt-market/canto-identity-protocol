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

    function testCannotRemoveNonExistingEntry() public {
        uint256 tokenId = cidNFT.numMinted() + 1;
        cidNFT.mint(new bytes[](0));

        // NFT id that does not exist
        uint256 nftIDToRemove = 1;

        // Should revert when non-existing entry is inputted
        vm.expectRevert(
            abi.encodeWithSelector(
                CidNFT.ActiveArrayDoesNotContainID.selector,
                tokenId,
                "sub1",
                nftIDToRemove
            )
        );
        cidNFT.remove(
            tokenId,
            "sub1",
            0,
            nftIDToRemove,
            CidNFT.AssociationType.ACTIVE
        );
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
        uint256 sub1Id = 12;
        uint256 sub2Id = 34;
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

    function testMintWithMultiAddItemsAndRevert() public {
        uint256 tokenId = cidNFT.numMinted() + 1;

        // mint in subprotocol
        uint256 sub1Id = 12;
        uint256 sub2Id = 34;
        sub1.mint(address(this), sub1Id);
        sub1.approve(address(cidNFT), sub1Id);
        sub2.mint(address(this), sub2Id);
        // sub2 not approved
        // sub2.approve(address(cidNFT), sub2Id);
        (uint256 key1, uint256 key2) = (0, 1);

        bytes[] memory addList = new bytes[](2);
        addList[0] = abi.encode(tokenId, "sub1", key1, sub1Id, CidNFT.AssociationType.ORDERED);
        addList[1] = abi.encode(tokenId, "sub2", key2, sub2Id, CidNFT.AssociationType.ORDERED);

        // revert by add[1]
        vm.expectRevert(abi.encodeWithSelector(CidNFT.AddCallAfterMintingFailed.selector, 1));
        cidNFT.mint(addList);
        // tokenId of CidNFT is not minted
        assertEq(cidNFT.ownerOf(tokenId), address(0));
        // confirm data - not added
        assertEq(cidNFT.getOrderedData(tokenId, "sub1", key1), 0);
        assertEq(cidNFT.getOrderedData(tokenId, "sub2", key2), 0);
        // sub NFTs are not transferred
        assertEq(sub1.ownerOf(sub1Id), address(this));
        assertEq(sub2.ownerOf(sub2Id), address(this));
    }

    function prepareAddOne(address subOwner)
        internal
        returns (
            uint256 tokenId,
            uint256 sub1Id,
            uint256 key1
        )
    {
        // mint without add
        tokenId = cidNFT.numMinted() + 1;

        assertEq(cidNFT.ownerOf(tokenId), address(0));
        cidNFT.mint(new bytes[](0));

        // mint in subprotocol
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

        // add as approved account
        vm.startPrank(user2);
        vm.expectEmit(true, true, true, true);
        emit OrderedDataAdded(tokenId, "sub1", key1, sub1Id);
        cidNFT.add(tokenId, "sub1", key1, sub1Id, CidNFT.AssociationType.ORDERED);
        vm.stopPrank();

        // confirm data
        assertEq(cidNFT.getOrderedData(tokenId, "sub1", key1), sub1Id);
    }

    function testAddFromCidUnauthorizedAccount() public {
        (uint256 tokenId, uint256 sub1Id, uint256 key1) = prepareAddOne(user2);

        // add as unauthorized account
        vm.startPrank(user2);
        vm.expectRevert(abi.encodeWithSelector(CidNFT.NotAuthorizedForCIDNFT.selector, user2, tokenId, address(this)));
        cidNFT.add(tokenId, "sub1", key1, sub1Id, CidNFT.AssociationType.ORDERED);
        vm.stopPrank();
    }

    function tryAddType(
        bool valid,
        string memory subName,
        CidNFT.AssociationType aType
    ) internal {
        (uint256 tokenId, uint256 sub1Id, uint256 key) = prepareAddOne(address(this));
        if (!valid) {
            vm.expectRevert(
                abi.encodeWithSelector(CidNFT.AssociationTypeNotSupportedForSubprotocol.selector, aType, subName)
            );
        }
        cidNFT.add(tokenId, subName, key, sub1Id, aType);
    }

    function testAddUnsupportedAssociationType() public {
        // register different subprotocols
        vm.startPrank(user1);
        subprotocolRegistry.register(true, false, false, address(sub1), "OrderedOnly", 0);
        subprotocolRegistry.register(false, true, false, address(sub1), "PrimaryOnly", 0);
        subprotocolRegistry.register(false, false, true, address(sub1), "ActiveOnly", 0);
        subprotocolRegistry.register(true, true, false, address(sub1), "OrderedAndPrimary", 0);
        subprotocolRegistry.register(true, false, true, address(sub1), "OrderedAndActive", 0);
        subprotocolRegistry.register(false, true, true, address(sub1), "PrimaryAndActive", 0);
        subprotocolRegistry.register(true, true, true, address(sub1), "AllTypes", 0);
        vm.stopPrank();

        // OrderedOnly
        tryAddType(true, "OrderedOnly", CidNFT.AssociationType.ORDERED);
        tryAddType(false, "OrderedOnly", CidNFT.AssociationType.PRIMARY);
        tryAddType(false, "OrderedOnly", CidNFT.AssociationType.ACTIVE);
        // PrimaryOnly
        tryAddType(false, "PrimaryOnly", CidNFT.AssociationType.ORDERED);
        tryAddType(true, "PrimaryOnly", CidNFT.AssociationType.PRIMARY);
        tryAddType(false, "PrimaryOnly", CidNFT.AssociationType.ACTIVE);
        // ActiveOnly
        tryAddType(false, "ActiveOnly", CidNFT.AssociationType.ORDERED);
        tryAddType(false, "ActiveOnly", CidNFT.AssociationType.PRIMARY);
        tryAddType(true, "ActiveOnly", CidNFT.AssociationType.ACTIVE);
        // OrderedAndPrimary
        tryAddType(true, "OrderedAndPrimary", CidNFT.AssociationType.ORDERED);
        tryAddType(true, "OrderedAndPrimary", CidNFT.AssociationType.PRIMARY);
        tryAddType(false, "OrderedAndPrimary", CidNFT.AssociationType.ACTIVE);
        // OrderedAndActive
        tryAddType(true, "OrderedAndActive", CidNFT.AssociationType.ORDERED);
        tryAddType(false, "OrderedAndActive", CidNFT.AssociationType.PRIMARY);
        tryAddType(true, "OrderedAndActive", CidNFT.AssociationType.ACTIVE);
        // PrimaryAndActive
        tryAddType(false, "PrimaryAndActive", CidNFT.AssociationType.ORDERED);
        tryAddType(true, "PrimaryAndActive", CidNFT.AssociationType.PRIMARY);
        tryAddType(true, "PrimaryAndActive", CidNFT.AssociationType.ACTIVE);
        // AllTypes
        tryAddType(true, "AllTypes", CidNFT.AssociationType.ORDERED);
        tryAddType(true, "AllTypes", CidNFT.AssociationType.PRIMARY);
        tryAddType(true, "AllTypes", CidNFT.AssociationType.ACTIVE);
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
