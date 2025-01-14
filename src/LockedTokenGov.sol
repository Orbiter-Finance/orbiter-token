// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {TransferFailed} from "src/libraries/Error.sol";
import {LockedTokenGrant} from "src/LockedTokenGrant.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {UUPSUpgradeable} from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

/**
  The {LockedTokenCommon} contract serves one purposes:
  1. Allocate locked token grants in {LockedTokenGrant} contracts.

  Roles:
  =====
  1. At initializtion time, admin is defined as owner.

  Grant Locked Tokens:
  ===================
  Locked token grants are granted using the `grantLockedTokens` here.
  The arguments passed are:
  - recipient - The address of the tokens "owner". When the tokens get unlocked, they can be released
                to the recipient address, and only there.
  - amount    - The number of tokens to be transfered onto the grant contract upon creation.
  - allocationPool - The {LockedTokenCommon} doesn't hold liquidity from which it can grant the tokens,
                     but rather uses an external LP for that. The `allocationPool` is the address of the LP
                     from which the tokens shall be allocated. The {LockedTokenCommon} must have sufficient allowance
                     on the `allocationPool` so it can transfer funds from it onto the creatred grant contract.

    Flow: The {LockedTokenCommon} deploys the contract of the new {LockedTokenGrant},
          transfer the grant amount from the allocationPool onto the new grant,
          and register the new grant in a mapping.
*/
contract LockedTokenGov is Initializable, OwnableUpgradeable, UUPSUpgradeable {
    IERC20 public token;
    LockedTokenGrant public grantImplementation;

    // Maps recipient to its locked grant contract.
    mapping(address => address) public grantByRecipient;

    event LockedTokenGranted(
        address indexed recipient,
        address indexed grantContract,
        uint256 grantAmount
    );

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(
        address tokenAddress,
        address admin
    ) public initializer {
        __Ownable_init(admin);
        __UUPSUpgradeable_init();

        token = IERC20(tokenAddress);
        grantImplementation = new LockedTokenGrant();
    }

    function setUnlockedTokensAmount(
        address recipient,
        uint256 unlockedTokensAmount
    ) external onlyOwner {
        require(grantByRecipient[recipient] != address(0x0));
        LockedTokenGrant(grantByRecipient[recipient]).setUnlockedTokensAmount(
            unlockedTokensAmount
        );
    }

    /**
      Deploys a LockedTokenGrant and transfers `grantAmount` tokens onto it.
      Returns the address of the LockedTokenGrant contract.

      Tokens owned by the {LockedTokenGrant} are initially locked, and can only be used for staking.
      The tokens gradually unlocked and can be transferred to the `recipient`.
    */
    function grantLockedTokens(
        address recipient,
        uint256 grantAmount,
        address allocationPool
    ) external onlyOwner returns (address) {
        require(grantByRecipient[recipient] == address(0x0), "ALREADY_GRANTED");

        address grantAddress = address(
            LockedTokenGrant(
                payable(
                    new ERC1967Proxy(
                        address(grantImplementation),
                        abi.encodeCall(
                            LockedTokenGrant.initialize,
                            (address(token), recipient, grantAmount)
                        )
                    )
                )
            )
        );

        if (!token.transferFrom(allocationPool, grantAddress, grantAmount)) {
            revert TransferFailed();
        }

        grantByRecipient[recipient] = grantAddress;
        emit LockedTokenGranted(recipient, grantAddress, grantAmount);
        return grantAddress;
    }

    function _authorizeUpgrade(
        address newImplementation
    ) internal view override onlyOwner {
        (newImplementation);
    }
}
