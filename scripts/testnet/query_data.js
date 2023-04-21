const { ethers } = require("hardhat")
// const { ethers } = require('ethers');

async function main() {
	
    accounts = await ethers.getSigners()
    deployer = accounts[0]

    const baycAddress = "0x88F853F0b4c074c0B3D9486cC56BD5BfCb987D82"
    if (baycAddress == "") {
        throw "Provide baycAddress"
    }

	try {
        const BoredApesCollection = await ethers.getContractFactory("MyNFTCollection", deployer)
		const baycCollection = await BoredApesCollection.attach(baycAddress)

        const tokenUri = await baycCollection.tokenURI(1);
        console.log("tokenUri", tokenUri)


	} catch (error) {
		console.log(error)
	}
}

main().catch((error) => {
	console.error(error)
	process.exitCode = 1
})