// // SPDX-License-Identifier: MIT
// pragma solidity ^0.8.26;

// import {LockedTokenGrant} from "src/LockedTokenGrant.sol";
// import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
// import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
// import {AccessControlUpgradeable} from "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";

// /**
//   The {LockedTokenCommon} contract serves two purposes:
//   1. Maintain the OrbiterToken global timelock (see {GlobalUnlock})
//   2. Allocate locked token grants in {LockedTokenGrant} contracts.

//   Roles:
//   =====
//   1. At initializtion time, the msg.sender of the initialize tx, is defined as DEFAULT_ADMIN_ROLE.
//   2. LOCKED_GRANT_ADMIN_ROLE is required to call `grantLockedTokens`.
//   3. GLOBAL_TIMELOCK_ADMIN_ROLE is reqiured to call the `updateGlobalLock`.
//   Two special roles must be granted

//   Grant Locked Tokens:
//   ===================
//   Locked token grants are granted using the `grantLockedTokens` here.
//   The arguments passed are:
//   - recipient - The address of the tokens "owner". When the tokens get unlocked, they can be released
//                 to the recipient address, and only there.
//   - amount    - The number of tokens to be transfered onto the grant contract upon creation.
//   - startTime - The timestamp of the beginning of the 4 years unlock period over which the tokens
//                 gradually unlock. The startTime can be anytime within the margins specified in the {CommonConstants}.
//   - allocationPool - The {LockedTokenCommon} doesn't hold liquidity from which it can grant the tokens,
//                      but rather uses an external LP for that. The `allocationPool` is the address of the LP
//                      from which the tokens shall be allocated. The {LockedTokenCommon} must have sufficient allowance
//                      on the `allocationPool` so it can transfer funds from it onto the creatred grant contract.

//     Flow: The {LockedTokenCommon} deploys the contract of the new {LockedTokenGrant},
//           transfer the grant amount from the allocationPool onto the new grant,
//           and register the new grant in a mapping.
// */
// contract LockedTokenGov is AccessControlUpgradeable {
//     IERC20 internal immutable tokenContract;
//     LockedTokenGrant public immutable grantImplementation;

//     bytes32 constant LOCKED_GRANT_ADMIN_ROLE =
//         keccak256("LOCKED_GRANT_ADMIN_ROLE");

//     // Maps recipient to its locked grant contract.
//     mapping(address => address) public grantByRecipient;

//     event LockedTokenGranted(
//         address indexed recipient,
//         address indexed grantContract,
//         uint256 grantAmount
//     );

//     constructor(address tokenAddress) {
//         _grantRole(DEFAULT_ADMIN_ROLE, _msgSender());
//         tokenContract = IERC20(tokenAddress);
//         grantImplementation = new LockedTokenGrant();
//     }

//     function setUnlockedTokensAmount(
//         address recipient,
//         uint256 unlockedTokensAmount
//     ) external onlyRole(LOCKED_GRANT_ADMIN_ROLE) {
//         require(grantByRecipient[recipient] != address(0x0));
//         LockedTokenGrant(grantByRecipient[recipient]).setUnlockedTokensAmount(
//             unlockedTokensAmount
//         );
//     }

//     /**
//       Deploys a LockedTokenGrant and transfers `grantAmount` tokens onto it.
//       Returns the address of the LockedTokenGrant contract.

//       Tokens owned by the {LockedTokenGrant} are initially locked, and can only be used for staking.
//       The tokens gradually unlocked and can be transferred to the `recipient`.
//     */
//     function grantLockedTokens(
//         address recipient,
//         uint256 grantAmount,
//         uint256 _startTime,
//         address allocationPool
//     ) external onlyRole(LOCKED_GRANT_ADMIN_ROLE) returns (address) {
//         require(grantByRecipient[recipient] == address(0x0), "ALREADY_GRANTED");
//         // require(
//         //     startTime < block.timestamp + LOCKED_GRANT_MAX_START_FUTURE_OFFSET,
//         //     "START_TIME_TOO_LATE"
//         // );
//         // require(
//         //     startTime > block.timestamp - LOCKED_GRANT_MAX_START_PAST_OFFSET,
//         //     "START_TIME_TOO_EARLY"
//         // );

//         address grantAddress = address(
//             LockedTokenGrant(
//                 payable(
//                     new ERC1967Proxy(
//                         address(grantImplementation),
//                         abi.encodeCall(
//                             LockedTokenGrant.initialize,
//                             (address(tokenContract), recipient, grantAmount)
//                         )
//                     )
//                 )
//             )
//         );

//         require(
//             tokenContract.transferFrom(
//                 allocationPool,
//                 grantAddress,
//                 grantAmount
//             ),
//             "TRANSFER_FROM_FAILED"
//         );
//         grantByRecipient[recipient] = grantAddress;
//         emit LockedTokenGranted(recipient, grantAddress, grantAmount);
//         return grantAddress;
//     }
// }
