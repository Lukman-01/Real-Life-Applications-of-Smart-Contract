// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

contract Hotel{
    address payable landlord;
    address payable tenant;

    uint no_of_rooms = 0;
    uint no_of_rent = 0;
    uint no_of_agreement = 0;

    struct Room{
        uint room_id;
        uint agreement_id;
        string room_name;
        string room_address;
        uint rent_per_month;
        uint security_deposit;
        uint timestamp;
        bool vacant;
        address payable landlord;
        address payable current_tenant;
    }

    mapping(uint => Room) public Rooms;

    struct RoomAgreement{
        uint room_id;
        uint agreement_id;
        string room_name;
        string room_address;
        uint rent_per_month;
        uint security_deposit;
        uint lockperiod;
        uint timestamp;
        address payable landlord_address;
        address payable tenant_address;
    }

    mapping(uint => RoomAgreement) public Agreements;

    struct Rent{
        uint rent_id;
        uint room_id;
        uint agreement_id;
        string room_name;
        string room_address;
        uint rent_per_month;
        uint timestamp;
        address payable landlord_address;
        address payable tenant_address;
    }

    mapping(uint => Rent) public Rents;

    modifier OnlyLandlord(uint _id){
        require(msg.sender == Rooms[_id].landlord, "Only landlord can call this function");
        _;
    }

    modifier OnlyTenant(uint _id){
        require(msg.sender == Rooms[_id].current_tenant, "Only tenants can call this function");
        _;
    }

    modifier notOccupied(uint _id){
        require(Rooms[_id].vacant == true, "This room is occupied");
        _;
    }

    modifier CheckAmount(uint _id){
        require(msg.value >= uint(Rooms[_id].rent_per_month * 1 ether), "You have insufficient amount for the rent");
        _;
    }

    modifier enoughAgreement(uint _id){
        require(msg.value >= uint(uint(Rooms[_id].rent_per_month) + uint(Rooms[_id].security_deposit)), "Not enough Agreement fee");
        _;
    }

    modifier sameTenant(uint _id){
        require(msg.sender == Rooms[_id].current_tenant, "No previous agreement");
        _;
    }

    modifier AgreementTimeLeft(uint _id){
        uint agrId = Rooms[_id].agreement_id;
        uint time = Agreements[agrId].timestamp + Agreements[agrId].lockperiod;
        require(block.timestamp < time, "Agreement ended");
        _;
    }

    modifier AgreementTimesUp(uint _id){
        uint agrId = Rooms[_id].agreement_id;
        uint time = Agreements[agrId].timestamp + Agreements[agrId].lockperiod;
        require(block.timestamp > time, "There is still some time left");
        _;
    }

    modifier RentTimesUp(uint _id){
        uint time = Rooms[_id].timestamp + 30 days;
        require(block.timestamp >= time, "Times Up");
        _;
    }

    event RoomAdded(
    uint indexed roomId,
    string room_name,
    string room_address,
    uint rent_per_month,
    uint security_deposit,
    address landlord
    );

    event AgreementSigned(
    uint indexed agreementId,
    uint roomId,
    string room_name,
    string room_address,
    uint rent_per_month,
    uint security_deposit,
    uint lockperiod,
    address landlord,
    address tenant
    );

    event RentPaid(
    uint rentId,
    uint indexed roomId,
    string room_name,
    string room_address,
    uint rent_per_month,
    address indexed landlord,
    address indexed tenant
    );

    event AgreementCompleted(
    uint indexed roomId,
    string room_name,
    string room_address,
    uint rent_per_month,
    address indexed landlord
    );

    event AgreementTerminated(
    uint indexed roomId,
    string room_name,
    string room_address,
    uint rent_per_month,
    address indexed landlord
    );

    function addRoom(
    string memory _roomName,
    string memory _roomAddress,
    uint _rentPerMonth,
    uint _securityDeposit
    ) external {
        require(msg.sender != address(0));
        no_of_rooms++; // Increment the total number of rooms
        uint roomId = no_of_rooms; // Assign the new room ID

        // Create a new Room struct instance and initialize its values
        Room memory newRoom = Room({
            room_id: roomId,
            agreement_id: 0, // Initialize agreement_id to 0 since it's a new room and has no agreement yet
            room_name: _roomName,
            room_address: _roomAddress,
            rent_per_month: _rentPerMonth,
            security_deposit: _securityDeposit,
            timestamp: block.timestamp, // Set the current timestamp as the room's creation timestamp
            vacant: true, // Set vacant to true since the room is initially available for rent
            landlord: payable(msg.sender), // Set the landlord as the one who adds the room
            current_tenant: payable(address(0)) // Set the current_tenant to address(0) since there's no tenant initially
        });

        // Store the new room in the mapping using its ID as the key
        Rooms[roomId] = newRoom;

        // Emit an event to notify the addition of a new room
        emit RoomAdded(
            roomId,
            _roomName,
            _roomAddress,
            _rentPerMonth,
            _securityDeposit,
            msg.sender
        );
    }

    function signAgreement(
        uint _roomId, 
        uint _lockperiod
        ) external payable 
        OnlyTenant(_roomId) notOccupied(_roomId) 
        CheckAmount(_roomId) enoughAgreement(_roomId) AgreementTimesUp(_roomId) {
    // Increment the total number of agreements
        no_of_agreement++;
        uint agreementId = no_of_agreement;

        // Get the room details
        Room storage room = Rooms[_roomId];

        // Create a new RoomAgreement struct instance and initialize its values
        RoomAgreement memory newAgreement = RoomAgreement(
            _roomId,
            agreementId,
            room.room_name,
            room.room_address,
            room.rent_per_month,
            room.security_deposit,
            _lockperiod,
            block.timestamp, // Set the current timestamp as the agreement's creation timestamp
            room.landlord,
            payable(msg.sender) // Set the tenant as the one who signs the agreement
        );

        // Store the new agreement in the Agreements mapping using its ID as the key
        Agreements[agreementId] = newAgreement;

        // Update the room's agreement_id and current_tenant fields
        room.agreement_id = agreementId;
        room.current_tenant = payable(msg.sender);
        room.vacant = false; // Set the room as occupied
        room.timestamp = block.timestamp;

        // Emit an event to notify the signing of the agreement
        emit AgreementSigned(
            agreementId,
            _roomId,
            room.room_name,
            room.room_address,
            room.rent_per_month,
            room.security_deposit,
            _lockperiod,
            room.landlord,
            msg.sender
        );
    }

    function payRent(uint _roomId) external payable OnlyTenant(_roomId) AgreementTimeLeft(_roomId) RentTimesUp(_roomId) CheckAmount(_roomId) {
    // Get the room details
        Room storage room = Rooms[_roomId];
        uint agreementId = room.agreement_id;

        // Update the rent counter
        no_of_rent++;
        uint rentId = no_of_rent;

        // Create a new Rent struct instance and initialize its values
        Rent memory newRent = Rent(
            rentId,
            _roomId,
            agreementId,
            room.room_name,
            room.room_address,
            room.rent_per_month,
            block.timestamp, // Set the current timestamp as the rent payment timestamp
            room.landlord,
            room.current_tenant
        );

        // Store the new rent payment in the Rents mapping using its ID as the key
        Rents[rentId] = newRent;

        // Transfer the rent amount to the landlord
        room.landlord.transfer(room.rent_per_month * 1 ether);

        // Emit an event to notify the rent payment
        emit RentPaid(
            rentId,
            _roomId,
            room.room_name,
            room.room_address,
            room.rent_per_month,
            room.landlord,
            room.current_tenant
        );
    }

    function agreementCompleted(uint _roomId) external OnlyLandlord(_roomId) AgreementTimeLeft(_roomId) {
        // Get the room details
        Room storage room = Rooms[_roomId];

        // Set the room as vacant and clear the agreement details
        room.vacant = true;
        room.agreement_id = 0;
        room.current_tenant = payable(address(0));

        // Emit an event to notify the completion of the agreement
        emit AgreementCompleted(
            _roomId,
            room.room_name,
            room.room_address,
            room.rent_per_month,
            room.landlord
        );
    }

}