// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.23;

import {Script, console} from "forge-std/Script.sol";
import "src/GovToken.sol";
import {Upgrades} from "openzeppelin-foundry-upgrades/Upgrades.sol";

contract DeployBridge is Script {
    function run() external {
        address proxy;
        GovToken token;

        // role
        address admin;

        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");

        vm.startBroadcast(deployerPrivateKey);
        address deployer = vm.addr(deployerPrivateKey);
        admin = deployer;

        vm.label(deployer, "Deployer");
        vm.label(admin, "Admin");

        // Deploy GovToken contract Proxy
        proxy = Upgrades.deployUUPSProxy(
            "GovToken.sol",
            abi.encodeCall(GovToken.initialize, ("Orbiter", "ORB", admin))
        );

        console.log("proxy:", proxy);

        token = GovToken(proxy);

        console.log("token:", address(token));

        vm.stopBroadcast();
    }
}
