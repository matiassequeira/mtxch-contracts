const { ethers } = require("hardhat")
// const { ethers } = require('ethers');

async function main() {
	
    accounts = await ethers.getSigners()
    deployer = accounts[0]

    const baycAddress = "0x9fE46736679d2D9a65F0992F2272dE9f3c7fa6e0"
    if (baycAddress == "") {
        throw "Provide baycAddress"
    }

	try {
        const BoredApesCollection = await ethers.getContractFactory("MyNFTCollection", deployer)
		const baycCollection = await BoredApesCollection.attach(baycAddress)

        const tokenUri = await baycCollection.tokenURI(2);
        console.log("tokenUri", tokenUri)


	} catch (error) {
		console.log(error)
	}
}

main().catch((error) => {
	console.error(error)
	process.exitCode = 1
})