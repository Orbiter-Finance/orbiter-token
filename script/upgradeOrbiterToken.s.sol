// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.26;

import {Script, console} from "forge-std/Script.sol";
import {JsonHelper} from "./utils/JsonHelper.sol";
import {Upgrades} from "openzeppelin-foundry-upgrades/Upgrades.sol";

contract DeployOrbiterToken is JsonHelper {
    function run() external {
        TokenInitInfo memory tokenInit = readTokenInitInfo();
        TokenNetwork memory tokenNetwork = readTokenNetwork(
            ETHEREUM_ORBITER_TOKEN
        );

        uint256 deployerPrivateKey = vm.envUint(
            "ORBITER_TOKEN_ADMIN_PRIVATE_KEY"
        );

        vm.startBroadcast(deployerPrivateKey);
        address deployer = vm.addr(deployerPrivateKey);
        require(deployer == tokenInit.admin, "Role Equal");

        vm.label(deployer, "Admin");

        Upgrades.upgradeProxy(
            tokenNetwork.addr,
            "OrbiterTokenV101.sol",
            "",
            deployer
        );

        vm.stopBroadcast();
    }
}
