// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.26;

import {Script, console} from "forge-std/Script.sol";
import {OrbiterToken} from "src/OrbiterToken.sol";
import {JsonHelper} from "./utils/JsonHelper.sol";
import {Upgrades} from "openzeppelin-foundry-upgrades/Upgrades.sol";

contract DeployOrbiterToken is JsonHelper {
    function run() external {
        address proxy;
        OrbiterToken token;

        TokenInitInfo memory tokenInit = readTokenInitInfo();

        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");

        vm.startBroadcast(deployerPrivateKey);
        address deployer = vm.addr(deployerPrivateKey);

        vm.label(deployer, "Deployer");
        vm.label(tokenInit.admin, "Admin");

        // Deploy OrbiterToken contract Proxy
        proxy = Upgrades.deployUUPSProxy(
            "OrbiterToken.sol",
            abi.encodeCall(
                OrbiterToken.initialize,
                (
                    tokenInit.name,
                    tokenInit.symbol,
                    tokenInit.supply * 10 ** 18,
                    tokenInit.admin
                )
            )
        );

        console.log("proxy:", proxy);

        token = OrbiterToken(proxy);

        writeTokenAddressToTokenNetwork(ETHEREUM_ORBITER_TOKEN, address(token));

        vm.stopBroadcast();
    }
}
