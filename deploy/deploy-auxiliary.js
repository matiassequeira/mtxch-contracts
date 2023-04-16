const { ethers } = require("hardhat")

module.exports = async ({ getNamedAccounts }) => {
	const { deployer } = await getNamedAccounts()

    userAddresses = [
        deployer.address,
        "0xaa"
    ]

    nftImagesIPFSBAYC = [
        "QmcNz9GaEFHaGek9r8pZ5ginUwnR79Cb6ark9RruAZa2Jq", //447
        "QmNz5JZHp6YSWRucfuuSQs5gcsGTUGSWyS3zqqa1oYHeXN", //1348
        "QmPDk5YbUZsqgvRKdrhARnvE9ynUH9zLHCD21vgEDchfUb" //4255
    ]

    nftImagesIPFSPunks = [
        "QmRvQsgVz92A5pPdR4toKMUPgrQ896MjJBixoWt32qoqCM", //100
        "QmQi9pxGstEsuS12V8JkpDt6eJA9rtu2B4CtwDnaXL8U9N", //10
        "QmbynhRCEKd8N5UPijMRfjCD9GvGSvx3P3cScJEPnbDLy4" //1
    ]

	try {
		console.log("----- DEPLOY -----")

		TestWETH = await ethers.getContractFactory("TestWETH", deployer)
        const mintAmount = hre.ethers.utils.parseUnits("100", 18);
		testWETH = await TestWETH.deploy(mintAmount)   
        await testWETH.deployed();
		console.log("TestWETH address ", testWETH.address)
        for(let i = 0; i < userAddresses.length; i++){
            testWETH.mintTo(userAddresses[i], mintAmount)
        }

        BoredApesCollection = await ethers.getContractFactory("MyNFTCollection", deployer)
		boredApesCollection = await BoredApesCollection.deploy(
            "Bored Ape Yatch Club",
            "BAYC"
        )   
        await boredApesCollection.deployed();
		console.log("BoredApesCollection address ", boredApesCollection.address)
        for(let i = 0; i < userAddresses.length; i++){
            boredApesCollection.mintNFT(userAddresses[i], nftImagesIPFSBAYC[i])
        }

        CryptopunksCollection = await ethers.getContractFactory("MyNFTCollection", deployer)
		cryptopunksCollection = await CryptopunksCollection.deploy(
            "CRYPTOPUNKS",
            "C"
        )   
        await cryptopunksCollection.deployed();
		console.log("CryptopunksCollection address ", cryptopunksCollection.address)

        for(let i = 0; i < userAddresses.length; i++){
            cryptopunksCollection.mintNFT(userAddresses[i], nftImagesIPFSPunks[i])
        }


	} catch (error) {
		console.log(error)
	}
}

// Export fixtures to reuse deployment in tests (https://github.com/wighawag/hardhat-deploy#testing-deployed-contracts)
module.exports.tags = ["all", "deploy_contracts"]
