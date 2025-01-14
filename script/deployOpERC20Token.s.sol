// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.26;

import {JsonHelper} from "./utils/JsonHelper.sol";
import {Script, console} from "forge-std/Script.sol";
import {IOptimismMintableERC20Factory} from "src/interfaces/IOptimismMintableERC20Factory.sol";

contract DeployOpERC20Token is JsonHelper {
    function run() external {
        TokenInitInfo memory tokenInit = readTokenInitInfo();
        TokenNetwork memory tokenNetwork = readTokenNetwork(
            ETHEREUM_ORBITER_TOKEN
        );

        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address factoryAddress = vm.envAddress(
            "OPTIMISM_MINTABLE_ERC20FACTORY"
        );

        vm.startBroadcast(deployerPrivateKey);
        address deployer = vm.addr(deployerPrivateKey);

        vm.label(deployer, "Deployer");

        IOptimismMintableERC20Factory factory = IOptimismMintableERC20Factory(
            factoryAddress
        );

        address token = factory.createOptimismMintableERC20(
            tokenNetwork.addr,
            tokenInit.name,
            tokenInit.symbol
        );

        console.log("token:", token);

        writeTokenAddressToTokenNetwork(Base_ORBITER_TOKEN, token);

        vm.stopBroadcast();
    }
}
