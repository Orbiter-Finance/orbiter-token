// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import "forge-std/Test.sol";
import "src/LockedTokenGov.sol";
import "src/LockedTokenGrant.sol";
import "src/OrbiterToken.sol";
import {Upgrades} from "openzeppelin-foundry-upgrades/Upgrades.sol";

contract DeployLockedTokenTest is Test {
    address public govProxy;
    LockedTokenGov public gov;

    address public deployer;
    address public admin;
    address public user;
    address public minter;

    // token configs
    address public tokenProxy;
    OrbiterToken public token;
    uint256 max_supply = 1000000 * 10 ** 18;

    uint256 minter_amount = 1000 * 10 ** 18;

    uint256 user_grant_amount = 100 * 10 ** 18;

    function setUp() public {
        // Initialize test accounts
        deployer = address(1);
        admin = address(2);
        minter = address(3);
        user = address(4);

        vm.label(deployer, "Deployer");
        vm.label(admin, "Admin");
        vm.label(minter, "Minter");
        vm.label(user, "User");

        vm.startPrank(deployer);

        // Deploy the Orbiter Token Proxy
        tokenProxy = Upgrades.deployUUPSProxy(
            "OrbiterToken.sol",
            abi.encodeCall(
                OrbiterToken.initialize,
                ("Orbiter Token", "OBT", max_supply, admin)
            )
        );

        token = OrbiterToken(tokenProxy);

        // Deploy the Orbiter contract Proxy
        govProxy = Upgrades.deployUUPSProxy(
            "LockedTokenGov.sol",
            abi.encodeCall(LockedTokenGov.initialize, (address(token), admin))
        );

        gov = LockedTokenGov(govProxy);

        vm.stopPrank();

        vm.prank(admin);
        token.mint(minter, minter_amount);
    }

    function testNewLockedTokenGrant() public {
        vm.prank(minter);
        token.approve(address(gov), user_grant_amount);
        vm.prank(admin);
        gov.grantLockedTokens(user, user_grant_amount, minter);
    }

    function testRevertWhenNotLockedToken() public {
        vm.prank(minter);
        token.approve(address(gov), user_grant_amount);
        vm.prank(admin);
        address userGrant = gov.grantLockedTokens(
            user,
            user_grant_amount,
            minter
        );

        LockedTokenGrant grant = LockedTokenGrant(userGrant);

        vm.expectRevert();
        vm.prank(user);
        grant.releaseTokens(user_grant_amount);
    }

    function testRevertWhenSetUnlockTokenNoRole() public {
        vm.prank(minter);
        token.approve(address(gov), user_grant_amount);
        vm.prank(admin);
        address userGrant = gov.grantLockedTokens(
            user,
            user_grant_amount,
            minter
        );

        LockedTokenGrant grant = LockedTokenGrant(userGrant);

        vm.expectRevert();
        vm.prank(user);
        grant.setUnlockedTokensAmount(user_grant_amount);
    }

    function testReleaseTokens() public {
        vm.prank(minter);
        token.approve(address(gov), user_grant_amount);
        vm.prank(admin);
        address userGrant = gov.grantLockedTokens(
            user,
            user_grant_amount,
            minter
        );

        LockedTokenGrant grant = LockedTokenGrant(userGrant);

        // check tokens
        require(grant.grantAmount() == user_grant_amount, "grantAmount");
        require(grant.availableTokens() == 0, "availableTokens");
        require(grant.releasedTokens() == 0, "releasedTokens");

        uint256 unlockedTokensAmount = user_grant_amount / 2; // 50 tokens

        vm.prank(admin);
        gov.setUnlockedTokensAmount(user, unlockedTokensAmount);

        console.log(
            "grant erc20 balance before:",
            token.balanceOf(address(grant)) / 10 ** 18
        );
        console.log(
            "user erc20 balance before:",
            token.balanceOf(user) / 10 ** 18
        );

        uint256 releaseTokensAmount = user_grant_amount / 4; // 25 tokens

        vm.prank(user);
        grant.releaseTokens(releaseTokensAmount);

        require(
            grant.availableTokens() ==
                unlockedTokensAmount - releaseTokensAmount,
            "availableTokens"
        );
        require(
            grant.releasedTokens() == releaseTokensAmount,
            "releasedTokens"
        );

        console.log(
            "grant erc20 balance after:",
            token.balanceOf(address(grant)) / 10 ** 18
        );
        console.log(
            "user erc20 balance after:",
            token.balanceOf(user) / 10 ** 18
        );

        console.log(
            "releasedTokens %t,unlockedTokens %t",
            grant.releasedTokens() / 10 ** 18,
            grant.unlockedTokens() / 10 ** 18
        );
    }
}
