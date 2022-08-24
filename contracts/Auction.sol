// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

contract Auction {
    IERC721 NFTaddress;
    bool started;
    bool ended;
    address seller;
    string NFTname;
    address highestBidder;
    uint256 NFTId;
    uint256 TimeEnded;
    uint256 highestBid;
    uint256 lastcaller;
    uint256 endAt;

    struct Bid{
        uint256 amount;
        uint256 timeOfBid;
    }

    mapping(address=> Bid) bidder;

    constructor(address _NFTaddress, string memory _NFTname, uint256 _NFTId){
        NFTaddress = IERC721(_NFTaddress);
        require(msg.sender == NFTaddress.ownerOf(_NFTId), "You are not an owner of these NFT");
        seller = msg.sender;
        NFTname = _NFTname;
        NFTId = _NFTId;
    }

    modifier onlyOwner {
        require(msg.sender == seller, "You are not a seller");
        _;
    }

    function StartAuction(uint256 _minBid) public onlyOwner {
        require(msg.sender == seller, "Not the right seller");

        NFTaddress.transferFrom(msg.sender, address(this), NFTId);
        require(!started, "The Auction already started");

        highestBid = _minBid;
        started = true;

        lastcaller = block.timestamp + 20 minutes;
        endAt = block.timestamp + 12 hours;
    }

    function PlaceBid() public payable{
        if(block.timestamp >= lastcaller + 5 minutes | endAt){
            endAuction();
        }
        else{
            require(started, "Auction have not started or ended");
            require(msg.sender != address(0), "can't send to zero address"); // sanity check
            require(msg.value > highestBid, "There's an higher bid");

            Bid storage bid = bidder[msg.sender];

            bid.amount += msg.value;
            bid.timeOfBid = block.timestamp;

            highestBid = bid.amount;
            highestBidder = msg.sender;
            lastcaller = bid.timeOfBid;
        }
    }

    function endAuction() internal {
        require(!ended, "The Auction has ended");
        require(NFTaddress.ownerOf(NFTId) == address(this), "The NFT has been trabsferred to the highest bidder");
        require(msg.sender != address(0), "you can't send to zero address");
        
        NFTaddress.safeTransferFrom(address(this), highestBidder, NFTId);
        uint256 winnerValue = bidder[highestBidder].amount;
        bidder[highestBidder].amount = 0;
        payable(seller).transfer(winnerValue);
        ended = true;

    }

    function withdraw() public {
        require(NFTaddress.ownerOf(NFTId) == address(this), "The NFT has been trabsferred to the highest bidder");
        require(msg.sender != address(0), "can't send to zero address");
        require(ended, "You can only withdraw after the auction ended");
        uint256 userValue = bidder[msg.sender].amount;
        bidder[msg.sender].amount = 0;
        payable(msg.sender).transfer(userValue);

    }
}