const fs = require("fs");
const path = require("path");
const { expect } = require("chai");

const {
  getArbitrumNetwork,
  ParentToChildMessageStatus,
  Erc20Bridger,
} = require("@arbitrum/sdk");
const { arbLog } = require("arb-shared-dependencies");
const { BigNumber, providers, Wallet, Contract } = require("ethers");
const OrbiterTokenNetworkPath = path.join(__dirname, "../config/tokenNetwork.json");
const OrbiterTokenNetwork = require(OrbiterTokenNetworkPath);
const OrbiterToken = require("../out/OrbiterToken.sol/OrbiterToken.json");


require('dotenv').config();

/**
 * Set up: instantiate wallets connected to providers
 */
const walletPrivateKey = process.env.PRIVATE_KEY

const parentChainProvider = new providers.JsonRpcProvider(
  process.env.ETHEREUM_RPC_URL
);
const childChainProvider = new providers.JsonRpcProvider(
  process.env.ARBITRUM_RPC_URL
);

const parentChainWallet = new Wallet(walletPrivateKey, parentChainProvider);
const childChainWallet = new Wallet(walletPrivateKey, childChainProvider);

/**
 * Set the amount of token to be transferred to the child chain
 */
const tokenAmount = BigNumber.from(OrbiterTokenNetwork.ArbitrumOrbiterToken.amount);

const main = async () => {
  await arbLog("Deposit token using Arbitrum SDK");

  console.log("Deploying the OrbiterToken to the Ethereum chain:");
  const ethereumOrbiterToken = new Contract(
    OrbiterTokenNetwork.EthereumOrbiterToken.address,
    OrbiterToken.abi,
    parentChainWallet
  );

  const ethereumOrbiterTokenAddress = ethereumOrbiterToken.address;

  console.log(
    `EthereumOrbiterToken is deployed to the Ethereum chain at ${ethereumOrbiterTokenAddress}`
  );

  let currentBalance = await ethereumOrbiterToken.balanceOf(parentChainWallet.address);

  const tokenDecimals = await ethereumOrbiterToken.decimals();

  console.log(`Now you have ${currentBalance / (10 ** tokenDecimals)} OrbiterToken on the Ethereum chain.`);

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
  const expectedGatewayAddress = await erc20Bridger.getParentGatewayAddress(
    ethereumOrbiterTokenAddress,
    parentChainProvider
  );


  const initialBridgeTokenBalance = await ethereumOrbiterToken.balanceOf(
    expectedGatewayAddress
  );

  console.log(`The Arbitrum Bridge already holds a balance of ${initialBridgeTokenBalance / (10 ** tokenDecimals)} OrbiterTokens prior to the transfer.`);

  /**
   * Because the token might have decimals, we update the amount to deposit taking into account those decimals
   */
  const tokenDepositAmount = tokenAmount.mul(
    BigNumber.from(10).pow(BigNumber.from(tokenDecimals))
  );

  console.log(`${tokenAmount} OrbiterTokens will be transferred to the Arbitrum chain shortly.`);

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
    erc20ParentAddress: ethereumOrbiterTokenAddress,
  });

  const approveTransactionReceipt = await approveTransaction.wait();
  console.log(
    `You successfully allowed the Arbitrum Bridge to spend OrbiterToken ${approveTransactionReceipt.transactionHash}`
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
  console.log("Transferring EthereumOrbiterToken to the Arbitrum chain:");
  const depositTransaction = await erc20Bridger.deposit({
    amount: tokenDepositAmount,
    erc20ParentAddress: ethereumOrbiterTokenAddress,
    parentSigner: parentChainWallet,
    childProvider: childChainProvider,
  });

  /**
   * Now we wait for both the parent-chain and child-chain sides of transactions to be confirmed
   */
  console.log(
    `Deposit initiated: waiting for execution of the retryable ticket on the Arbitrum chain (takes 10-15 minutes; current time: ${new Date().toTimeString()}) `
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
      `Message was successfully executed on the child chain: status: ${ParentToChildMessageStatus[childTransactionReceipt.status]
      }`
    );
  } else {
    throw new Error(
      `Message failed to be executed on the child chain: status ${ParentToChildMessageStatus[childTransactionReceipt.status]
      }`
    );
  }

  /**
   * Get the Bridge token balance
   */
  const finalBridgeTokenBalance = await ethereumOrbiterToken.balanceOf(
    expectedGatewayAddress
  );

  /**
   * Check if Bridge balance has been updated correctly
   */
  expect(
    BigNumber.from(initialBridgeTokenBalance).add(tokenDepositAmount)
      .eq(BigNumber.from(finalBridgeTokenBalance)),
    "Bridge balance was not updated after the token deposit transaction"
  ).to.be.true;

  /**
   * Check if our balance of DappToken on the child chain has been updated correctly
   * To do so, we use erc20Bridge to get the token address and contract on the child chain
   */
  const childChainTokenAddress = await erc20Bridger.getChildErc20Address(
    ethereumOrbiterTokenAddress,
    parentChainProvider
  );
  const childChainToken = erc20Bridger.getChildTokenContract(
    childChainProvider,
    childChainTokenAddress
  );

  console.log(
    `ArbitrumOrbiterToken is deployed to the Arbitrum chain at ${childChainTokenAddress}`
  );



  {
    let OrbiterTokenNetwork;
    try {
      const rawData = fs.readFileSync(OrbiterTokenNetworkPath, "utf8");
      OrbiterTokenNetwork = JSON.parse(rawData);

    } catch (error) {
      console.error("Error reading JSON file:", error);
      process.exit(1);
    }

    OrbiterTokenNetwork.ArbitrumOrbiterToken.address = childChainTokenAddress;
    fs.writeFileSync(OrbiterTokenNetworkPath, JSON.stringify(OrbiterTokenNetwork, null, 2), "utf8", (err) => {
      if (err) {
        console.error("Error writing to JSON file:", err);
      } else {
        console.log("JSON file updated successfully!");
      }
    });
  }


  // Todo:Consider whether direct transfer is required.
  //   {
  //     childChainToken.functions.transfer(airdopAddress, tokenDepositAmount);
  //   }

  currentBalance = await ethereumOrbiterToken.balanceOf(parentChainWallet.address);

  console.log(`Update:Now you have ${currentBalance / (10 ** tokenDecimals)} OrbiterToken on the Ethereum chain.`);


  const testWalletBalanceOnChildChain = (
    await childChainToken.functions.balanceOf(childChainWallet.address)
  )[0];

  console.log(`Now you have ${testWalletBalanceOnChildChain / (10 ** tokenDecimals)} OrbiterTokens on the Arbitrum chain.`);

  expect(
    BigNumber.from(testWalletBalanceOnChildChain).eq(BigNumber.from(finalBridgeTokenBalance)),
    "wallet balance on the child chain was not updated after deposit"
  ).to.be.true;
};

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
