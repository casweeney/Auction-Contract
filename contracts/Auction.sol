// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

contract AuctionCas {
    IERC721 ItemAddress;
    uint itemId;
    string itemName;
    bool AuctionStarted;
    bool AuctionEnded;
    uint highestBidAmount;
    address highestBidder;

    address itemSeller;

    uint auctionPeriod = block.timestamp + 24 days;

    modifier onlyOwner() {
        require(msg.sender == itemSeller);
        _;
    }

    mapping(address => uint) bidders;

    constructor(address _itemAddress, string memory _itemName, uint _itemId) {
        ItemAddress = IERC721(_itemAddress);
        require(msg.sender == ItemAddress.ownerOf(_itemId));
        itemSeller = msg.sender;
        itemName = _itemName;
        itemId = _itemId;
    }

    function startAuction(uint _minBidAmount) external onlyOwner {
       require(!AuctionStarted, "Auction already started");

        ItemAddress.transferFrom(msg.sender, address(this), itemId);

        highestBidAmount = _minBidAmount;
        AuctionStarted = true;
    }

    function bid() external payable {
        require(AuctionStarted == true, "Can't bid now, auction hasn't started yet");
        require(msg.value > highestBidAmount, "can't bid less than highest bid");

        if(block.timestamp > auctionPeriod) {
            endAuction();
        } else {
            bidders[msg.sender] += msg.value;
            highestBidAmount = msg.value;
            highestBidder = msg.sender;
        }
    }

    function endAuction() public onlyOwner {
        require(AuctionEnded == false, "Auction already ended");
        require(bidders[highestBidder] == highestBidAmount, "This doesn't correlate");

        uint winningAmount = bidders[highestBidder];

        bidders[highestBidder] = 0;

        payable(itemSeller).transfer(winningAmount);
        ItemAddress.safeTransferFrom(address(this), highestBidder, itemId);

        AuctionEnded = true;
    }

    function withdraw() external {
        require(AuctionEnded == true, "You can't withdraw until action ends");
        require(bidders[msg.sender] > 0, "You didn't bid here");

        uint biddedAmount = bidders[msg.sender];
        bidders[msg.sender] = 0;

        payable(msg.sender).transfer(biddedAmount);
    }
}