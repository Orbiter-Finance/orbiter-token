// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {InvalidAddr, ReachedMaximumSupplyLimit} from "src/libraries/Error.sol";
import {ERC20PermitUpgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC20PermitUpgradeable.sol";
import {AccessControlUpgradeable} from "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {UUPSUpgradeable} from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

/// @custom:oz-upgrades-from OrbiterToken
contract OrbiterTokenV101 is
    Initializable,
    ERC20PermitUpgradeable,
    AccessControlUpgradeable,
    UUPSUpgradeable
{
    // test scope
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    // bytes32 public constant BURNER_ROLE = keccak256("BURNER_ROLE");

    uint256 public MAX_SUPPLY_AMOUNT;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    /**
     * @dev Initialize function (replaces constructor for upgradeable contracts).
     */
    function initialize(
        string memory name,
        string memory symbol,
        uint256 max_supply_amount,
        address admin
    ) public initializer {
        __ERC20_init(name, symbol);
        __EIP712_init(name, "1");
        __ERC20Permit_init(name);
        __AccessControl_init();
        __UUPSUpgradeable_init();

        if (admin == address(0)) {
            revert InvalidAddr();
        }

        MAX_SUPPLY_AMOUNT = max_supply_amount;

        _grantRole(DEFAULT_ADMIN_ROLE, admin);
    }

    /**
     * @notice Mints `_amount` of tokens to `_account`.
     * @param _account The account to mint tokens to.
     * @param _amount The amount of tokens to mint.
     * @dev Reverts if the caller does not have the DEFAULT_ADMIN_ROLE.
     */
    function mint(
        address _account,
        uint256 _amount
    ) public onlyRole(DEFAULT_ADMIN_ROLE) {
        if (totalSupply() + _amount > MAX_SUPPLY_AMOUNT) {
            revert ReachedMaximumSupplyLimit();
        }
        _mint(_account, _amount);
    }

    // /**
    //  * @notice Burns `_value` of tokens from `_account`.
    //  * @param _account The account to burn tokens from.
    //  * @param _value The amount of tokens to burn.
    //  * @dev Reverts if the caller does not have the BURNER_ROLE.
    //  */
    // function burn(
    //     address _account,
    //     uint256 _value
    // ) public onlyRole(BURNER_ROLE) {
    //     _burn(_account, _value);
    // }

    // Upgrade authorization (only DEFAULT_ADMIN_ROLE)
    function _authorizeUpgrade(
        address newImplementation
    ) internal override onlyRole(DEFAULT_ADMIN_ROLE) {}

    function transferOwnership(
        address newOwner
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        grantRole(DEFAULT_ADMIN_ROLE, newOwner);
        renounceRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }
}
