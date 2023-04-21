const { expect } = require("chai")
const { network, upgrades, ethers } = require("hardhat")
// https://hardhat.org/hardhat-network-helpers/docs/reference
const { time } = require("@nomicfoundation/hardhat-network-helpers")

let accounts
let deployer, borrower, lender
let testWETH, boredApesCollection, cryptopunksCollection, metaExchange
const provider = ethers.provider


describe("Metaexchange functionality work as expected", function () {
	beforeEach(async () => {
		try {
			accounts = await ethers.getSigners()
			deployer = accounts[0]
			borrower = accounts[1]
			lender = accounts[2]

            const initialFloorPrices = [
                ethers.utils.parseUnits("100", 18), // bayc floor
                ethers.utils.parseUnits("50", 18), //punks floor
            ]

            const userAddresses = [
                borrower.address,
                lender.address,
            ]
        
            const nftImagesIPFSBAYC = [
                "ipfs://QmcNz9GaEFHaGek9r8pZ5ginUwnR79Cb6ark9RruAZa2Jq", //447
                "ipfs://QmNz5JZHp6YSWRucfuuSQs5gcsGTUGSWyS3zqqa1oYHeXN", //1348
                "ipfs://QmPDk5YbUZsqgvRKdrhARnvE9ynUH9zLHCD21vgEDchfUb" //4255
            ]
        
            const nftImagesIPFSPunks = [
                "ipfs://QmRvQsgVz92A5pPdR4toKMUPgrQ896MjJBixoWt32qoqCM", //100
                "ipfs://QmQi9pxGstEsuS12V8JkpDt6eJA9rtu2B4CtwDnaXL8U9N", //10
                "ipfs://QmbynhRCEKd8N5UPijMRfjCD9GvGSvx3P3cScJEPnbDLy4" //1
            ]

            // console.log("----- WETH DEPLOY -----")
            const TestWETH = await ethers.getContractFactory("TestWETH", deployer)
            const mintAmount = ethers.utils.parseUnits("200", 18);
            testWETH = await TestWETH.deploy(mintAmount)   
            await testWETH.deployed();
            // console.log("TestWETH address ", testWETH.address)
            for(let i = 0; i < userAddresses.length; i++){
                await testWETH.mintTo(userAddresses[i], mintAmount)
            }
    
            // console.log("----- BAYC DEPLOY -----")
            const BoredApesCollection = await ethers.getContractFactory("MyNFTCollection", deployer)
            boredApesCollection = await BoredApesCollection.deploy("Bored Ape Yatch Club","BAYC")   
            await boredApesCollection.deployed();
            // console.log("BoredApesCollection address ", boredApesCollection.address)
            for(let i = 0; i < userAddresses.length; i++){
                for(let j = 0; j < nftImagesIPFSBAYC.length; j++){
                    await boredApesCollection.mintNFT(userAddresses[i], nftImagesIPFSBAYC[j])
                }
            }
    
            // console.log("----- CRYPTOPUNKS DEPLOY -----")
            const CryptopunksCollection = await ethers.getContractFactory("MyNFTCollection", deployer)
            cryptopunksCollection = await CryptopunksCollection.deploy(
                "CRYPTOPUNKS",
                "C"
            )   
            await cryptopunksCollection.deployed();
            // console.log("CryptopunksCollection address ", cryptopunksCollection.address)
            for(let i = 0; i < userAddresses.length; i++){
                for(let j = 0; j < nftImagesIPFSPunks.length; j++){
                    await cryptopunksCollection.mintNFT(userAddresses[i], nftImagesIPFSPunks[j])
                }
            }

            const MetaExchange = await ethers.getContractFactory("MetaExchange", deployer)
            metaExchange = await MetaExchange.deploy(
                testWETH.address,
                [boredApesCollection.address, cryptopunksCollection.address],
                [],
                initialFloorPrices,
                "0xdeadbeefdeadbeefdeadbeefdeadbeefdeadbeef"
            )
            await metaExchange.deployed();
            // console.log("MetaExchange address ", metaExchange.address)

		} catch (error) {
			console.log("Error: ", error)
		}
	})
	describe("Loan offer works as expected", function () {
		it("Creates loan offer successfully", async () => {
			// Approve tokenId=1 to MTXCH
            cryptopunksCollection = cryptopunksCollection.connect(borrower)
            await cryptopunksCollection.approve(metaExchange.address, 1)           

            const nftAddress = cryptopunksCollection.address
            const tokenId = 1
            const nftValuation = ethers.utils.parseUnits("100", 18)
            const expectedLiquidity = ethers.utils.parseUnits("60", 18) // 200 * 0.6
            const destinationAddress = prependNullBytes(borrower.address)
            const daysDuration = daysToSeconds(30)
            const interestRate = 10
            
            // Send offer
            metaExchange = metaExchange.connect(borrower)
            await metaExchange.makeOffer(
                nftAddress,
                tokenId,
                nftValuation,
                expectedLiquidity,
                destinationAddress,
                daysDuration,
                interestRate
            )
            
            const mtxchOffers = await metaExchange.getOffers()
            expect(mtxchOffers.length).to.equal(1)
            
            expect(mtxchOffers[0].isActive).to.equal(true)
            expect(mtxchOffers[0].borrower).to.equal(borrower.address)
            expect(mtxchOffers[0].nftAddress).to.equal(nftAddress)
            expect(mtxchOffers[0].tokenId).to.equal(tokenId)
            expect(mtxchOffers[0].tokenValuation).to.equal(nftValuation)
            expect(mtxchOffers[0].tokenFloorPrice).to.equal(ethers.utils.parseUnits("50", 18))
            expect(mtxchOffers[0].loanValue).to.equal(expectedLiquidity)
            expect(mtxchOffers[0].destinationAddress).to.equal(destinationAddress.toLowerCase())
            expect(mtxchOffers[0].duration).to.equal(daysDuration)
            expect(mtxchOffers[0].interestRate).to.equal(interestRate)
		})
		it("Repays loan successfully", async () => {
            cryptopunksCollection = cryptopunksCollection.connect(borrower)
            await cryptopunksCollection.approve(metaExchange.address, 1)           

            const nftAddress = cryptopunksCollection.address
            const tokenId = 1
            const nftValuation = ethers.utils.parseUnits("100", 18)
            const expectedLiquidity = ethers.utils.parseUnits("60", 18) // 100 * 0.6
            const destinationAddress = prependNullBytes(borrower.address)
            const daysDuration = daysToSeconds(30)
            const interestRate = ethers.BigNumber.from(10);
            
            // Send offer
            metaExchange = metaExchange.connect(borrower)
            await metaExchange.makeOffer(
                nftAddress,
                tokenId,
                nftValuation,
                expectedLiquidity,
                destinationAddress,
                daysDuration,
                interestRate
            )
            
            testWETH = testWETH.connect(lender)
            await testWETH.approve(metaExchange.address, expectedLiquidity)
            metaExchange = metaExchange.connect(lender)
            await metaExchange.acceptOffer(0)
            
            const loanRepaymentValue = computeRepaymentValue(
                expectedLiquidity,
                interestRate,
                daysDuration
            )
            
            testWETH = testWETH.connect(borrower)
            await testWETH.approve(metaExchange.address, loanRepaymentValue)
            metaExchange = metaExchange.connect(borrower)
            await metaExchange.repayLoan(0)
            
            expect(await cryptopunksCollection.ownerOf(1)).to.equal(borrower.address)
            
            const mtxchLoans = await metaExchange.getLoans()
            expect(mtxchLoans[0].isActive).to.equal(false)

            
		})
	})
    describe("Lender functionality works as expected ", function () {
		it("Accepts loan offer successfully", async () => {
			// Approve tokenId=1 to MTXCH
            cryptopunksCollection = cryptopunksCollection.connect(borrower)
            await cryptopunksCollection.approve(metaExchange.address, 1)           

            const nftAddress = cryptopunksCollection.address
            const tokenId = 1
            const nftValuation = ethers.utils.parseUnits("100", 18)
            const expectedLiquidity = ethers.utils.parseUnits("60", 18) // 200 * 0.6
            const destinationAddress = prependNullBytes(borrower.address)
            const daysDuration = daysToSeconds(30)
            const interestRate = 10
            
            // Send offer
            metaExchange = metaExchange.connect(borrower)
            await metaExchange.makeOffer(
                nftAddress,
                tokenId,
                nftValuation,
                expectedLiquidity,
                destinationAddress,
                daysDuration,
                interestRate
            )
            
            testWETH = testWETH.connect(lender)
            await testWETH.approve(metaExchange.address, expectedLiquidity)
            
            
            const mxtchInitialBalance = await testWETH.balanceOf(metaExchange.address)
            metaExchange = metaExchange.connect(lender)
            await metaExchange.acceptOffer(0)

            const mxtchFinalBalance = await testWETH.balanceOf(metaExchange.address)
            expect(mxtchInitialBalance.add(expectedLiquidity)).to.equal(mxtchFinalBalance)

            const mtxchLoans = await metaExchange.getLoans()
            expect(mtxchLoans.length).to.equal(1)
            
            expect(mtxchLoans[0].offer.borrower).to.equal(borrower.address)
            expect(mtxchLoans[0].offer.nftAddress).to.equal(nftAddress)
            expect(mtxchLoans[0].offer.tokenId).to.equal(tokenId)
            expect(mtxchLoans[0].offer.tokenValuation).to.equal(nftValuation)
            expect(mtxchLoans[0].offer.tokenFloorPrice).to.equal(ethers.utils.parseUnits("50", 18))
            expect(mtxchLoans[0].offer.loanValue).to.equal(expectedLiquidity)
            expect(mtxchLoans[0].offer.destinationAddress).to.equal(destinationAddress.toLowerCase())
            expect(mtxchLoans[0].offer.duration).to.equal(daysDuration)
            expect(mtxchLoans[0].offer.interestRate).to.equal(interestRate)
            expect(mtxchLoans[0].isActive).to.equal(true)
            expect(mtxchLoans[0].lender).to.equal(lender.address)
            expect(mtxchLoans[0].initialDate).to.equal(await time.latest())
		})
        it("Loan liquidation works as expected due to floor price decrease", async () => {
            cryptopunksCollection = cryptopunksCollection.connect(borrower)
            await cryptopunksCollection.approve(metaExchange.address, 1)           

            const nftAddress = cryptopunksCollection.address
            const tokenId = 1
            const nftValuation = ethers.utils.parseUnits("100", 18)
            const expectedLiquidity = ethers.utils.parseUnits("60", 18) // 200 * 0.6
            const destinationAddress = prependNullBytes(borrower.address)
            const daysDuration = daysToSeconds(30)
            const interestRate = 10
            
            // Send offer
            metaExchange = metaExchange.connect(borrower)
            await metaExchange.makeOffer(
                nftAddress,
                tokenId,
                nftValuation,
                expectedLiquidity,
                destinationAddress,
                daysDuration,
                interestRate
            )
            
            testWETH = testWETH.connect(lender)
            await testWETH.approve(metaExchange.address, expectedLiquidity)
            
            metaExchange = metaExchange.connect(lender)
            await metaExchange.acceptOffer(0)
            
            const newFloorPrices = [
                ethers.utils.parseUnits("100", 18), // bayc floor
                ethers.utils.parseUnits("49", 18), //punks floor, now worth 1 ETH less
            ]
            await metaExchange.setFloorPrice(
                [boredApesCollection.address, cryptopunksCollection.address],
                newFloorPrices
            )

            await metaExchange.liquidateDefaultedPosition(0)
            expect(await cryptopunksCollection.ownerOf(1)).to.equal(lender.address)
            
            const mtxchLoans = await metaExchange.getLoans()
            expect(mtxchLoans[0].isActive).to.equal(false)
		})
        it("Loan liquidation works as expected due to debt not paid in time", async () => {
			cryptopunksCollection = cryptopunksCollection.connect(borrower)
            await cryptopunksCollection.approve(metaExchange.address, 1)           

            const nftAddress = cryptopunksCollection.address
            const tokenId = 1
            const nftValuation = ethers.utils.parseUnits("100", 18)
            const expectedLiquidity = ethers.utils.parseUnits("60", 18) // 200 * 0.6
            const destinationAddress = prependNullBytes(borrower.address)
            const daysDuration = daysToSeconds(30)
            const interestRate = 10
            
            // Send offer
            metaExchange = metaExchange.connect(borrower)
            await metaExchange.makeOffer(
                nftAddress,
                tokenId,
                nftValuation,
                expectedLiquidity,
                destinationAddress,
                daysDuration,
                interestRate
            )
            
            testWETH = testWETH.connect(lender)
            await testWETH.approve(metaExchange.address, expectedLiquidity)
            
            metaExchange = metaExchange.connect(lender)
            await metaExchange.acceptOffer(0)
            
            await time.increase(daysDuration.add(10)) //duration + 10 seconds

            await metaExchange.liquidateDefaultedPosition(0)
            expect(await cryptopunksCollection.ownerOf(1)).to.equal(lender.address)
            
            const mtxchLoans = await metaExchange.getLoans()
            expect(mtxchLoans[0].isActive).to.equal(false)
		})
	})
})


function prependNullBytes(address) {
    // Remove the '0x' prefix if it exists
    const cleanedAddress = address.startsWith('0x') ? address.slice(2) : address;
    
    // Check if the cleaned address is a valid EVM address
    if (cleanedAddress.length !== 40) {
      throw new Error('Invalid EVM address');
    }
  
    // Prepend 12 null bytes (24 zeros) to the cleaned address
    const paddedAddress = '0x' + '0'.repeat(24) + cleanedAddress;
  
    return paddedAddress;
}

function daysToSeconds(days) {
    const SECONDS_IN_A_DAY = ethers.BigNumber.from(86400); // 24 hours * 60 minutes * 60 seconds
    const daysBigNumber = ethers.BigNumber.from(days);
  
    return daysBigNumber.mul(SECONDS_IN_A_DAY);
}

function computeRepaymentValue(value, interestRate, durationInSeconds){
    SECONDS_PER_YEAR = ethers.BigNumber.from(365 * 86400 );
    const interest = value.mul(interestRate).mul(durationInSeconds).div(SECONDS_PER_YEAR).div(100)
    const repaymentValue = value.add(interest)
    return repaymentValue
}