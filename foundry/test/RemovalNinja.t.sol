// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.19;

import {Test, console} from "forge-std/Test.sol";
import {RemovalNinja} from "../src/RemovalNinja.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * @title RemovalNinja Test Suite
 * @dev Comprehensive tests with fuzzing for the RemovalNinja protocol
 */
contract RemovalNinjaTest is Test {
    RemovalNinja public removalNinja;
    
    // Test accounts
    address public owner;
    address public alice;
    address public bob;
    address public charlie;
    address public processor1;
    address public processor2;
    address public maliciousActor;
    
    // Constants for testing
    uint256 public constant INITIAL_SUPPLY = 1000000 * 10**18;
    uint256 public constant BROKER_REWARD = 100 * 10**18;
    uint256 public constant PROCESSING_REWARD = 50 * 10**18;
    uint256 public constant MIN_USER_STAKE = 10 * 10**18;
    uint256 public constant MIN_PROCESSOR_STAKE = 1000 * 10**18;
    
    // Events to test
    event DataBrokerSubmitted(uint256 indexed brokerId, string name, address indexed submitter);
    event ProcessorRegistered(address indexed processor, uint256 stake, string description);
    event UserStakedForRemoval(address indexed user, uint256 amount, address[] selectedProcessors);
    event RemovalRequested(uint256 indexed removalId, address indexed user, uint256 indexed brokerId, address processor);
    event RemovalCompleted(uint256 indexed removalId, address indexed processor, string zkProof);
    event ProcessorSlashed(address indexed processor, uint256 slashedAmount, string reason);
    event BrokerVerified(uint256 indexed brokerId, address indexed verifier);
    
    function setUp() public {
        // Deploy contract
        removalNinja = new RemovalNinja();
        
        // Set up test accounts
        owner = address(this);
        alice = makeAddr("alice");
        bob = makeAddr("bob");
        charlie = makeAddr("charlie");
        processor1 = makeAddr("processor1");
        processor2 = makeAddr("processor2");
        maliciousActor = makeAddr("maliciousActor");
        
        // Give test accounts some tokens
        removalNinja.transfer(alice, 10000 * 10**18);
        removalNinja.transfer(bob, 10000 * 10**18);
        removalNinja.transfer(charlie, 5000 * 10**18);
        removalNinja.transfer(processor1, 20000 * 10**18);
        removalNinja.transfer(processor2, 20000 * 10**18);
        removalNinja.transfer(maliciousActor, 5000 * 10**18);
        
        // Labels for easier debugging
        vm.label(alice, "Alice");
        vm.label(bob, "Bob");
        vm.label(charlie, "Charlie");
        vm.label(processor1, "Processor1");
        vm.label(processor2, "Processor2");
        vm.label(maliciousActor, "MaliciousActor");
    }
    
    // ============ Basic Contract Tests ============
    
    function test_InitialState() public view {
        assertEq(removalNinja.name(), "RemovalNinja");
        assertEq(removalNinja.symbol(), "RN");
        assertEq(removalNinja.totalSupply(), INITIAL_SUPPLY);
        assertEq(removalNinja.balanceOf(owner), INITIAL_SUPPLY - 70000 * 10**18); // After setUp transfers: 10k+10k+5k+20k+20k+5k = 70k
        assertEq(removalNinja.owner(), owner);
        assertFalse(removalNinja.paused());
    }
    
    function test_OwnershipTransfer() public {
        removalNinja.transferOwnership(alice);
        assertEq(removalNinja.owner(), alice);
    }
    
    function test_PauseUnpause() public {
        // Test pause
        removalNinja.pause();
        assertTrue(removalNinja.paused());
        
        // Test unpause
        removalNinja.unpause();
        assertFalse(removalNinja.paused());
    }
    
    function test_RevertWhen_NonOwnerPauses() public {
        vm.prank(alice);
        vm.expectRevert();
        removalNinja.pause();
    }
    
    // ============ Data Broker Tests ============
    
    function test_SubmitDataBroker() public {
        vm.startPrank(alice);
        
        // Check initial balance
        uint256 initialBalance = removalNinja.balanceOf(alice);
        
        // Submit broker
        vm.expectEmit(true, false, false, true);
        emit DataBrokerSubmitted(1, "TestBroker", alice);
        
        removalNinja.submitDataBroker(
            "TestBroker",
            "https://testbroker.com",
            "Email privacy@testbroker.com"
        );
        
        // Check broker was created
        (
            uint256 id,
            string memory name,
            string memory website,
            string memory instructions,
            address submitter,
            bool isVerified,
            uint256 submissionTime,
            uint256 totalRemovals
        ) = removalNinja.dataBrokers(1);
        
        assertEq(id, 1);
        assertEq(name, "TestBroker");
        assertEq(website, "https://testbroker.com");
        assertEq(instructions, "Email privacy@testbroker.com");
        assertEq(submitter, alice);
        assertFalse(isVerified);
        assertEq(submissionTime, block.timestamp);
        assertEq(totalRemovals, 0);
        
        // Check reward was given
        assertEq(removalNinja.balanceOf(alice), initialBalance + BROKER_REWARD);
        
        vm.stopPrank();
    }
    
    function test_RevertWhen_SubmitEmptyBrokerName() public {
        vm.prank(alice);
        vm.expectRevert("Name cannot be empty");
        removalNinja.submitDataBroker("", "https://test.com", "instructions");
    }
    
    function test_RevertWhen_SubmitEmptyBrokerWebsite() public {
        vm.prank(alice);
        vm.expectRevert("Website cannot be empty");
        removalNinja.submitDataBroker("Test", "", "instructions");
    }
    
    function test_VerifyDataBroker() public {
        // Submit broker first
        vm.prank(alice);
        removalNinja.submitDataBroker("TestBroker", "https://test.com", "instructions");
        
        // Verify broker
        vm.expectEmit(true, true, false, false);
        emit BrokerVerified(1, owner);
        
        removalNinja.verifyDataBroker(1);
        
        // Check verification
        (, , , , , bool isVerified, , ) = removalNinja.dataBrokers(1);
        assertTrue(isVerified);
    }
    
    function test_RevertWhen_NonOwnerVerifiesBroker() public {
        vm.prank(alice);
        removalNinja.submitDataBroker("TestBroker", "https://test.com", "instructions");
        
        vm.prank(bob);
        vm.expectRevert();
        removalNinja.verifyDataBroker(1);
    }
    
    function test_RevertWhen_VerifyInvalidBroker() public {
        vm.expectRevert("Invalid broker ID");
        removalNinja.verifyDataBroker(999);
    }
    
    function test_GetAllDataBrokers() public {
        // Submit multiple brokers
        vm.startPrank(alice);
        removalNinja.submitDataBroker("Broker1", "https://broker1.com", "instructions1");
        removalNinja.submitDataBroker("Broker2", "https://broker2.com", "instructions2");
        vm.stopPrank();
        
        vm.prank(bob);
        removalNinja.submitDataBroker("Broker3", "https://broker3.com", "instructions3");
        
        // Get all brokers
        RemovalNinja.DataBroker[] memory brokers = removalNinja.getAllDataBrokers();
        assertEq(brokers.length, 3);
        assertEq(brokers[0].name, "Broker1");
        assertEq(brokers[1].name, "Broker2");
        assertEq(brokers[2].name, "Broker3");
    }
    
    // ============ Processor Tests ============
    
    function test_RegisterProcessor() public {
        vm.startPrank(processor1);
        
        uint256 stakeAmount = MIN_PROCESSOR_STAKE;
        string memory description = "Trusted processor service";
        
        // Check initial state
        assertFalse(removalNinja.isProcessor(processor1));
        
        // Register processor
        vm.expectEmit(true, false, false, true);
        emit ProcessorRegistered(processor1, stakeAmount, description);
        
        removalNinja.registerProcessor(stakeAmount, description);
        
        // Check processor was registered
        (
            address addr,
            bool isProcessorFlag,
            uint256 stake,
            string memory desc,
            uint256 completedRemovals,
            uint256 reputation,
            uint256 registrationTime,
            bool isSlashed
        ) = removalNinja.processors(processor1);
        
        assertEq(addr, processor1);
        assertTrue(isProcessorFlag);
        assertEq(stake, stakeAmount);
        assertEq(desc, description);
        assertEq(completedRemovals, 0);
        assertEq(reputation, 100);
        assertEq(registrationTime, block.timestamp);
        assertFalse(isSlashed);
        
        // Check stake was transferred
        assertEq(removalNinja.balanceOf(processor1), 20000 * 10**18 - stakeAmount);
        assertEq(removalNinja.balanceOf(address(removalNinja)), stakeAmount);
        
        // Check helper function
        assertTrue(removalNinja.isProcessor(processor1));
        
        vm.stopPrank();
    }
    
    function test_RevertWhen_RegisterProcessorInsufficientStake() public {
        vm.prank(processor1);
        vm.expectRevert("Insufficient stake amount");
        removalNinja.registerProcessor(MIN_PROCESSOR_STAKE - 1, "description");
    }
    
    function test_RevertWhen_RegisterProcessorInsufficientBalance() public {
        // Create a new address with insufficient balance
        address poorUser = makeAddr("poorUser");
        removalNinja.transfer(poorUser, MIN_PROCESSOR_STAKE - 1); // Give less than required
        
        vm.prank(poorUser);
        vm.expectRevert("Insufficient balance");
        removalNinja.registerProcessor(MIN_PROCESSOR_STAKE, "description");
    }
    
    function test_RevertWhen_RegisterProcessorTwice() public {
        vm.startPrank(processor1);
        removalNinja.registerProcessor(MIN_PROCESSOR_STAKE, "description");
        
        vm.expectRevert("Already registered as processor");
        removalNinja.registerProcessor(MIN_PROCESSOR_STAKE, "description");
        vm.stopPrank();
    }
    
    function test_SlashProcessor() public {
        // Register processor first
        vm.prank(processor1);
        removalNinja.registerProcessor(MIN_PROCESSOR_STAKE, "description");
        
        uint256 slashAmount = (MIN_PROCESSOR_STAKE * 10) / 100; // 10%
        string memory reason = "Poor performance";
        
        // Check initial state
        (, , uint256 initialStake, , , uint256 initialReputation, , bool initialSlashed) = removalNinja.processors(processor1);
        assertEq(initialStake, MIN_PROCESSOR_STAKE);
        assertEq(initialReputation, 100);
        assertFalse(initialSlashed);
        
        // Slash processor
        vm.expectEmit(true, false, false, true);
        emit ProcessorSlashed(processor1, slashAmount, reason);
        
        removalNinja.slashProcessor(processor1, reason);
        
        // Check processor was slashed
        (, , uint256 finalStake, , , uint256 finalReputation, , bool finalSlashed) = removalNinja.processors(processor1);
        assertEq(finalStake, initialStake - slashAmount);
        assertEq(finalReputation, 0);
        assertTrue(finalSlashed);
        
        // Check processor is no longer active
        assertFalse(removalNinja.isProcessor(processor1));
    }
    
    function test_RevertWhen_NonOwnerSlashesProcessor() public {
        vm.prank(processor1);
        removalNinja.registerProcessor(MIN_PROCESSOR_STAKE, "description");
        
        vm.prank(alice);
        vm.expectRevert();
        removalNinja.slashProcessor(processor1, "reason");
    }
    
    function test_GetAllProcessors() public {
        // Register multiple processors
        vm.prank(processor1);
        removalNinja.registerProcessor(MIN_PROCESSOR_STAKE, "Processor 1");
        
        vm.prank(processor2);
        removalNinja.registerProcessor(MIN_PROCESSOR_STAKE + 500 * 10**18, "Processor 2");
        
        // Get all processors
        RemovalNinja.Processor[] memory processors = removalNinja.getAllProcessors();
        assertEq(processors.length, 2);
        assertEq(processors[0].addr, processor1);
        assertEq(processors[1].addr, processor2);
    }
    
    // ============ User Staking Tests ============
    
    function test_StakeForRemoval() public {
        // Register processors first
        vm.prank(processor1);
        removalNinja.registerProcessor(MIN_PROCESSOR_STAKE, "Processor 1");
        
        vm.prank(processor2);
        removalNinja.registerProcessor(MIN_PROCESSOR_STAKE, "Processor 2");
        
        // User stakes for removal
        vm.startPrank(alice);
        
        uint256 stakeAmount = MIN_USER_STAKE * 2;
        address[] memory selectedProcessors = new address[](2);
        selectedProcessors[0] = processor1;
        selectedProcessors[1] = processor2;
        
        uint256 initialBalance = removalNinja.balanceOf(alice);
        
        vm.expectEmit(true, false, false, true);
        emit UserStakedForRemoval(alice, stakeAmount, selectedProcessors);
        
        removalNinja.stakeForRemoval(stakeAmount, selectedProcessors);
        
        // Check user state
        (
            bool isStakingForRemoval,
            uint256 userStakeAmount,
            uint256 stakeTime
        ) = removalNinja.users(alice);
        
        assertTrue(isStakingForRemoval);
        assertEq(userStakeAmount, stakeAmount);
        assertEq(stakeTime, block.timestamp);
        
        // Check selected processors separately
        address[] memory userSelectedProcessors = removalNinja.getUserSelectedProcessors(alice);
        assertEq(userSelectedProcessors.length, 2);
        assertEq(userSelectedProcessors[0], processor1);
        assertEq(userSelectedProcessors[1], processor2);
        
        // Check balance was transferred
        assertEq(removalNinja.balanceOf(alice), initialBalance - stakeAmount);
        
        // Check helper functions
        assertEq(removalNinja.userStakeAmount(alice), stakeAmount);
        address[] memory retrievedProcessors = removalNinja.getUserSelectedProcessors(alice);
        assertEq(retrievedProcessors.length, 2);
        assertEq(retrievedProcessors[0], processor1);
        assertEq(retrievedProcessors[1], processor2);
        
        vm.stopPrank();
    }
    
    function test_RevertWhen_StakeForRemovalInsufficientAmount() public {
        vm.prank(processor1);
        removalNinja.registerProcessor(MIN_PROCESSOR_STAKE, "Processor 1");
        
        address[] memory selectedProcessors = new address[](1);
        selectedProcessors[0] = processor1;
        
        vm.prank(alice);
        vm.expectRevert("Insufficient stake amount");
        removalNinja.stakeForRemoval(MIN_USER_STAKE - 1, selectedProcessors);
    }
    
    function test_RevertWhen_StakeForRemovalNoProcessors() public {
        address[] memory selectedProcessors = new address[](0);
        
        vm.prank(alice);
        vm.expectRevert("Must select at least one processor");
        removalNinja.stakeForRemoval(MIN_USER_STAKE, selectedProcessors);
    }
    
    function test_RevertWhen_StakeForRemovalInvalidProcessor() public {
        address[] memory selectedProcessors = new address[](1);
        selectedProcessors[0] = processor1; // Not registered
        
        vm.prank(alice);
        vm.expectRevert("Invalid processor");
        removalNinja.stakeForRemoval(MIN_USER_STAKE, selectedProcessors);
    }
    
    function test_RevertWhen_StakeForRemovalSlashedProcessor() public {
        // Register and slash processor
        vm.prank(processor1);
        removalNinja.registerProcessor(MIN_PROCESSOR_STAKE, "Processor 1");
        
        removalNinja.slashProcessor(processor1, "Poor performance");
        
        address[] memory selectedProcessors = new address[](1);
        selectedProcessors[0] = processor1;
        
        vm.prank(alice);
        vm.expectRevert("Processor is slashed");
        removalNinja.stakeForRemoval(MIN_USER_STAKE, selectedProcessors);
    }
    
    function test_RevertWhen_StakeForRemovalTwice() public {
        vm.prank(processor1);
        removalNinja.registerProcessor(MIN_PROCESSOR_STAKE, "Processor 1");
        
        address[] memory selectedProcessors = new address[](1);
        selectedProcessors[0] = processor1;
        
        vm.startPrank(alice);
        removalNinja.stakeForRemoval(MIN_USER_STAKE, selectedProcessors);
        
        vm.expectRevert("Already staking for removal");
        removalNinja.stakeForRemoval(MIN_USER_STAKE, selectedProcessors);
        vm.stopPrank();
    }
    
    function test_RevertWhen_StakeForRemovalTooManyProcessors() public {
        // Register 6 processors (more than MAX_SELECTED_PROCESSORS)
        address[] memory processors = new address[](6);
        for (uint i = 0; i < 6; i++) {
            processors[i] = makeAddr(string(abi.encodePacked("processor", i)));
            removalNinja.transfer(processors[i], MIN_PROCESSOR_STAKE);
            vm.prank(processors[i]);
            removalNinja.registerProcessor(MIN_PROCESSOR_STAKE, "description");
        }
        
        vm.prank(alice);
        vm.expectRevert("Too many processors selected");
        removalNinja.stakeForRemoval(MIN_USER_STAKE, processors);
    }
    
    // ============ Removal Request Tests ============
    
    function setupForRemovalRequests() internal {
        // Register processors
        vm.prank(processor1);
        removalNinja.registerProcessor(MIN_PROCESSOR_STAKE, "Processor 1");
        
        // Submit and verify broker
        vm.prank(bob);
        removalNinja.submitDataBroker("TestBroker", "https://test.com", "instructions");
        removalNinja.verifyDataBroker(1);
        
        // User stakes for removal
        vm.startPrank(alice);
        address[] memory selectedProcessors = new address[](1);
        selectedProcessors[0] = processor1;
        removalNinja.stakeForRemoval(MIN_USER_STAKE, selectedProcessors);
        vm.stopPrank();
    }
    
    function test_RequestRemoval() public {
        setupForRemovalRequests();
        
        vm.startPrank(alice);
        
        vm.expectEmit(true, true, true, true);
        emit RemovalRequested(1, alice, 1, processor1);
        
        removalNinja.requestRemoval(1);
        
        // Check removal request
        (
            uint256 id,
            address user,
            uint256 brokerId,
            address processor,
            bool isCompleted,
            bool isVerified,
            uint256 requestTime,
            uint256 completionTime,
            string memory zkProof
        ) = removalNinja.removalRequests(1);
        
        assertEq(id, 1);
        assertEq(user, alice);
        assertEq(brokerId, 1);
        assertEq(processor, processor1);
        assertFalse(isCompleted);
        assertFalse(isVerified);
        assertEq(requestTime, block.timestamp);
        assertEq(completionTime, 0);
        assertEq(zkProof, "");
        
        vm.stopPrank();
    }
    
    function test_RevertWhen_RequestRemovalNotStaking() public {
        vm.prank(processor1);
        removalNinja.registerProcessor(MIN_PROCESSOR_STAKE, "Processor 1");
        
        vm.prank(bob);
        removalNinja.submitDataBroker("TestBroker", "https://test.com", "instructions");
        removalNinja.verifyDataBroker(1);
        
        vm.prank(alice); // Alice hasn't staked
        vm.expectRevert("User not staking for removal");
        removalNinja.requestRemoval(1);
    }
    
    function test_RevertWhen_RequestRemovalInvalidBroker() public {
        setupForRemovalRequests();
        
        vm.prank(alice);
        vm.expectRevert("Invalid broker ID");
        removalNinja.requestRemoval(999);
    }
    
    function test_CompleteRemoval() public {
        setupForRemovalRequests();
        
        // Request removal
        vm.prank(alice);
        removalNinja.requestRemoval(1);
        
        // Complete removal
        vm.startPrank(processor1);
        
        uint256 initialBalance = removalNinja.balanceOf(processor1);
        string memory zkProof = "zkproof_hash_12345";
        
        vm.expectEmit(true, true, false, true);
        emit RemovalCompleted(1, processor1, zkProof);
        
        removalNinja.completeRemoval(1, zkProof);
        
        // Check removal request was completed
        (, , , , bool isCompleted, , , uint256 completionTime, string memory storedProof) = removalNinja.removalRequests(1);
        assertTrue(isCompleted);
        assertEq(completionTime, block.timestamp);
        assertEq(storedProof, zkProof);
        
        // Check processor stats updated
        (, , , , uint256 completedRemovals, , , ) = removalNinja.processors(processor1);
        assertEq(completedRemovals, 1);
        
        // Check broker stats updated
        (, , , , , , , uint256 totalRemovals) = removalNinja.dataBrokers(1);
        assertEq(totalRemovals, 1);
        
        // Check processor was rewarded
        assertEq(removalNinja.balanceOf(processor1), initialBalance + PROCESSING_REWARD);
        
        vm.stopPrank();
    }
    
    function test_RevertWhen_CompleteRemovalNotProcessor() public {
        setupForRemovalRequests();
        
        vm.prank(alice);
        removalNinja.requestRemoval(1);
        
        vm.prank(bob); // Not a processor
        vm.expectRevert("Not a registered processor");
        removalNinja.completeRemoval(1, "proof");
    }
    
    function test_RevertWhen_CompleteRemovalWrongProcessor() public {
        setupForRemovalRequests();
        
        // Register another processor
        vm.prank(processor2);
        removalNinja.registerProcessor(MIN_PROCESSOR_STAKE, "Processor 2");
        
        vm.prank(alice);
        removalNinja.requestRemoval(1);
        
        vm.prank(processor2); // Wrong processor
        vm.expectRevert("Not assigned processor");
        removalNinja.completeRemoval(1, "proof");
    }
    
    function test_RevertWhen_CompleteRemovalAlreadyCompleted() public {
        setupForRemovalRequests();
        
        vm.prank(alice);
        removalNinja.requestRemoval(1);
        
        vm.startPrank(processor1);
        removalNinja.completeRemoval(1, "proof1");
        
        vm.expectRevert("Already completed");
        removalNinja.completeRemoval(1, "proof2");
        vm.stopPrank();
    }
    
    function test_RevertWhen_CompleteRemovalInvalidId() public {
        setupForRemovalRequests();
        
        vm.prank(processor1);
        vm.expectRevert("Invalid removal ID");
        removalNinja.completeRemoval(999, "proof");
    }
    
    // ============ View Function Tests ============
    
    function test_GetStats() public {
        // Submit some data
        vm.prank(alice);
        removalNinja.submitDataBroker("Broker1", "https://broker1.com", "instructions");
        
        vm.prank(processor1);
        removalNinja.registerProcessor(MIN_PROCESSOR_STAKE, "Processor 1");
        
        vm.startPrank(alice);
        address[] memory selectedProcessors = new address[](1);
        selectedProcessors[0] = processor1;
        removalNinja.stakeForRemoval(MIN_USER_STAKE, selectedProcessors);
        vm.stopPrank();
        
        removalNinja.verifyDataBroker(1);
        
        vm.prank(alice);
        removalNinja.requestRemoval(1);
        
        // Check stats
        (uint256 totalBrokers, uint256 totalProcessors, uint256 totalRemovals, uint256 contractBalance) = removalNinja.getStats();
        
        assertEq(totalBrokers, 1);
        assertEq(totalProcessors, 1);
        assertEq(totalRemovals, 1);
        assertEq(contractBalance, MIN_PROCESSOR_STAKE + MIN_USER_STAKE);
    }
    
    function test_GetProcessorReputation() public {
        vm.prank(processor1);
        removalNinja.registerProcessor(MIN_PROCESSOR_STAKE, "Processor 1");
        
        uint256 reputation = removalNinja.getProcessorReputation(processor1);
        assertEq(reputation, 100);
        
        // Slash processor
        removalNinja.slashProcessor(processor1, "Poor performance");
        
        reputation = removalNinja.getProcessorReputation(processor1);
        assertEq(reputation, 0);
    }
    
    function test_RevertWhen_GetReputationNonProcessor() public {
        vm.expectRevert("Not a processor");
        removalNinja.getProcessorReputation(alice);
    }
    
    // ============ Admin Function Tests ============
    
    function test_EmergencyWithdraw() public {
        // Send some tokens to contract
        vm.prank(processor1);
        removalNinja.registerProcessor(MIN_PROCESSOR_STAKE, "Processor 1");
        
        uint256 contractBalance = removalNinja.balanceOf(address(removalNinja));
        uint256 ownerBalanceBefore = removalNinja.balanceOf(owner);
        
        assertTrue(contractBalance > 0);
        
        // Emergency withdraw
        removalNinja.emergencyWithdraw();
        
        assertEq(removalNinja.balanceOf(address(removalNinja)), 0);
        assertEq(removalNinja.balanceOf(owner), ownerBalanceBefore + contractBalance);
    }
    
    function test_RevertWhen_NonOwnerEmergencyWithdraw() public {
        vm.prank(alice);
        vm.expectRevert();
        removalNinja.emergencyWithdraw();
    }
    
    // ============ Fuzzing Tests ============
    
    function testFuzz_SubmitDataBroker(
        string calldata name,
        string calldata website,
        string calldata instructions
    ) public {
        vm.assume(bytes(name).length > 0);
        vm.assume(bytes(website).length > 0);
        vm.assume(bytes(name).length <= 100); // Reasonable limit
        vm.assume(bytes(website).length <= 200); // Reasonable limit
        vm.assume(bytes(instructions).length <= 500); // Reasonable limit
        
        vm.prank(alice);
        removalNinja.submitDataBroker(name, website, instructions);
        
        (uint256 id, string memory storedName, , , address submitter, , , ) = removalNinja.dataBrokers(1);
        assertEq(id, 1);
        assertEq(storedName, name);
        assertEq(submitter, alice);
    }
    
    function testFuzz_ProcessorStake(uint256 stakeAmount) public {
        stakeAmount = bound(stakeAmount, MIN_PROCESSOR_STAKE, 100000 * 10**18);
        
        // Give processor enough tokens
        removalNinja.transfer(processor1, stakeAmount);
        
        vm.prank(processor1);
        removalNinja.registerProcessor(stakeAmount, "Fuzz test processor");
        
        (, , uint256 storedStake, , , , , ) = removalNinja.processors(processor1);
        assertEq(storedStake, stakeAmount);
        assertTrue(removalNinja.isProcessor(processor1));
    }
    
    function testFuzz_UserStake(uint256 stakeAmount) public {
        stakeAmount = bound(stakeAmount, MIN_USER_STAKE, 50000 * 10**18);
        
        // Register processor first
        vm.prank(processor1);
        removalNinja.registerProcessor(MIN_PROCESSOR_STAKE, "Processor 1");
        
        address[] memory selectedProcessors = new address[](1);
        selectedProcessors[0] = processor1;
        
        // Give user enough tokens
        removalNinja.transfer(alice, stakeAmount);
        
        vm.prank(alice);
        removalNinja.stakeForRemoval(stakeAmount, selectedProcessors);
        
        (, uint256 storedStake, ) = removalNinja.users(alice);
        assertEq(storedStake, stakeAmount);
        assertEq(removalNinja.userStakeAmount(alice), stakeAmount);
    }
    
    function testFuzz_MultipleProcessorSelection(uint8 numProcessors) public {
        numProcessors = uint8(bound(numProcessors, 1, 5)); // Max 5 processors
        
        address[] memory processors = new address[](numProcessors);
        for (uint8 i = 0; i < numProcessors; i++) {
            processors[i] = makeAddr(string(abi.encodePacked("processor", i)));
            removalNinja.transfer(processors[i], MIN_PROCESSOR_STAKE);
            vm.prank(processors[i]);
            removalNinja.registerProcessor(MIN_PROCESSOR_STAKE, "description");
        }
        
        vm.prank(alice);
        removalNinja.stakeForRemoval(MIN_USER_STAKE, processors);
        
        address[] memory selectedProcessors = removalNinja.getUserSelectedProcessors(alice);
        assertEq(selectedProcessors.length, numProcessors);
        
        for (uint8 i = 0; i < numProcessors; i++) {
            assertEq(selectedProcessors[i], processors[i]);
        }
    }
    
    function testFuzz_SlashingAmount(uint256 processorStake) public {
        processorStake = bound(processorStake, MIN_PROCESSOR_STAKE, 100000 * 10**18);
        
        // Give processor enough tokens and register
        removalNinja.transfer(processor1, processorStake);
        vm.prank(processor1);
        removalNinja.registerProcessor(processorStake, "Processor to slash");
        
        // Slash processor
        removalNinja.slashProcessor(processor1, "Fuzz test slashing");
        
        // Check slashing amount (10% of stake)
        (, , uint256 remainingStake, , , uint256 reputation, , bool isSlashed) = removalNinja.processors(processor1);
        uint256 expectedSlash = (processorStake * 10) / 100;
        
        assertEq(remainingStake, processorStake - expectedSlash);
        assertEq(reputation, 0);
        assertTrue(isSlashed);
        assertFalse(removalNinja.isProcessor(processor1));
    }
    
    // ============ Integration Tests ============
    
    function test_FullWorkflow() public {
        // 1. Submit and verify data broker
        vm.prank(alice);
        removalNinja.submitDataBroker("TestBroker", "https://testbroker.com", "Email privacy@test.com");
        removalNinja.verifyDataBroker(1);
        
        // 2. Register processors
        vm.prank(processor1);
        removalNinja.registerProcessor(MIN_PROCESSOR_STAKE, "Processor 1");
        
        vm.prank(processor2);
        removalNinja.registerProcessor(MIN_PROCESSOR_STAKE + 500 * 10**18, "Processor 2");
        
        // 3. User stakes for removal
        vm.startPrank(bob);
        address[] memory selectedProcessors = new address[](2);
        selectedProcessors[0] = processor1;
        selectedProcessors[1] = processor2;
        removalNinja.stakeForRemoval(MIN_USER_STAKE * 3, selectedProcessors);
        vm.stopPrank();
        
        // 4. Request removal
        vm.prank(bob);
        removalNinja.requestRemoval(1);
        
        // 5. Complete removal
        vm.prank(processor1);
        removalNinja.completeRemoval(1, "zkproof_hash_complete");
        
        // Verify final state
        (, , , , bool completed, , , , string memory proof) = removalNinja.removalRequests(1);
        assertTrue(completed);
        assertEq(proof, "zkproof_hash_complete");
        
        // Check stats
        (uint256 totalBrokers, uint256 totalProcessors, uint256 totalRemovals, ) = removalNinja.getStats();
        assertEq(totalBrokers, 1);
        assertEq(totalProcessors, 2);
        assertEq(totalRemovals, 1);
    }
    
    function test_MultipleRemovalRequests() public {
        // Setup: register processors and submit brokers
        vm.prank(processor1);
        removalNinja.registerProcessor(MIN_PROCESSOR_STAKE, "Processor 1");
        
        vm.prank(alice);
        removalNinja.submitDataBroker("Broker1", "https://broker1.com", "instructions1");
        removalNinja.verifyDataBroker(1);
        
        vm.prank(bob);
        removalNinja.submitDataBroker("Broker2", "https://broker2.com", "instructions2");
        removalNinja.verifyDataBroker(2);
        
        // User stakes and requests multiple removals
        vm.startPrank(charlie);
        address[] memory selectedProcessors = new address[](1);
        selectedProcessors[0] = processor1;
        removalNinja.stakeForRemoval(MIN_USER_STAKE * 5, selectedProcessors);
        
        removalNinja.requestRemoval(1);
        removalNinja.requestRemoval(2);
        vm.stopPrank();
        
        // Complete both removals
        vm.startPrank(processor1);
        removalNinja.completeRemoval(1, "proof1");
        removalNinja.completeRemoval(2, "proof2");
        vm.stopPrank();
        
        // Verify both completed
        (, , , , bool completed1, , , , ) = removalNinja.removalRequests(1);
        (, , , , bool completed2, , , , ) = removalNinja.removalRequests(2);
        assertTrue(completed1);
        assertTrue(completed2);
        
        // Check processor stats
        (, , , , uint256 completedRemovals, , , ) = removalNinja.processors(processor1);
        assertEq(completedRemovals, 2);
    }
    
    // ============ Edge Case Tests ============
    
    function test_ProcessorStakingAfterSlashing() public {
        // Register processor
        vm.prank(processor1);
        removalNinja.registerProcessor(MIN_PROCESSOR_STAKE, "Processor 1");
        
        // Slash processor
        removalNinja.slashProcessor(processor1, "Poor performance");
        
        // Processor should not be able to complete removals while slashed
        vm.prank(processor2);
        removalNinja.registerProcessor(MIN_PROCESSOR_STAKE, "Processor 2");
        
        vm.prank(alice);
        removalNinja.submitDataBroker("TestBroker", "https://test.com", "instructions");
        removalNinja.verifyDataBroker(1);
        
        vm.startPrank(bob);
        address[] memory selectedProcessors = new address[](1);
        selectedProcessors[0] = processor2; // Use non-slashed processor
        removalNinja.stakeForRemoval(MIN_USER_STAKE, selectedProcessors);
        removalNinja.requestRemoval(1);
        vm.stopPrank();
        
        // Slashed processor should not be able to complete removal
        vm.prank(processor1);
        vm.expectRevert("Processor is slashed");
        removalNinja.completeRemoval(1, "proof");
        
        // Non-slashed processor should be able to complete it
        vm.prank(processor2);
        removalNinja.completeRemoval(1, "proof");
        
        (, , , , bool completed, , , , ) = removalNinja.removalRequests(1);
        assertTrue(completed);
    }
    
    function test_PausedContractBehavior() public {
        // Pause contract
        removalNinja.pause();
        
        // Should not be able to submit broker
        vm.prank(alice);
        vm.expectRevert();
        removalNinja.submitDataBroker("TestBroker", "https://test.com", "instructions");
        
        // Should not be able to register processor
        vm.prank(processor1);
        vm.expectRevert();
        removalNinja.registerProcessor(MIN_PROCESSOR_STAKE, "description");
        
        // Should not be able to stake for removal
        vm.prank(alice);
        address[] memory selectedProcessors = new address[](1);
        selectedProcessors[0] = processor1;
        vm.expectRevert();
        removalNinja.stakeForRemoval(MIN_USER_STAKE, selectedProcessors);
        
        // Unpause and verify functionality returns
        removalNinja.unpause();
        
        vm.prank(alice);
        removalNinja.submitDataBroker("TestBroker", "https://test.com", "instructions");
        
        (, string memory name, , , , , , ) = removalNinja.dataBrokers(1);
        assertEq(name, "TestBroker");
    }
    
    function test_ZeroStakeEdgeCases() public {
        vm.prank(alice);
        vm.expectRevert("Insufficient stake amount");
        removalNinja.stakeForRemoval(0, new address[](0));
        
        vm.prank(processor1);
        vm.expectRevert("Insufficient stake amount");
        removalNinja.registerProcessor(0, "description");
    }
}
