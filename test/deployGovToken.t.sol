// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import "forge-std/Test.sol";
import "../src/GovToken.sol";
import {Upgrades} from "openzeppelin-foundry-upgrades/Upgrades.sol";

contract GovTokenTest is Test {
    address public proxy;
    GovToken public govToken;
    address public admin;
    address public minter;
    address public burner;
    address public user;

    function setUp() public {
        // Initialize test accounts
        admin = address(1);
        user = address(4);

        vm.label(admin, "admin");
        vm.label(user, "user");

        // Deploy the GovToken contract Proxy
        proxy = Upgrades.deployUUPSProxy(
            "GovToken.sol",
            abi.encodeCall(GovToken.initialize, ("Orbiter", "ORB", admin))
        );

        govToken = GovToken(proxy);
    }

    function testMint() public {
        uint256 mintAmount = 1000 * 10 ** 18;

        // Mint tokens to user
        vm.prank(admin); // Simulates `admin` as the msg.sender
        govToken.mint(user, mintAmount);

        // Verify user balance
        assertEq(govToken.balanceOf(user), mintAmount);
    }

    // function testBurn() public {
    //     uint256 mintAmount = 1000 * 10 ** 18;
    //     uint256 burnAmount = 500 * 10 ** 18;

    //     // Mint tokens to user
    //     vm.prank(minter);
    //     govToken.mint(user, mintAmount);

    //     // Burn tokens from user
    //     vm.prank(burner);
    //     govToken.burn(user, burnAmount);

    //     // Verify user balance
    //     assertEq(govToken.balanceOf(user), mintAmount - burnAmount);
    // }

    function testTransfer() public {
        uint256 mintAmount = 1000 * 10 ** 18;

        // Mint tokens to user
        vm.prank(admin);
        govToken.mint(user, mintAmount);

        // Transfer tokens from user to another account
        address recipient = address(5);
        uint256 transferAmount = 400 * 10 ** 18;

        vm.prank(user); // Simulates `user` as the msg.sender
        govToken.transfer(recipient, transferAmount);

        // Verify balances
        assertEq(govToken.balanceOf(user), mintAmount - transferAmount);
        assertEq(govToken.balanceOf(recipient), transferAmount);
    }

    function testRevertWhenMintWithoutRole() public {
        uint256 mintAmount = 1000 * 10 ** 18;

        // Attempt to mint tokens without the MINTER_ROLE
        vm.expectRevert(); // Expect the transaction to revert
        govToken.mint(user, mintAmount);
    }

    // function testRevertWhenBurnWithoutRole() public {
    //     uint256 burnAmount = 500 * 10 ** 18;

    //     // Attempt to burn tokens without the BURNER_ROLE
    //     vm.expectRevert(); // Expect the transaction to revert
    //     govToken.burn(user, burnAmount);
    // }
}
