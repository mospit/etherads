//SPDX-License-Identifier: MIT
 pragma solidity ^0.8.17;

contract EthersAd 
{
    address owner;
    uint day = 1 days;
    uint coolDown = 1 minutes;
    string emptyString;
    Slot[10] public slots;
    uint[10] internal highestBidders;
    uint[10] internal highestBiddingBid;
    uint256 minBid = 0.1 ether;
    mapping(string => mapping(address => Listing)) internal listings;
    mapping(address => mapping(uint => uint)) internal fundsByBidder;

    event Bid(address indexed bidder, uint bidAmount, string listing, string listingLink);
    event WinningBid(address indexed bidder, uint bidAmount, string listing, string listingLink);
    event ResetSlot();
    event FundSlot();

    enum Status {
        readyForBids,
        running,
        coolDown,
        funding
    }
    struct Slot {
        address bidder;
        Status status;
        uint bid;
        uint minBid;
        uint amtPerDay;
        uint duration;
        uint startTime;
        uint endTime;
        uint coolDownnTime;
        uint fundingTime;
        string listing;
    }
   struct Listing{
       address owner;
       string link;
   }

   modifier onlyOnwer{
       require(msg.sender == owner,"Not Authorized");
       _;
   }
   
   constructor() payable {
       // Set Slots bid amount to minimum
       createSlot(0,minBid);
       createSlot(1,minBid);
       createSlot(2,minBid);
       createSlot(3,minBid);
       createSlot(4,minBid);
       createSlot(5,minBid);
       createSlot(6,minBid);
       createSlot(7,minBid);
       createSlot(8,minBid);
       createSlot(9,minBid);

        // Assign contract deplyer as owner
        owner = msg.sender;
   }

    // Create Ad Slots Max 10
  function createSlot(uint _slot, uint _bid) internal {
      slots[_slot].bid = _bid;
      slots[_slot].minBid = _bid;
      slots[_slot].amtPerDay = _bid;
  }

    /// Create Listing
    function createListing(string memory _name, string memory _link) public{
        Listing memory listing = Listing(msg.sender,_link);
        listings[_name][msg.sender] = listing;

    }

    function bid(uint _slot,string memory _lisitng, uint _amount, uint _days) public  payable{
        require(msg.value >= minBid,"Bid to low");
        _slot = _slot - 1 ; // reduce slot numer so it can match the right index

        Status status= slots[_slot].status; // Assign minimum status to vvariable
        uint bid = _amount;
        uint amountPerDay = _amount / _days; // Assign minimum bid to vvariable
        uint previousAmtPerDay = slots[_slot].amtPerDay; // Previous amount per day
        string memory listing = listings[_lisitng][msg.sender].link; // Assign minimum listing to vvariable

        uint highestBid = highestBiddingBid[_slot];
        uint newBid = fundsByBidder[msg.sender][_slot] + msg.value;

        if(slots[_slot].coolDownnTime == 0){
             slots[_slot].coolDownnTime = block.timestamp + 1 minutes;
        }
        uint coolDownTime = slots[_slot].coolDownnTime;
        
        // Update Slot status before continuing
         if(block.timestamp > slots[_slot].startTime && block.timestamp < slots[_slot].endTime){
            slots[_slot].status = Status.running;
        }
        if(block.timestamp > slots[_slot].endTime && block.timestamp < slots[_slot].coolDownnTime){
            slots[_slot] = Slot(address(0),Status.readyForBids,minBid,minBid,0,0,0,0,block.timestamp,0,"");
        }
        if(slots[_slot].coolDownnTime != 0 && block.timestamp > slots[_slot].coolDownnTime){
            slots[_slot].status = Status.funding;
            slots[_slot].fundingTime = block.timestamp + 1 minutes;

            emit WinningBid(msg.sender,_amount,_lisitng, listings[_lisitng][msg.sender].link);
        }
        
        // Set the slot to current bidder untl the time is up
        if( newBid < highestBid){revert();}
        if(slots[_slot].status == Status.readyForBids){
            require(amountPerDay > previousAmtPerDay,"Increase bid amount"); // Input amount has to be more than previous bid
            require(_days > 0, "Can't be 0"); // Check if the "days" input is greater than zero

            // This will not be set in sone until the bidding period is down
           // slots[_slot] = Slot(msg.sender,status,bid,minBid,amountPerDay,0,0,0,coolDownTime,0,listing);
           highestBidders[_slot] = msg.sender;
           highestBiddingBid[_slot] = newBid;
           fundsByBidder[msg.sender][_slot] = newBid;

            emit Bid(msg.sender,_amount, _lisitng, listings[_lisitng][msg.sender].link);
        }
    }

    // Slot Winner pays for the slot
    function fundSlot(uint _slot, string memory _lisitng) public payable{
        // Send money to the smart contract
        require(slots[_slot].status == Status.funding, "Not ready to fund");
        slots[_slot].startTime = block.timestamp;
        slots[_slot].endTime = slots[_slot].startTime + slots[_slot].duration;
        slots[_slot].coolDownnTime = slots[_slot].endTime + coolDown;

    }

    function payMe(address payable _to) public payable returns (uint) {
        require(msg.value >= minBid);
        (bool sent, bytes memory data) = _to.call{value: msg.value}("");
         require(sent, "Failed to send Ether");
    }
}
