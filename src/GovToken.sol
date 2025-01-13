// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

// import {IBridge} from "src/interfaces/IBridge.sol";
import {NotSupportToken, InvalidAddr, InvalidAmount, InvalidData, InsufficientBalance, InvalidPauseState, InvalidSignature, Timeout, ContractPausedStateError} from "src/libraries/Error.sol";
import {ERC20PermitUpgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC20PermitUpgradeable.sol";
import {ReentrancyGuardUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol";
import {AccessControlUpgradeable} from "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

contract GovToken is
    Initializable,
    ERC20PermitUpgradeable,
    AccessControlUpgradeable
{
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant BURNER_ROLE = keccak256("BURNER_ROLE");

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
        address admin
    ) public initializer {
        __ERC20_init(name, symbol);
        __EIP712_init(name, "1");
        __ERC20Permit_init(name);
        __AccessControl_init();

        if (admin == address(0)) {
            revert InvalidAddr();
        }

        _grantRole(DEFAULT_ADMIN_ROLE, admin);
    }

    /**
     * @notice Mints `_amount` of tokens to `_account`.
     * @param _account The account to mint tokens to.
     * @param _amount The amount of tokens to mint.
     * @dev Reverts if the caller does not have the MINTER_ROLE.
     */
    function mint(
        address _account,
        uint256 _amount
    ) public onlyRole(MINTER_ROLE) {
        _mint(_account, _amount);
    }

    /**
     * @notice Burns `_value` of tokens from `_account`.
     * @param _account The account to burn tokens from.
     * @param _value The amount of tokens to burn.
     * @dev Reverts if the caller does not have the BURNER_ROLE.
     */
    function burn(
        address _account,
        uint256 _value
    ) public onlyRole(BURNER_ROLE) {
        _burn(_account, _value);
    }
}
