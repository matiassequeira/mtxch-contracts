// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "./external/Peggy.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";


// TODO reorder this struct to make it more gas-efficient
struct Offer {
    bool isActive;
    address borrower;
    address nftAddress;
	uint256 tokenId;
    uint256 tokenValuation;
    uint256 tokenFloorPrice;
    uint256 loanValue;
    bytes32 injectiveAddress;
    uint32 duration;
    uint8 interestRate;
}

// TODO reorder this struct to make it more gas-efficient
struct Loan {
    Offer offer;
    bool isActive;
    address lender;
    uint256 initialDate;
}

contract MetaExchange {

    using SafeERC20 for IERC20;

    // TODO: make this uint8
    uint256 constant public maxBorrowPercentage = 60;
    IERC20 public immutable weth;
    Peggy public peggyBridge;
    mapping(address => bool) public allowedAddresses;
    Offer[] public offers;
    Loan[] public loans;
    uint8 public interestRate = 5; // 5% percent
    uint32 public constant DAYS_PER_YEAR = 365;
    mapping(address=>address) public nftAddressToPriceFeedAddress;
    mapping(address=>uint256) public nftAddressToMockFloorPrice;
    

    constructor(
        address _wethAddress, 
        address[] memory _allowedAddresses,
        address[] memory _priceFeedAddresses,
        address[] memory _mockPrices,
        address peggyAddress) {
        weth = IERC20(_wethAddress);
        peggyBridge = Peggy(peggyAddress);


        if (block.chainId == 1){
            for (uint256 i = 0; i < _allowedAddresses.length; i++) {
                require(_allowedAddresses.length == _priceFeedAddresses.length, "Size of addresses lists don't match");
                allowedAddresses[_allowedAddresses[i]] = true;
                nftAddressToPriceFeedAddress[_allowedAddresses[i]]=_priceFeedAddresses[i];
            }
        } else {
            for (uint256 i = 0; i < _allowedAddresses.length; i++) {
                require(_allowedAddresses.length == _mockPrices.length, "Size of address/price lists don't match");
                allowedAddresses[_allowedAddresses[i]] = true;
                nftAddressToMockFloorPrice[_allowedAddresses[i]]=_mockPrices[i];
            }
        }
    }

    function makeOffer(
        address _nftAddress, 
        uint256 _tokenId, 
        uint256 _tokenValuation,
        uint256 _loanValue,
        bytes32 _injectiveAddress,
        uint32 _duration
    ) public {
        require(allowedAddresses[_nftAddress], "NFT collection not supported");
        require(_loanValue < _tokenValuation * maxBorrowPercentage / 100, "Loan should be less than 60% of token valuation");
        require(_duration >= 30 days || _duration <= 180 days, "Duration must be within 30 and 180 days");
        
        IERC721 nft = IERC721(_nftAddress);
        nft.safeTransferFrom(msg.sender, address(this), _tokenId);

        uint256 tokenFloorPrice = getFloorPrice(_nftAddress);

        offers.push(Offer(
            true,
            msg.sender,
            _nftAddress,
            _tokenId,
            _tokenValuation,
            tokenFloorPrice,
            _loanValue,
            _injectiveAddress,
            _duration,
            interestRate
        ));
    }

    // TODO: make this more gas-efficient by copying offer to memory then dumping to storage
    function cancelOffer(uint256 offerIndex) public {
        Offer storage offer = offers[offerIndex];
        
        require(offer.isActive, "Offer is not active");
        require(msg.sender == offer.borrower, "Offer not owned by msg.sender");
        
        offer.isActive = false;
        IERC721 nft = IERC721(offer.nftAddress);
        nft.transferFrom(address(this), msg.sender, offer.tokenId);
    }

    // TODO: make this more gas-efficient by copying offer to memory then dumping to storage
    function acceptOffer(uint256 offerIndex) public {
        Offer storage offer = offers[offerIndex];
        offer.isActive = false;

        loans.push(Loan(
            offer,
            true,
            msg.sender,
            block.timestamp
        ));

        weth.safeTransferFrom(msg.sender, address(this), offer.loanValue);
        weth.approve(address(peggyBridge), offer.loanValue);

        // if (block.chainId == 1 or block.chainId == 5){
        //     peggyBridge.sendToInjective(
        //         address(weth),
        //         offer.injectiveAddress,
        //         offer.loanValue,
        //         _
        //     );
        // }
        
    }

    // TODO: make this more gas-efficient by copying offer to memory then dumping to storage
    function liquidateDefaultedPosition(uint256 loanIndex) public {
        Loan storage loan = loans[loanIndex];
        require(loan.isActive, "Loan was already liquidated");
        loan.isActive = false;

        uint256 currentFloorPrice = getFloorPrice(loan.offer.nftAddress);
        
        uint256 currentValuation = loan.offer.tokenValuation * currentFloorPrice / loan.offer.tokenFloorPrice;
        require(
            loan.offer.loanValue > currentValuation ||
            loan.initialDate + loan.offer.duration >= block.timestamp
        , "Position still healthy or time not elapsed");
        
        
        IERC721 nft = IERC721(loan.offer.nftAddress);
        nft.safeTransferFrom(address(this), loan.lender, loan.offer.tokenId);

    }

    function repayLoan(uint256 loanIndex) public {
        Loan storage loan = loans[loanIndex];
        
        require(loan.initialDate + loan.offer.duration <= block.timestamp);
        require(loan.isActive, "Loan is not active");
        loan.isActive = false;
        
        uint256 anualInterest = loan.offer.loanValue * loan.offer.interestRate / 100;
        uint256 interest = anualInterest * loan.offer.duration / DAYS_PER_YEAR;
        uint256 repayValue = loan.offer.loanValue + interest;
        weth.safeTransferFrom(msg.sender, loan.lender, repayValue);

        IERC721 nft = IERC721(loan.offer.nftAddress);
        nft.safeTransferFrom(address(this), msg.sender, loan.offer.tokenId);
    }

    function getFloorPrice(address _nftCollection) external view returns (uint256) {
        if (block.chainId != 1){
            return nftAddressToMockFloorPrice[_nftCollection];
        }

        AggregatorV3Interface priceFeed = AggregatorV3Interface(nftAddressToPriceFeedAddress[_nftCollection]);
        int256 floorPrice;
        (_,floorPrice,_,_,_) = priceFeed.latestRoundData();
        require(floorPrice > 0, "Invalid floor price");
        return floorPrice;
    }

    function getOffers() public view returns (Offer[] memory){
        return offers;
    }
    
    function getLoans() public view returns (Loan[] memory){
        return loans;
    }

    function getInterestRate() public view returns (uint8) {
        return interestRate;
    }
}