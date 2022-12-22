//SPDX-License-Identifier: MIT
 pragma solidity ^0.8.17;

contract EthersAd 
{
    address owner;
    uint duration = 1 days;
    uint coolDown = 1 minutes;
    string emptyString;
   Slot[10] public slots;
   mapping(string => mapping(address => Listing)) internal listings;

    enum Status {
        readyForBids,
        running,
        coolDown,
        funding
    }
    struct Slot {
        uint id;
        bool isActive;
        Status status;
        uint bid;
        uint minBid;
        uint startTime;
        uint endTime;
        uint coolDownnTime;
        uint fundingTime;
        string listing;
        bool hasRest;
    }
   struct Listing{
       string link;
   }

   modifier onlyOnwer{
       require(msg.sender == owner,"Not Authorized");
       _;
   }
   
   constructor(){
       owner = msg.sender;
   }

    // Create Ad Slots Max 10
  function setSlotBid(uint _slot, uint _bid) public onlyOnwer {
      slots[_slot].bid = _bid;
      slots[_slot].minBid = _bid;
  }

    /// Create Listing
    function createListing(string memory _name, string memory _link) public{
        Listing memory listing = Listing(_link);
        listings[_name][msg.sender] = listing;
    }

    function makeABid(uint _slot,string memory _lisitng, uint _amount) public {
        _slot = _slot -1 ; // reduce slot numer so it can match the right index
        updateSlotStatus(_slot);
        
        startBidding(_lisitng, _slot, _amount);

        // If ths slot is not active set it to active and set the cooldown time
        if(slots[_slot].isActive == false){
            slots[_slot].coolDownnTime = block.timestamp + coolDown;
            slots[_slot].isActive = true;
        }

        // Set new bid ammount and listing in the slot
        // This will not be set in sone until the bidding period is down
        slots[_slot].bid = _amount;
        slots[_slot].listing = listings[_lisitng][msg.sender].link;
        
        restSlot(_slot); // Rest slot values to default 
        setSlot(_slot); // Set change staus to funding preventing any more bids
    }

    function startBidding(string memory _lisitng, uint _slot , uint _amount) internal{
        if(slots[_slot].hasRest){
            require(slots[_slot].status == Status.readyForBids,"Not ready to bid"); // Check the status to see if its ok to bid
            require(_amount > slots[_slot].bid,"Increase bid amount"); // Input amount has to be more than previous bid
             // If ths slot is not active set it to active and set the cooldown time
            if(slots[_slot].coolDownnTime == 0){
                slots[_slot].coolDownnTime = block.timestamp + coolDown;
            }

            // Set new bid ammount and listing in the slot
            // This will not be set in sone until the bidding period is down
            slots[_slot].bid = _amount;
            slots[_slot].listing = listings[_lisitng][msg.sender].link;
        }
        
    }

    function updateSlotStatus(uint _slot) internal {
        if(block.timestamp > slots[_slot].startTime && block.timestamp < slots[_slot].endTime){
            slots[_slot].status = Status.running;
        }
        if(block.timestamp > slots[_slot].endTime && block.timestamp < slots[_slot].coolDownnTime){
            slots[_slot].status = Status.readyForBids;
            slots[_slot].hasRest = true;
        }
        if(block.timestamp >= slots[_slot].coolDownnTime && slots[_slot].isActive){
            slots[_slot].status = Status.funding;
           slots[_slot].fundingTime = block.timestamp + 1 minutes;
        }
    }

    function setSlot(uint _slot) internal {
        if(block.timestamp >= slots[_slot].coolDownnTime){
           slots[_slot].fundingTime = block.timestamp + 1 minutes;
        }
    }

    function restSlot(uint _slot) internal{
        if(!slots[_slot].hasRest){
            slots[_slot].status = Status.readyForBids;
            slots[_slot].listing = "";
            slots[_slot].bid = slots[_slot].minBid;
             slots[_slot].fundingTime = 0;
            slots[_slot].hasRest = true;
        }
    }

    function fundSlot(uint _slot, string memory _lisitng) public payable{
        // Send money to the smart contract
        slots[_slot].id;
    }

    function getListingInfo(string memory _lisitng) public view returns (string memory){
       return  listings[_lisitng][msg.sender].link;
    }
}
