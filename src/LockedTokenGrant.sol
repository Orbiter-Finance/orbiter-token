// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {ReachedGrantAmountLimit, InvalidAmount, TransferFailed} from "src/libraries/Error.sol";
import {ERC20Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {UUPSUpgradeable} from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

/**
  This Contract holds a grant of locked tokens and gradually releases the tokens to its recipient.

  This contract should be deployed through the {LockedTokenCommon} contract,
  The global lock expiration time may be adjusted through the {LockedTokenCommon} contract.

  The {LockedTokenGrant} is initialized  with the following parameters:
  `address tokenAddress`: The address of Orbiter token ERC20 contract.
  `address _recipient`: The owner of the grant.
  `uint256 _grantAmount`: The amount of tokens granted in this grant.

  Token Release Operation:
  ======================
  - Tokens are owned by the `recipient`. They cannot be revoked.
  - At any given time the recipient can release any amount of tokens
    as long as the specified amount is available for release.
  - The amount of tokens available for release is the following:
  ```
  availableAmount = unlockedTokens - releasedTokens;
  ```
  - Only the recipient is allowed to trigger release of tokens.
  - The released tokens can be transferred ONLY to the recipient address.
*/
contract LockedTokenGrant is
    Initializable,
    OwnableUpgradeable,
    UUPSUpgradeable
{
    ERC20Upgradeable public token;
    uint256 public grantAmount; // Total grant amount of token
    uint256 public releasedTokens; // Total released amount of token
    uint256 public unlockedTokens;
    address public recipient;

    event TokensSentToRecipient(
        address indexed recipient,
        address indexed grantContract,
        uint256 amountSent,
        uint256 aggregateSent
    );

    modifier onlyRecipient() {
        require(msg.sender == recipient, "Only recipient");
        _;
    }

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(
        address tokenAddress,
        address _recipient,
        uint256 _grantAmount
    ) public initializer {
        __Ownable_init(msg.sender);
        __UUPSUpgradeable_init();

        token = ERC20Upgradeable(tokenAddress);
        recipient = _recipient;
        grantAmount = _grantAmount;
    }

    /*
      Returns the available tokens for release.
    */
    function availableTokens() public view returns (uint256) {
        return unlockedTokens - releasedTokens;
    }

    function setUnlockedTokensAmount(
        uint256 requestedAmount
    ) external onlyOwner {
        if (unlockedTokens + requestedAmount > grantAmount) {
            revert ReachedGrantAmountLimit();
        }
        unlockedTokens += requestedAmount;
    }

    /*
      Transfers `requestedAmount` tokens (if available) to the `recipient`.
    */
    function releaseTokens(uint256 requestedAmount) external onlyRecipient {
        if (requestedAmount > availableTokens()) {
            revert InvalidAmount();
        }

        releasedTokens += requestedAmount;

        if (!token.transfer(recipient, requestedAmount)) {
            revert TransferFailed();
        }
        emit TokensSentToRecipient(
            recipient,
            address(this),
            requestedAmount,
            releasedTokens
        );
    }

    function _authorizeUpgrade(
        address newImplementation
    ) internal view override onlyOwner {
        (newImplementation);
    }
}
