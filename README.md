
## Usage

### 1. Config 
#### 1.1 config jsons

config/lockedTokenGov.json
```json
{
  "address": "Do not fill",
  "admin": "0xb2c87A026Bfa7136B36ca7C0027f64328021D721"
}

```
config/tokenInit.json
```json
{
  "name": "Orbiter Token",
  "symbol": "OBT",
  "admin": "0xb2c87A026Bfa7136B36ca7C0027f64328021D721",
  "supply": "0x186a0"// supply * 10 ** 18
}

```
config/tokenNetwork.json
```json
{
  "Owner": "0xb2c87a026bfa7136b36ca7c0027f64328021d721",// Token‘s owner address
  "EthereumOrbiterToken": {
    "address": "Do not fill",
    "amount": "0x3e8" //The amount of tokens to be minted on the Ethererum (amount * 10 ** 18)
  },
  "ArbitrumOrbiterToken": {
    "address": "Do not fill",
    "amount": "0x32" // The number of tokens that will be bridged to the Arbitrum (amount * 10 ** 18)
  },
  "BaseOrbiterToken": {
    "address": "Do not fill",
    "amount": "0x32" // The number of tokens that will be bridged to the Base (amount * 10 ** 18)
  }
}
```

#### 1.2 config contract .env
```
PRIVATE_KEY="deployer private key"
ADMIN_PRIVATE_KEY="Token's admin private key(Used to mint tokens)"
ETHEREUM_SEPOLIA_RPC_URL=""
ARBITRUM_SEPOLIA_RPC_URL=""
BASE_SEPOLIA_RPC_URL=""
OPTIMISM_MINTABLE_ERC20FACTORY="0x4200000000000000000000000000000000000012"
```

#### 1.3 config bridge .env
```
PRIVATE_KEY="Token's owner private key"
ETHEREUM_SEPOLIA_RPC_URL=""
ARBITRUM_SEPOLIA_RPC_URL=""
BASE_SEPOLIA_RPC_URL=""
```

### Deploy

```shell
# core
make deployOrbiterToken
make deployOpERC20Token
make mintOrbiterToken

# gov
make deployLockedTokenGov
```

### Bridge

```shell
cd bridge
node arbitrumBridge.js
node baseBridge.js
```
