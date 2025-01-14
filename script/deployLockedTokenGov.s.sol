// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.26;

import {JsonHelper} from "./utils/JsonHelper.sol";
import {Script, console} from "forge-std/Script.sol";
import {LockedTokenGov} from "src/LockedTokenGov.sol";
import {Upgrades} from "openzeppelin-foundry-upgrades/Upgrades.sol";

contract DeployLockedTokenGov is JsonHelper {
    function run() external {
        address proxy;
        LockedTokenGov gov;

        TokenNetwork memory tokenNetwork = readTokenNetwork(
            ETHEREUM_ORBITER_TOKEN
        );

        address admin = readLockedTokenGovAdmin();

        console.log("admin :", admin);

        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");

        vm.startBroadcast(deployerPrivateKey);
        address deployer = vm.addr(deployerPrivateKey);

        vm.label(deployer, "Deployer");

        proxy = Upgrades.deployUUPSProxy(
            "LockedTokenGov.sol",
            abi.encodeCall(
                LockedTokenGov.initialize,
                (tokenNetwork.addr, admin)
            )
        );

        gov = LockedTokenGov(proxy);

        writeLockedTokenGovAddress(proxy);

        vm.stopBroadcast();
    }
}
