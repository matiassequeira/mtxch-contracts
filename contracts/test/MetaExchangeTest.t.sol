// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "../MetaExchange.sol";
import "../auxiliary/TestERC20.sol";
import "../auxiliary/TestERC721.sol";

contract MetaExchangeTest is Test {
    address constant DEPLOYER = 0x0000000000000000000000000000000000000001;
    address constant BORROWER = 0x0000000000000000000000000000000000000002;
    address constant LENDER = 0x0000000000000000000000000000000000000003;

    address[] userAddresses = [BORROWER, LENDER, DEPLOYER];
    string[] nftImagesIPFSBAYC = [
        "ipfs://QmcNz9GaEFHaGek9r8pZ5ginUwnR79Cb6ark9RruAZa2Jq", //447
        "ipfs://QmNz5JZHp6YSWRucfuuSQs5gcsGTUGSWyS3zqqa1oYHeXN", //1348
        "ipfs://QmPDk5YbUZsqgvRKdrhARnvE9ynUH9zLHCD21vgEDchfUb" //4255
    ];
    string[] nftImagesIPFSPunks = [
        "ipfs://QmRvQsgVz92A5pPdR4toKMUPgrQ896MjJBixoWt32qoqCM", //100
        "ipfs://QmQi9pxGstEsuS12V8JkpDt6eJA9rtu2B4CtwDnaXL8U9N", //10
        "ipfs://QmbynhRCEKd8N5UPijMRfjCD9GvGSvx3P3cScJEPnbDLy4" //1
    ];
    uint256[] initialFloorPrices = [
        100 ether,
        50 ether
    ];

    address public constant peggyAddress = 0xDeaDbeefdEAdbeefdEadbEEFdeadbeEFdEaDbeeF;
    TestWETH public weth;
    MyNFTCollection public cryptopunksCollection;
    MyNFTCollection public boredApesCollection;
    MetaExchange public metaExchange;

    function setUp() public {
        vm.startPrank(DEPLOYER);
        
        uint256 mintAmount = 200 ether;
        weth = new TestWETH(mintAmount);
        for(uint8 i = 0; i < userAddresses.length; i++){
                weth.mintTo(userAddresses[i], mintAmount);
        }

        cryptopunksCollection = new MyNFTCollection("CRYPTOPUNKS", "C");
        for(uint8 i = 0; i < userAddresses.length; i++){
            for(uint8 j = 0; j < nftImagesIPFSBAYC.length; j++){
                
                cryptopunksCollection.mintNFT(userAddresses[i], nftImagesIPFSBAYC[j]);
            }
        }

        boredApesCollection = new MyNFTCollection("Bored Ape Yatch Club","BAYC");
        for(uint8 i = 0; i < userAddresses.length; i++){
            for(uint8 j = 0; j < nftImagesIPFSPunks.length; j++){
                boredApesCollection.mintNFT(userAddresses[i], nftImagesIPFSPunks[j]);
            }
        }

        address[] memory collectionAddresses = new address[](2);
        collectionAddresses[0]=address(cryptopunksCollection);
        collectionAddresses[1]=address(boredApesCollection);

        metaExchange = new MetaExchange(
            address(weth),
            collectionAddresses,
            new address[](2),
            initialFloorPrices,
            peggyAddress

        );
        vm.stopPrank();
    }

    function testCreateLoan() public {
        // Approve tokenId=1 to MTXCH
        vm.startPrank(BORROWER);
        cryptopunksCollection.approve(address(metaExchange), 1);

        address nftAddress = address(cryptopunksCollection);
        uint256 tokenId = 1;
        uint256 nftValuation = 100 ether;
        uint256 expectedLiquidity = 60 ether;
        bytes32 destinationAddress = 0x0000000000000000000000000000000000000000000000000000000000000002;
        uint32 daysDuration = 30 * 24 * 60 * 60;
        uint8 interestRate = 10;
        
        // // Send offer
        metaExchange.makeOffer(
            nftAddress,
            tokenId,
            nftValuation,
            expectedLiquidity,
            destinationAddress,
            daysDuration,
            interestRate
        );
        
        Offer[] memory offers = metaExchange.getOffers();
        assertEq(offers.length, 1); 
        
        assertEq(offers[0].isActive, true); 
        assertEq(offers[0].borrower, BORROWER); 
        assertEq(offers[0].nftAddress, nftAddress); 
        assertEq(offers[0].tokenId, tokenId); 
        assertEq(offers[0].tokenValuation, nftValuation); 
        assertEq(offers[0].tokenFloorPrice, 100 ether); 
        assertEq(offers[0].loanValue, expectedLiquidity); 
        assertEq(offers[0].destinationAddress, destinationAddress); 
        assertEq(offers[0].duration, daysDuration); 
        assertEq(offers[0].interestRate, interestRate); 
    }

    function testLoanCreation() public {
        vm.startPrank(BORROWER);
        cryptopunksCollection.approve(address(metaExchange), 1);

        address nftAddress = address(cryptopunksCollection);
        uint256 tokenId = 1;
        uint256 nftValuation = 100 ether;
        uint256 expectedLiquidity = 60 ether;
        bytes32 destinationAddress = 0x0000000000000000000000000000000000000000000000000000000000000002;
        uint32 daysDuration = 30 * 24 * 60 * 60;
        uint8 interestRate = 10;
        
        // // Send offer
        metaExchange.makeOffer(
            nftAddress,
            tokenId,
            nftValuation,
            expectedLiquidity,
            destinationAddress,
            daysDuration,
            interestRate
        );
        vm.stopPrank();
        
        vm.startPrank(LENDER);
        weth.approve(address(metaExchange), expectedLiquidity);

        uint256 mxtchInitialBalance = weth.balanceOf(address(metaExchange));
        metaExchange.acceptOffer(0);
        uint256 mxtchFinalBalance = weth.balanceOf(address(metaExchange));

        assertEq(mxtchInitialBalance+expectedLiquidity, mxtchFinalBalance);

        Loan[] memory mtxchLoans = metaExchange.getLoans();
        assertEq(mtxchLoans.length, 1);
          
        assertEq(mtxchLoans[0].offer.borrower,BORROWER);
        assertEq(mtxchLoans[0].offer.nftAddress,nftAddress);
        assertEq(mtxchLoans[0].offer.tokenId,tokenId);
        assertEq(mtxchLoans[0].offer.tokenValuation,nftValuation);
        assertEq(mtxchLoans[0].offer.tokenFloorPrice,100 ether);
        assertEq(mtxchLoans[0].offer.loanValue,expectedLiquidity);
        assertEq(mtxchLoans[0].offer.destinationAddress,destinationAddress);
        assertEq(mtxchLoans[0].offer.duration,daysDuration);
        assertEq(mtxchLoans[0].offer.interestRate,interestRate);
        assertEq(mtxchLoans[0].isActive,true);
        assertEq(mtxchLoans[0].lender,LENDER);
        assertEq(mtxchLoans[0].initialDate,block.timestamp);

    }
    function computeRepaymentValue(
        uint256 value, 
        uint8 interestRate, 
        uint32 durationInSeconds 
        ) internal pure returns (uint256 repaymentValue) {
        uint256 SECONDS_PER_YEAR = 365 * 86400 ;
        uint256 interest = value * interestRate * durationInSeconds / (SECONDS_PER_YEAR * 100);
        repaymentValue = value + interest;
    }

    function testLoanRepayment() public {
        vm.startPrank(BORROWER);
        cryptopunksCollection.approve(address(metaExchange), 1);
        address nftAddress = address(cryptopunksCollection);
        uint256 tokenId = 1;
        uint256 nftValuation = 100 ether;
        uint256 expectedLiquidity = 60 ether;
        bytes32 destinationAddress = 0x0000000000000000000000000000000000000000000000000000000000000002;
        uint32 daysDuration = 30 * 24 * 60 * 60;
        uint8 interestRate = 10;
        // // Send offer
        metaExchange.makeOffer(
            nftAddress,
            tokenId,
            nftValuation,
            expectedLiquidity,
            destinationAddress,
            daysDuration,
            interestRate
        );
        vm.stopPrank();
        
        vm.startPrank(LENDER);
        weth.approve(address(metaExchange), expectedLiquidity);
        metaExchange.acceptOffer(0);
        vm.stopPrank();

        uint256 loanRepaymentValue = computeRepaymentValue(
            expectedLiquidity,
            interestRate,
            daysDuration
        );
        
        vm.startPrank(BORROWER);
        weth.approve(address(metaExchange),loanRepaymentValue);
        metaExchange.repayLoan(0);
        
        assertEq(cryptopunksCollection.ownerOf(1), BORROWER);
        
        Loan[] memory mtxchLoans = metaExchange.getLoans();
        assertEq(mtxchLoans[0].isActive, false);
    }

    function testLoanLiquidationDueToFloorDecrease() public {
        vm.startPrank(BORROWER);
        cryptopunksCollection.approve(address(metaExchange), 1);
        address nftAddress = address(cryptopunksCollection);
        uint256 tokenId = 1;
        uint256 nftValuation = 100 ether;
        uint256 expectedLiquidity = 60 ether;
        bytes32 destinationAddress = 0x0000000000000000000000000000000000000000000000000000000000000002;
        uint32 daysDuration = 30 * 24 * 60 * 60;
        uint8 interestRate = 10;
        // // Send offer
        metaExchange.makeOffer(
            nftAddress,
            tokenId,
            nftValuation,
            expectedLiquidity,
            destinationAddress,
            daysDuration,
            interestRate
        );
        vm.stopPrank();
        
        vm.startPrank(LENDER);
        weth.approve(address(metaExchange), expectedLiquidity);
        metaExchange.acceptOffer(0);
        
        uint256[] memory newFloorPrices = new uint256[](2);
        newFloorPrices[0] = 99 ether;
        newFloorPrices[1] = 50 ether;

        address[] memory collectionAddresses = new address[](2);
        collectionAddresses[0]=address(cryptopunksCollection);
        collectionAddresses[1]=address(boredApesCollection);

        metaExchange.setFloorPrice(
            collectionAddresses,
            newFloorPrices
        );

        metaExchange.liquidateDefaultedPosition(0);
        assertEq(cryptopunksCollection.ownerOf(1), LENDER);
        
        Loan[] memory mtxchLoans = metaExchange.getLoans();
        assertEq(mtxchLoans[0].isActive, false); 
    }

    function testLoanLiquidationDueToDefault() public {
        vm.startPrank(BORROWER);
        cryptopunksCollection.approve(address(metaExchange), 1);
        address nftAddress = address(cryptopunksCollection);
        uint256 tokenId = 1;
        uint256 nftValuation = 100 ether;
        uint256 expectedLiquidity = 60 ether;
        bytes32 destinationAddress = 0x0000000000000000000000000000000000000000000000000000000000000002;
        uint32 daysDuration = 30 * 24 * 60 * 60;
        uint8 interestRate = 10;
        // // Send offer
        metaExchange.makeOffer(
            nftAddress,
            tokenId,
            nftValuation,
            expectedLiquidity,
            destinationAddress,
            daysDuration,
            interestRate
        );
        vm.stopPrank();
        
        vm.startPrank(LENDER);
        weth.approve(address(metaExchange), expectedLiquidity);
        metaExchange.acceptOffer(0);
        
        uint256 initialTimestamp = block.timestamp;
        vm.warp(initialTimestamp + daysDuration-1);
        vm.expectRevert();
        metaExchange.liquidateDefaultedPosition(0);

        vm.warp(initialTimestamp + daysDuration);
        metaExchange.liquidateDefaultedPosition(0);
        assertEq(cryptopunksCollection.ownerOf(1), LENDER);
        
        Loan[] memory mtxchLoans = metaExchange.getLoans();
        assertEq(mtxchLoans[0].isActive, false); 
    }
}
