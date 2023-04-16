const { ethers } = require("hardhat")

module.exports = async ({ getNamedAccounts }) => {
	const { deployer } = await getNamedAccounts()

    const wethAddress
    const allowedNFTAddresses
    const peggyAddress
    
    const provider = ethers.getDefaultProvider();
    const network = await provider.getNetwork();
    const chainId = network.chainId;
    
    if (chainId == 1) {
        console.log("----- MAINNET DEPLOY -----")
        wethAddress = "0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2"
        allowedNFTAddresses = [
            "0xaa..."
        ]
        priceFeedAddresses = [
            "..."
        ]
        mockPrices = []
        peggyAddress = "0xF955C57f9EA9Dc8781965FEaE0b6A2acE2BAD6f3"
    } else {
        console.log("----- TEST DEPLOY -----, chainId", chainId)
        wethAddress
        allowedNFTAddresses
        priceFeedAddresses
        mockPrices
        peggyAddress
    }

	try {
		console.log("----- DEPLOY -----")
		MetaExchange = await ethers.getContractFactory("MetaExchange", deployer)

		metaExchange = await MetaExchange.deploy(
            wethAddress,
            allowedNFTAddresses,
            priceFeedAddresses,
            mockPrices,
            peggyAddress
        )
        
        await metaExchange.deployed();

		console.log("MetaExchange address ", metaExchange.address)
	} catch (error) {
		console.log(error)
	}
}

// Export fixtures to reuse deployment in tests (https://github.com/wighawag/hardhat-deploy#testing-deployed-contracts)
module.exports.tags = ["all", "deploy_contracts"]
