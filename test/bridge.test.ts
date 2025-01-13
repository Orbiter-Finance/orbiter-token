import { ethers, upgrades } from "hardhat";
import { expect } from "chai";
import {
  getArbitrumNetwork,
  ParentToChildMessageStatus,
  Erc20Bridger,
} from "@arbitrum/sdk";

import { arbLog } from "arb-shared-dependencies";

import { toBigNumber, toV5Provider, toV5Wallet } from "./warpEthers";

/**
 * Set up: instantiate wallets connected to providers
 */
const walletPrivateKey = process.env.PRIVATE_KEY as string;

const parentChainProvider = toV5Provider(
  process.env.ETHEREUM_SEPOLIA_RPC_URL as string
);
const childChainProvider = toV5Provider(
  process.env.ARBITRUM_SEPOLIA_RPC_URL as string
);

const parentChainWallet = toV5Wallet(walletPrivateKey, parentChainProvider);
const childChainWallet = toV5Wallet(walletPrivateKey, childChainProvider);

const tokenTotalSupply = BigInt(100000);

/**
 * Set the amount of token to be transferred to the child chain
 */
const tokenAmount = BigInt(50);

const main = async () => {
  await arbLog("Deposit token using Arbitrum SDK");

  /**
   * Add the custom network configuration to the SDK if present
   */
  //   addCustomNetworkFromFile();

  /**
   * For the purpose of our tests, here we deploy an standard ERC-20 token (DappToken) to the parent chain
   * It sends its deployer (us) the initial supply of 1000
   */
  console.log("Deploying the test DappToken to the parent chain:");
  const dappToken = await ethers.getContractAt(
    "GovToken",
    "0x76B4e27420af7417eC7b2cB0C803bc6174DEEE35",
    parentChainWallet
  );

  // Todo: Currently, contracts cannot be deployed. Contracts can only be deployed through foundry.
  // The problem is unknown.
  //   const DappToken = (await ethers.getContractFactory("GovToken")).connect(
  //     parentChainWallet
  //   );
  //   const dappToken = await upgrades.deployProxy(
  //     DappToken,
  //     ["Orbiter", "Orb", "0xb2c87A026Bfa7136B36ca7C0027f64328021D721"],
  //     {
  //       initializer: "initialize",
  //       kind: "uups",
  //       //   txOverrides: { maxFeePerGas: 100000000000 },
  //     }
  //   );
  //   await dappToken.waitForDeployment();
  //   console.log("Proxy contract:", dappToken.target);
  //   const implAddress = await upgrades.erc1967.getImplementationAddress(
  //     await dappToken.getAddress()
  //   );
  //   console.log("Implementation contract:", implAddress);
  console.log(
    `DappToken is deployed to the parent chain at ${await dappToken.getAddress()}`
  );

  //   console.log("Mint Token");
  const tokenDecimals = await dappToken.decimals();
  //   await dappToken.mint(
  //     "0xb2c87A026Bfa7136B36ca7C0027f64328021D721",
  //     tokenTotalSupply * BigInt(10) ** tokenDecimals
  //   );

  //   console.log("Mint Token Successfully");

  /**
   * Use childChainNetwork to create an Arbitrum SDK Erc20Bridger instance
   * We'll use Erc20Bridger for its convenience methods around transferring token to the child chain
   */
  const childChainId = (await childChainProvider.getNetwork()).chainId;
  const childChainNetwork = getArbitrumNetwork(Number(childChainId));
  const erc20Bridger = new Erc20Bridger(childChainNetwork);

  /**
   * We get the address of the parent-chain gateway for our DappToken,
   * which will later help us get the initial token balance of the bridge (before deposit)
   */
  const tokenAddress = await dappToken.getAddress();
  const expectedGatewayAddress = await erc20Bridger.getParentGatewayAddress(
    tokenAddress,
    parentChainProvider
  );
  const initialBridgeTokenBalance = await dappToken.balanceOf(
    expectedGatewayAddress
  );

  /**
   * Because the token might have decimals, we update the amount to deposit taking into account those decimals
   */
  const tokenDepositAmount = tokenAmount * BigInt(10) ** tokenDecimals;

  /**
   * The StandardGateway contract will ultimately be making the token transfer call; thus, that's the contract we need to approve.
   * erc20Bridger.approveToken handles this approval
   * Arguments required are:
   * (1) parentSigner: address of the account on the parent chain transferring tokens to the child chain
   * (2) erc20ParentAddress: address on the parent chain of the ERC-20 token to be depositted to the child chain
   */
  console.log("Approving:");
  const approveTransaction = await erc20Bridger.approveToken({
    parentSigner: parentChainWallet,
    erc20ParentAddress: tokenAddress,
  });

  const approveTransactionReceipt = await approveTransaction.wait();
  console.log(
    `You successfully allowed the Arbitrum Bridge to spend DappToken ${approveTransactionReceipt.transactionHash}`
  );

  /**
   * The next function initiates the deposit of DappToken to the child chain using erc20Bridger.
   * This will escrow funds in the gateway contract on the parent chain, and send a message to mint tokens on the child chain.
   *
   * The erc20Bridge.deposit method handles computing the necessary fees for automatic-execution of retryable tickets — maxSubmission cost and (gas price * gas)
   * and will automatically forward the fees to the child chain as callvalue.
   *
   * Also note that since this is the first DappToken deposit onto the child chain, a standard Arb ERC-20 contract will automatically be deployed.
   * Arguments required are:
   * (1) amount: The amount of tokens to be transferred to the child chain
   * (2) erc20ParentAddress: address on the parent chain of the ERC-20 token to be depositted to the child chain
   * (3) parentSigner: address of the account on the parent chain transferring tokens to the child chain
   * (4) childProvider: A provider for the child chain
   */
  console.log("Transferring DappToken to the child chain:");
  const depositTransaction = await erc20Bridger.deposit({
    amount: toBigNumber(tokenDepositAmount),
    erc20ParentAddress: tokenAddress,
    parentSigner: parentChainWallet,
    childProvider: childChainProvider,
  });

  /**
   * Now we wait for both the parent-chain and child-chain sides of transactions to be confirmed
   */
  console.log(
    `Deposit initiated: waiting for execution of the retryable ticket on the child chain (takes 10-15 minutes; current time: ${new Date().toTimeString()}) `
  );
  const depositTransactionReceipt = await depositTransaction.wait();
  const childTransactionReceipt =
    await depositTransactionReceipt.waitForChildTransactionReceipt(
      childChainProvider
    );

  /**
   * The `complete` boolean tells us if the parent-to-child message was successful
   */
  if (childTransactionReceipt.complete) {
    console.log(
      `Message was successfully executed on the child chain: status: ${
        ParentToChildMessageStatus[childTransactionReceipt.status]
      }`
    );
  } else {
    throw new Error(
      `Message failed to be executed on the child chain: status ${
        ParentToChildMessageStatus[childTransactionReceipt.status]
      }`
    );
  }

  /**
   * Get the Bridge token balance
   */
  const finalBridgeTokenBalance = await dappToken.balanceOf(
    expectedGatewayAddress
  );

  /**
   * Check if Bridge balance has been updated correctly
   */
  expect(
    initialBridgeTokenBalance + tokenDepositAmount == finalBridgeTokenBalance,
    "Bridge balance was not updated after the token deposit transaction"
  ).to.be.true;

  /**
   * Check if our balance of DappToken on the child chain has been updated correctly
   * To do so, we use erc20Bridge to get the token address and contract on the child chain
   */
  const childChainTokenAddress = await erc20Bridger.getChildErc20Address(
    tokenAddress,
    parentChainProvider
  );
  const childChainToken = erc20Bridger.getChildTokenContract(
    childChainProvider,
    childChainTokenAddress
  );

  // Todo:Consider whether direct transfer is required.
  //   {
  //     childChainToken.functions.transfer(airdopAddress, tokenDepositAmount);
  //   }

  const testWalletBalanceOnChildChain = (
    await childChainToken.functions.balanceOf(childChainWallet.address)
  )[0];
  expect(
    testWalletBalanceOnChildChain.eq(tokenDepositAmount),
    "wallet balance on the child chain was not updated after deposit"
  ).to.be.true;
};

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
