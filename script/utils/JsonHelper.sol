// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.26;
import {Script, console, stdJson} from "forge-std/Script.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract JsonHelper is Script {
    string public constant TokenInitPath = "/config/tokenInit.json";
    string public constant TokenNetworkPath = "/config/tokenNetwork.json";

    struct TokenInitInfo {
        string name;
        string symbol;
        address admin;
        uint256 supply;
    }

    function readTokenInitInfo() public view returns (TokenInitInfo memory) {
        string memory root = vm.projectRoot();
        string memory filePath = string.concat(root, TokenInitPath);
        string memory jsonContent = vm.readFile(filePath);
        TokenInitInfo memory info;
        info.name = vm.parseJsonString(
            jsonContent,
            string(abi.encodePacked(".", "name"))
        );
        info.symbol = vm.parseJsonString(
            jsonContent,
            string(abi.encodePacked(".", "symbol"))
        );
        info.admin = vm.parseJsonAddress(
            jsonContent,
            string(abi.encodePacked(".", "admin"))
        );
        info.supply = vm.parseJsonUint(
            jsonContent,
            string(abi.encodePacked(".", "supply"))
        );
        return info;
    }

    string public constant ETHEREUM_ORBITER_TOKEN = "EthereumOrbiterToken";
    string public constant Base_ORBITER_TOKEN = "BaseOrbiterToken";

    struct TokenNetwork {
        address addr;
        uint256 amount;
    }

    function readTokenNetworkOwner() public view returns (address) {
        string memory root = vm.projectRoot();
        string memory filePath = string.concat(root, TokenNetworkPath);

        string memory jsonContent = vm.readFile(filePath);

        return
            vm.parseJsonAddress(
                jsonContent,
                string(abi.encodePacked(".", "Owner"))
            );
    }

    function readTokenNetwork(
        string memory network
    ) public view returns (TokenNetwork memory) {
        string memory root = vm.projectRoot();
        string memory filePath = string.concat(root, TokenNetworkPath);

        string memory jsonContent = vm.readFile(filePath);
        TokenNetwork memory info;
        info.addr = vm.parseJsonAddress(
            jsonContent,
            string(abi.encodePacked(".", network, ".", "address"))
        );
        info.amount = vm.parseJsonUint(
            jsonContent,
            string(abi.encodePacked(".", network, ".", "amount"))
        );

        return info;
    }

    function writeTokenAddressToTokenNetwork(
        string memory network,
        address token
    ) public {
        string memory root = vm.projectRoot();
        string memory filePath = string.concat(root, TokenNetworkPath);

        string memory value = addressToString(token);
        vm.writeJson(
            value,
            filePath,
            string(abi.encodePacked(".", network, ".", "address"))
        );
    }

    function addressToString(
        address _address
    ) internal pure returns (string memory) {
        bytes32 value = bytes32(uint256(uint160(_address)));
        bytes memory alphabet = "0123456789abcdef";

        bytes memory str = new bytes(42);
        str[0] = "0";
        str[1] = "x";
        for (uint256 i = 0; i < 20; i++) {
            str[2 + i * 2] = alphabet[uint8(value[i + 12] >> 4)];
            str[3 + i * 2] = alphabet[uint8(value[i + 12] & 0x0f)];
        }
        return string(str);
    }
}
