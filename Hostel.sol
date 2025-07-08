// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract RentSmart {
    uint public roomCount; 
    uint public agreementCount;

    struct Room {
        uint id;
        address payable landlord;
        string name;
        string location;
        uint rentPerMinute;
        uint securityDeposit;
        bool isVacant;
        address payable currentTenant;
        uint lastRentPaidAt;
        uint agreementId;
    }

    struct Agreement {
        uint id;
        uint roomId;
        address payable tenant;
        uint leaseStart;
        uint leaseDuration;
        bool active;
    }

    mapping(uint => Room) public rooms;
    mapping(uint => Agreement) public agreements;

    event RoomListed(uint roomId, address landlord);
    event AgreementSigned(uint agreementId, address tenant);
    event RentPaid(uint roomId, address tenant, uint amount);
    event LeaseEnded(uint agreementId);

    modifier onlyLandlord(uint id) { 
        require(msg.sender == rooms[id].landlord, "Not landlord"); 
        _; 
    }
    
    modifier onlyTenant(uint id) { 
        require(msg.sender == rooms[id].currentTenant, "Not tenant"); 
        _; 
    }
    
    modifier isLeaseActive(uint id) { 
        require(agreements[rooms[id].agreementId].active, "Inactive lease"); 
        _; 
    }

    function listRoom(string memory _name, string memory _loc, uint _rentPerMinute, uint _dep) public {
        roomCount++;
        rooms[roomCount] = Room(roomCount, payable(msg.sender), _name, _loc, _rentPerMinute, _dep, true, payable(0), 0, 0);
        emit RoomListed(roomCount, msg.sender);
    }

    function signAgreement(uint id, uint leaseMinutes) public payable {
        Room storage r = rooms[id];
        require(r.isVacant, "Occupied");
        require(msg.value >= r.rentPerMinute + r.securityDeposit, "Low payment");
        r.landlord.transfer(r.rentPerMinute + r.securityDeposit);
        agreementCount++;
        agreements[agreementCount] = Agreement(agreementCount, id, payable(msg.sender), block.timestamp, leaseMinutes * 1 seconds, true);
        r.isVacant = false; 
        r.currentTenant = payable(msg.sender); 
        r.lastRentPaidAt = block.timestamp; 
        r.agreementId = agreementCount;
        emit AgreementSigned(agreementCount, msg.sender);
    }

    function payRent(uint id) public payable onlyTenant(id) isLeaseActive(id) {
        Room storage r = rooms[id];
        require(msg.value >= r.rentPerMinute, "Low rent");
        require(block.timestamp >= r.lastRentPaidAt + 1 seconds, "Not due yet");
        r.landlord.transfer(r.rentPerMinute);
        r.lastRentPaidAt = block.timestamp;
        emit RentPaid(id, msg.sender, msg.value);
    }


    // Function to get the current block timestamp
    function getCurrentTime() public view returns (uint) {
        return block.timestamp;
    }
}
