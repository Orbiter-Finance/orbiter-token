import { BigNumber } from "@ethersproject/bignumber";
import { JsonRpcProvider } from "@ethersproject/providers";
import { Wallet } from "@ethersproject/wallet";

export function toBigNumber(value: bigint | number | string): BigNumber {
  return BigNumber.from(value);
}

export function toV5Provider(rpc: string): JsonRpcProvider {
  return new JsonRpcProvider(rpc);
}

export function toV5Wallet(
  walletPrivateKey: string,
  provider: JsonRpcProvider
): Wallet {
  return new Wallet(walletPrivateKey, provider);
}
