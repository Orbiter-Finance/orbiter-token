const optimism = require("@eth-optimism/sdk")
const { expect } = require("chai");
const { arbLog } = require("arb-shared-dependencies");
const { BigNumber, Contract, providers, Wallet } = require("ethers");

const OrbiterToken = require("../out/OrbiterToken.sol/OrbiterToken.json");

const OrbiterTokenNetwork = require("../config/tokenNetwork.json");

require('dotenv').config();

const abi = [
  {
    inputs: [
      { internalType: "address", name: "_bridge", type: "address" },
      { internalType: "address", name: "_remoteToken", type: "address" },
      { internalType: "string", name: "_name", type: "string" },
      { internalType: "string", name: "_symbol", type: "string" },
      { internalType: "uint8", name: "_decimals", type: "uint8" },
    ],
    stateMutability: "nonpayable",
    type: "constructor",
  },
  {
    anonymous: false,
    inputs: [
      {
        indexed: true,
        internalType: "address",
        name: "owner",
        type: "address",
      },
      {
        indexed: true,
        internalType: "address",
        name: "spender",
        type: "address",
      },
      {
        indexed: false,
        internalType: "uint256",
        name: "value",
        type: "uint256",
      },
    ],
    name: "Approval",
    type: "event",
  },
  {
    anonymous: false,
    inputs: [
      {
        indexed: true,
        internalType: "address",
        name: "account",
        type: "address",
      },
      {
        indexed: false,
        internalType: "uint256",
        name: "amount",
        type: "uint256",
      },
    ],
    name: "Burn",
    type: "event",
  },
  {
    anonymous: false,
    inputs: [
      {
        indexed: true,
        internalType: "address",
        name: "account",
        type: "address",
      },
      {
        indexed: false,
        internalType: "uint256",
        name: "amount",
        type: "uint256",
      },
    ],
    name: "Mint",
    type: "event",
  },
  {
    anonymous: false,
    inputs: [
      { indexed: true, internalType: "address", name: "from", type: "address" },
      { indexed: true, internalType: "address", name: "to", type: "address" },
      {
        indexed: false,
        internalType: "uint256",
        name: "value",
        type: "uint256",
      },
    ],
    name: "Transfer",
    type: "event",
  },
  {
    inputs: [],
    name: "BRIDGE",
    outputs: [{ internalType: "address", name: "", type: "address" }],
    stateMutability: "view",
    type: "function",
  },
  {
    inputs: [],
    name: "REMOTE_TOKEN",
    outputs: [{ internalType: "address", name: "", type: "address" }],
    stateMutability: "view",
    type: "function",
  },
  {
    inputs: [
      { internalType: "address", name: "owner", type: "address" },
      { internalType: "address", name: "spender", type: "address" },
    ],
    name: "allowance",
    outputs: [{ internalType: "uint256", name: "", type: "uint256" }],
    stateMutability: "view",
    type: "function",
  },
  {
    inputs: [
      { internalType: "address", name: "spender", type: "address" },
      { internalType: "uint256", name: "amount", type: "uint256" },
    ],
    name: "approve",
    outputs: [{ internalType: "bool", name: "", type: "bool" }],
    stateMutability: "nonpayable",
    type: "function",
  },
  {
    inputs: [{ internalType: "address", name: "account", type: "address" }],
    name: "balanceOf",
    outputs: [{ internalType: "uint256", name: "", type: "uint256" }],
    stateMutability: "view",
    type: "function",
  },
  {
    inputs: [],
    name: "bridge",
    outputs: [{ internalType: "address", name: "", type: "address" }],
    stateMutability: "view",
    type: "function",
  },
  {
    inputs: [
      { internalType: "address", name: "_from", type: "address" },
      { internalType: "uint256", name: "_amount", type: "uint256" },
    ],
    name: "burn",
    outputs: [],
    stateMutability: "nonpayable",
    type: "function",
  },
  {
    inputs: [],
    name: "decimals",
    outputs: [{ internalType: "uint8", name: "", type: "uint8" }],
    stateMutability: "view",
    type: "function",
  },
  {
    inputs: [
      { internalType: "address", name: "spender", type: "address" },
      { internalType: "uint256", name: "subtractedValue", type: "uint256" },
    ],
    name: "decreaseAllowance",
    outputs: [{ internalType: "bool", name: "", type: "bool" }],
    stateMutability: "nonpayable",
    type: "function",
  },
  {
    inputs: [
      { internalType: "address", name: "spender", type: "address" },
      { internalType: "uint256", name: "addedValue", type: "uint256" },
    ],
    name: "increaseAllowance",
    outputs: [{ internalType: "bool", name: "", type: "bool" }],
    stateMutability: "nonpayable",
    type: "function",
  },
  {
    inputs: [],
    name: "l1Token",
    outputs: [{ internalType: "address", name: "", type: "address" }],
    stateMutability: "view",
    type: "function",
  },
  {
    inputs: [],
    name: "l2Bridge",
    outputs: [{ internalType: "address", name: "", type: "address" }],
    stateMutability: "view",
    type: "function",
  },
  {
    inputs: [
      { internalType: "address", name: "_to", type: "address" },
      { internalType: "uint256", name: "_amount", type: "uint256" },
    ],
    name: "mint",
    outputs: [],
    stateMutability: "nonpayable",
    type: "function",
  },
  {
    inputs: [],
    name: "name",
    outputs: [{ internalType: "string", name: "", type: "string" }],
    stateMutability: "view",
    type: "function",
  },
  {
    inputs: [],
    name: "remoteToken",
    outputs: [{ internalType: "address", name: "", type: "address" }],
    stateMutability: "view",
    type: "function",
  },
  {
    inputs: [{ internalType: "bytes4", name: "_interfaceId", type: "bytes4" }],
    name: "supportsInterface",
    outputs: [{ internalType: "bool", name: "", type: "bool" }],
    stateMutability: "pure",
    type: "function",
  },
  {
    inputs: [],
    name: "symbol",
    outputs: [{ internalType: "string", name: "", type: "string" }],
    stateMutability: "view",
    type: "function",
  },
  {
    inputs: [],
    name: "totalSupply",
    outputs: [{ internalType: "uint256", name: "", type: "uint256" }],
    stateMutability: "view",
    type: "function",
  },
  {
    inputs: [
      { internalType: "address", name: "to", type: "address" },
      { internalType: "uint256", name: "amount", type: "uint256" },
    ],
    name: "transfer",
    outputs: [{ internalType: "bool", name: "", type: "bool" }],
    stateMutability: "nonpayable",
    type: "function",
  },
  {
    inputs: [
      { internalType: "address", name: "from", type: "address" },
      { internalType: "address", name: "to", type: "address" },
      { internalType: "uint256", name: "amount", type: "uint256" },
    ],
    name: "transferFrom",
    outputs: [{ internalType: "bool", name: "", type: "bool" }],
    stateMutability: "nonpayable",
    type: "function",
  },
  {
    inputs: [],
    name: "version",
    outputs: [{ internalType: "string", name: "", type: "string" }],
    stateMutability: "view",
    type: "function",
  },
];

/**
 * Set up: instantiate wallets connected to providers
 */
const walletPrivateKey = process.env.PRIVATE_KEY;

const parentChainProvider = new providers.JsonRpcProvider(
  process.env.ETHEREUM_SEPOLIA_RPC_URL
);
const childChainProvider = new providers.JsonRpcProvider(
  process.env.BASE_SEPOLIA_RPC_URL
);

const parentChainWallet = new Wallet(walletPrivateKey, parentChainProvider);
const childChainWallet = new Wallet(walletPrivateKey, childChainProvider);

/**
 * Set the amount of token to be transferred to the child chain
 */
const tokenAmount = BigNumber.from(OrbiterTokenNetwork.BaseOrbiterToken.amount);

const main = async () => {
  await arbLog("Deposit token using Optimism SDK");

  console.log("Deploying the OrbiterToken to the Ethereum chain:");
  const ethereumOrbiterToken = new Contract(
    OrbiterTokenNetwork.EthereumOrbiterToken.address,
    OrbiterToken.abi,
    parentChainWallet
  );

  const ethereumOrbiterTokenAddress = ethereumOrbiterToken.address;
  const baseOrbiterTokenAddress = OrbiterTokenNetwork.BaseOrbiterToken.address;

  console.log(
    `EthereumOrbiterToken is deployed to the Ethereum chain at ${ethereumOrbiterTokenAddress}`
  );

  let currentBalance = await ethereumOrbiterToken.balanceOf(parentChainWallet.address);

  const tokenDecimals = await ethereumOrbiterToken.decimals();

  console.log(`Now you have ${currentBalance / (10 ** tokenDecimals)} OrbiterToken on the Ethereum chain.`);


  const messenger = new optimism.CrossChainMessenger({
    l1ChainId: (await parentChainProvider.getNetwork()).chainId,
    l2ChainId: (await childChainProvider.getNetwork()).chainId,
    l1SignerOrProvider: parentChainWallet,
    l2SignerOrProvider: childChainWallet,
  });

  /**
   * Because the token might have decimals, we update the amount to deposit taking into account those decimals
   */
  const tokenDepositAmount = tokenAmount.mul(
    BigNumber.from(10).pow(BigNumber.from(tokenDecimals))
  );

  console.log(`${tokenAmount} OrbiterTokens will be transferred to the Base chain shortly.`);

  console.log("Approving:");
  const approveTransaction = await messenger.approveERC20(
    ethereumOrbiterTokenAddress,
    baseOrbiterTokenAddress,
    tokenDepositAmount
  );
  await approveTransaction.wait();

  console.log("Transferring EthereumOrbiterToken to the Base chain:");
  const depositTransaction = await messenger.depositERC20(
    ethereumOrbiterTokenAddress,
    baseOrbiterTokenAddress,
    tokenDepositAmount
  );

  console.log(
    `Deposit initiated: waiting for execution of the retryable ticket on the Base chain (takes 10-15 minutes; current time: ${new Date().toTimeString()}) `
  );
  await depositTransaction.wait();

  await messenger.waitForMessageStatus(
    depositTransaction.hash,
    optimism.MessageStatus.RELAYED
  );

  currentBalance = await ethereumOrbiterToken.balanceOf(parentChainWallet.address);

  console.log(`Update:Now you have ${currentBalance / (10 ** tokenDecimals)} OrbiterToken on the Ethereum chain.`);

  const l2ERC20 = new Contract(
    baseOrbiterTokenAddress,
    abi,
    childChainWallet
  );

  const testWalletBalanceOnChildChain = await l2ERC20.balanceOf(childChainWallet.address);

  console.log(`Now you have ${testWalletBalanceOnChildChain / (10 ** tokenDecimals)} OrbiterTokens on the Base chain`);
};

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
