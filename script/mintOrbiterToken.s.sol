// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.26;

import {Script, console} from "forge-std/Script.sol";
import {OrbiterToken} from "src/OrbiterToken.sol";
import {JsonHelper} from "./utils/JsonHelper.sol";
import {Upgrades} from "openzeppelin-foundry-upgrades/Upgrades.sol";

contract MintOrbiterToken is JsonHelper {
    function run() external {
        TokenInitInfo memory tokenInit = readTokenInitInfo();
        TokenNetwork memory tokenNetwork = readTokenNetwork(
            ETHEREUM_ORBITER_TOKEN
        );

        uint256 deployerPrivateKey = vm.envUint("ADMIN_PRIVATE_KEY");

        vm.startBroadcast(deployerPrivateKey);
        address admin = vm.addr(deployerPrivateKey);

        require(admin == tokenInit.admin);

        vm.label(admin, "Admin");

        OrbiterToken token = OrbiterToken(tokenNetwork.addr);

        token.mint(readTokenNetworkOwner(), tokenNetwork.amount * 10 ** 18);

        vm.stopBroadcast();
    }
}
