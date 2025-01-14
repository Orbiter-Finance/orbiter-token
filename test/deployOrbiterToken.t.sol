// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import "forge-std/Test.sol";
import "../src/OrbiterToken.sol";
import {Upgrades} from "openzeppelin-foundry-upgrades/Upgrades.sol";

contract OrbiterTokenTest is Test {
    address public proxy;
    OrbiterToken public token;

    address public deployer;
    address public admin;
    address public user;

    uint256 max_supply = 1000000 * 10 ** 18;

    function setUp() public {
        // Initialize test accounts
        deployer = address(1);
        admin = address(2);
        user = address(4);

        vm.label(admin, "admin");
        vm.label(user, "user");

        vm.startPrank(deployer);

        // Deploy the Orbiter contract Proxy
        proxy = Upgrades.deployUUPSProxy(
            "OrbiterToken.sol",
            abi.encodeCall(
                OrbiterToken.initialize,
                ("Orbiter Token", "OBT", max_supply, admin)
            )
        );

        vm.stopPrank();

        token = OrbiterToken(proxy);
    }

    function testMint() public {
        uint256 mintAmount = 1000 * 10 ** 18;

        // Mint tokens to user
        vm.prank(admin); // Simulates `admin` as the msg.sender
        token.mint(user, mintAmount);

        // Verify user balance
        assertEq(token.balanceOf(user), mintAmount);
    }

    function testTransfer() public {
        uint256 mintAmount = 1000 * 10 ** 18;

        // Mint tokens to user
        vm.prank(admin);
        token.mint(user, mintAmount);

        // Transfer tokens from user to another account
        address recipient = address(5);
        uint256 transferAmount = 400 * 10 ** 18;

        vm.prank(user); // Simulates `user` as the msg.sender
        token.transfer(recipient, transferAmount);

        // Verify balances
        assertEq(token.balanceOf(user), mintAmount - transferAmount);
        assertEq(token.balanceOf(recipient), transferAmount);
    }

    function testRevertWhenMintWithoutRole() public {
        uint256 mintAmount = 1000 * 10 ** 18;

        // Attempt to mint tokens without the MINTER_ROLE
        vm.expectRevert(); // Expect the transaction to revert
        token.mint(user, mintAmount);
    }

    function testRevertWhenUpgradeWithoutRole() public {
        vm.expectRevert(); // Expect the transaction to revert
        vm.prank(deployer);
        token.transferOwnership(user);

        vm.prank(admin);
        token.transferOwnership(user);

        vm.expectRevert(); // Expect the transaction to revert
        vm.prank(admin);
        token.transferOwnership(user);
    }
}
