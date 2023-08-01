// Import the necessary libraries and dependencies
const { expect } = require("chai");
const { ethers, waffle } = require("hardhat");
const { deployContract } = waffle;

// Describe the test suite for the Hotel contract
describe("Hotel Contract", function () {
    // Define variables to hold contract instances and addresses
    let hotelContract;
    let owner, landlord, tenant;
    let RoomAddedEvent, AgreementSignedEvent, RentPaidEvent, AgreementCompletedEvent, AgreementTerminatedEvent;
  
    // Deploy the contract before running tests
    beforeEach(async function () {
      // Get accounts from ethers provider
      [owner, landlord, tenant] = await ethers.getSigners();
  
      // Compile and deploy the contract
      const Hotel = await ethers.getContractFactory("Hotel");
      hotelContract = await deployContract(owner, Hotel);
    });
  
    // Test for adding a new room
    it("Should add a new room", async function () {
        // Add a new room using the 'addRoom' function
        const roomTx = await hotelContract.addRoom("Room 101", "Address 123", 100, 200);
        // Wait for the transaction to be mined
        await roomTx.wait();
    
        // Get the room details by calling the 'Rooms' mapping
        const room = await hotelContract.Rooms(1);
    
        // Check if the room details are correct
        expect(room.room_name).to.equal("Room 101");
        expect(room.room_address).to.equal("Address 123");
        expect(room.rent_per_month).to.equal(100);
        expect(room.security_deposit).to.equal(200);
        expect(room.landlord).to.equal(owner.address);
    });

    // Test for signing an agreement
    it("Should sign an agreement", async function () {
        // Sign an agreement using the 'signAgreement' function
        const agreementTx = await hotelContract.signAgreement(1, 86400); // 86400 seconds (1 day) lock period
        // Wait for the transaction to be mined
        await agreementTx.wait();
    
        // Get the agreement details by calling the 'Agreements' mapping
        const agreement = await hotelContract.Agreements(1);
    
        // Check if the agreement details are correct
        expect(agreement.room_id).to.equal(1);
        expect(agreement.room_name).to.equal("Room 101");
        expect(agreement.room_address).to.equal("Address 123");
        expect(agreement.rent_per_month).to.equal(100);
        expect(agreement.security_deposit).to.equal(200);
        expect(agreement.lockperiod).to.equal(86400);
        expect(agreement.landlord_address).to.equal(owner.address);
        expect(agreement.tenant_address).to.equal(tenant.address);
    });
  
  
  });
  