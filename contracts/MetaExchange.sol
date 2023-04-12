// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

// TODO reorder this struct to make it more gas-efficient
struct Offer {
    bool isActive;
    address user;
    address nftAddress;
	uint256 tokenId;
    uint256 tokenValuation;
    uint256 tokenFloorPrice;
    uint256 loanValue;
    string injectiveAddress;
}

// TODO reorder this struct to make it more gas-efficient
struct Loan {
    bool isActive;
    address borrower;
    address nftAddress;
	uint256 tokenId;
    uint256 tokenValuation;
    uint256 tokenFloorPrice;
    uint256 loanValue;
    string injectiveAddress;
    address lender;
}

interface IWETH is IERC20 {
    function deposit() external payable;
    function withdraw(uint256 amount) external;
}

interface PeggyBridge {
    function bridge() external;
}

contract MetaExchange {
    // TODO: make this uint8
    uint256 constant public maxBorrowPercentage = 60;
    IWETH public immutable weth;
    PeggyBridge public peggyBridge;
    mapping(address => bool) public immutable allowedAddresses;
    Offer[] public offers;
    Loan[] public loans;

    constructor(
        address _wethAddress, 
        address[] calldata _allowedAddresses,
        address peggyAddress) {
        weth = IWETH(_wethAddress);
        peggyBridge = PeggyBridge(peggyAddress);
        
        for (uint256 i = 0; i < _allowedAddresses.length; i++) {
            allowedAddresses[_allowedAddresses[i]] = true;
        }
    }

    function makeOffer(
        address _nftAddress, 
        uint256 _tokenId, 
        uint256 _tokenValuation,
        uint256 _loanValue,
        calldata string _injectiveAddress
    ) public {
        require(allowedAddresses[_nftAddress], "NFT collection not supported");
        require(_loanValue < _tokenValuation * 60 / 100, "Loan should be less than 60% of token valuation");
        
        IERC721 nft = IERC721(_nftAddress);
        nft.safeTransferFrom(msg.sender, address(this), _tokenId);

        // TODO: get token floorPrice fro chainlink
        uint256 tokenFloorPrice = getFloorPrice(_nftAddress);

        offers.push(Offer(
            true,
            msg.sender,
            _nftAddress,
            _tokenId,
            _tokenValuation,
            tokenFloorPrice,
            _loanValue,
            _injectiveAddress
        ));
    }

    // TODO: make this more gas-efficient by copying offer to memory then dumping to storage
    function cancelOffer(uint256 offerIndex) public {
        Offer storage offer = offers[offerIndex];
        
        require(offer.isActive, "Offer is not active");
        require(msg.sender == offer.user, "Offer not owned by msg.sender");
        
        offer.isActive = false;
        IERC721 nft = IERC721(offer.nftAddress);
        nft.transferFrom(address(this), msg.sender, offer.tokenId);
    }

    // TODO: make this more gas-efficient by copying offer to memory then dumping to storage
    function acceptOffer(uint256 offerIndex) public {
        Offer storage offer = offers[offerIndex];
        offer.isActive = false;

        loans.push(Loan(
            true,
            offer.borrower,
            offer.nftAddress,
            offer.tokenId,
            offer.tokenValuation,
            offer.tokenFloorPrice;
            offer.loanValue;
            offer.injectiveAddress;
            msg.sender
        ));

        weth.transferFrom(msg.sender, address(this), offer.loanValue)
        weth.approve(peggyBridge.address, loanValue);

        peggyBridge.bridge();
    }

    // TODO: make this more gas-efficient by copying offer to memory then dumping to storage
    function liquidateDefaultedPosition(uint256 loanIndex) public {
        uint256 currentFloorPrice = getFloorPrice(loans[loanIndex].nftAddress);
        
        Loan storage loan = loans[loanIndex];
        uint256 currentValuation = loan.tokenValuation * currentFloorPrice / loan.floorPrice;
        require(loan.loanValue > currentValuation, "Position still healthy")
        
        loan.isActive = false;
        
        IERC721 nft = IERC721(_nftAddress);
        nft.safeTransferFrom(address(this), loan.lender, loan.tokenId);

    }

    function repayLoan(uint256 loanIndex) public{
        return
    }

    function getFloorPrice(address nftCollection) internal {
        // TODO: get token floorPrice from chainlink
        return
    }
}