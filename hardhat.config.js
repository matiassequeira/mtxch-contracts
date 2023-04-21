require("dotenv").config()
require("hardhat-deploy")
require("@nomiclabs/hardhat-ethers");
require("@nomicfoundation/hardhat-toolbox");
const { ethers } = require("ethers");

// You need to export an object to set up your config
// Go to https://hardhat.org/config/ to learn more
/**
 * @type import('hardhat/config').HardhatUserConfig
 */

const MAINNET_MNEMONICS = process.env.MAINNET_MNEMONICS || ""
const TESTNET_MNEMONICS = process.env.TESTNET_MNEMONICS || ""
const GOERLI_RPC_URL = process.env.GOERLI_RPC_URL || ""
const POLYGON_RPC_URL = process.env.POLYGON_RPC_URL || ""


module.exports = {
  defaultNetwork: "hardhat",
	networks: {
		hardhat: {
			chainId: 80000,
			deploy: ["deploy/"],
		},
		localhost: {
			chainId: 80000, //same chainId as mumbai, will probally need it to match to test offchain signer
			deploy: ["deploy/"],
		},
		goerli: {
			url: GOERLI_RPC_URL,
			deploy: ["deploy/"],
			accounts: {
				mnemonic: TESTNET_MNEMONICS,
			},
			blockConfirmations: 6,
		},
		polygon: {
			url: POLYGON_RPC_URL,
			accounts: {
				mnemonic: MAINNET_MNEMONICS,
			},
			gasPrice: 240000000000,
			blockConfirmations: 6,
		},
	},
	solidity: {
		compilers: [
			{
				version: "0.8.18",
				settings: {
					optimizer: {
						enabled: true,
						runs: 200,
					},
				},
			},
		],
	},
	namedAccounts: {
		deployer: {
			default: 0, // here this will by default take the first account as deployer
			// 1: 0, // similarly on mainnet it will take the first account as deployer. Note though that depending on how hardhat network are configured, the account 0 on one network can be different than on another
		},
	},
};
