// SPDX-License-Identifier: GPL-3.0-only
pragma solidity >=0.8.0;

import {DSTest} from "ds-test/test.sol";
import {Utilities} from "./utils/Utilities.sol";
import {console} from "./utils/Console.sol";
import {Vm} from "forge-std/Vm.sol";
import "../AddressRegistry.sol";
import "../SubprotocolRegistry.sol";
import "../CidSubprotocolNFT.sol";
import "./mock/MockERC20.sol";

contract SubprotocolNFT is CidSubprotocolNFT {

    constructor() ERC721("MockNFT", "MNFT") {}

    function isActive(uint256 _nftID) public override returns (bool active) {
        return true;
    }

    function tokenURI(uint256 id) public view override returns (string memory) {
        return "";
    }

}

contract AddressRegistryTest is DSTest {

    Vm internal immutable vm = Vm(HEVM_ADDRESS);

    Utilities internal utils;
    address payable[] internal users;
    AddressRegistry internal addressRegistry;

    SubprotocolRegistry subprotocolRegistry; 
    MockToken token;

    address feeWallet;
    address user1;
    address user2;

    uint256 feeAmount;

    function setUp() public {

        utils = new Utilities();
        users = utils.createUsers(5);

        user1 = users[0];
        user2 = users[1];
        feeWallet = users[2];
        
        token = new MockToken();
        subprotocolRegistry = new SubprotocolRegistry(
            address(token),
            feeWallet
        );

        feeAmount = subprotocolRegistry.REGISTER_FEE();

        vm.prank(user1);
        token.approve(address(subprotocolRegistry), type(uint256).max);
        token.mint(user1, feeAmount * 100);

    }

    function testRegisterDifferentAssociation() public {

        vm.startPrank(user1);
        SubprotocolNFT subprotocolNFTOne = new SubprotocolNFT();
        subprotocolRegistry.register(
            true,
            false, 
            false,
            address(subprotocolNFTOne), 
            "subprotocol1",
            0
        );

        assertEq(token.balanceOf(feeWallet), feeAmount);

        SubprotocolNFT subprotocolNFTTwo = new SubprotocolNFT();
        subprotocolRegistry.register(
            true,
            true,
            false, 
            address(subprotocolNFTTwo), 
            "subprotocol2",
            100
        );

        assertEq(token.balanceOf(feeWallet), feeAmount * 2);

        subprotocolRegistry.register(
            true,
            true,
            true, 
            address(subprotocolNFTTwo), 
            "subprotocol3",
            100
        );

        assertEq(token.balanceOf(feeWallet), feeAmount * 3);

        subprotocolRegistry.register(
            true,
            false,
            true, 
            address(subprotocolNFTTwo), 
            "subprotocol4",
            5034
        );

        assertEq(token.balanceOf(feeWallet), feeAmount * 4);


    }

    function testRegisterExistedProtocol() public {

        vm.startPrank(user1);
        string memory name = "subprotocol1";
        SubprotocolNFT subprotocolNFTOne = new SubprotocolNFT();

        subprotocolRegistry.register(
            true,
            false, 
            false,
            address(subprotocolNFTOne), 
            name,
            0
        );

        vm.expectRevert(
            abi.encodeWithSelector(
                SubprotocolRegistry.SubprotocolAlreadyExists.selector, 
                name,
                user1
            )
        );
        subprotocolRegistry.register(
            true,
            false,
            false,
            address(subprotocolNFTOne), 
            name,
            0
        );

    }

}
