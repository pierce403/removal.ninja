const { expect } = require("chai");

describe("RemovalNinja Contract", function () {
  let RemovalNinja, removalNinja, owner, addr1, addr2;

  beforeEach(async function () {
    // Get the ContractFactory and Signers here.
    RemovalNinja = await ethers.getContractFactory("RemovalNinja");
    [owner, addr1, addr2] = await ethers.getSigners();

    // Deploy the contract
    removalNinja = await RemovalNinja.deploy();
    await removalNinja.waitForDeployment();
  });

  describe("Deployment", function () {
    it("Should set the right owner", async function () {
      expect(await removalNinja.owner()).to.equal(owner.address);
    });

    it("Should mint initial supply to owner", async function () {
      const ownerBalance = await removalNinja.balanceOf(owner.address);
      expect(ownerBalance).to.equal(ethers.parseEther("1000000"));
    });

    it("Should have correct token details", async function () {
      expect(await removalNinja.name()).to.equal("RemovalNinja");
      expect(await removalNinja.symbol()).to.equal("RN");
    });
  });

  describe("Data Broker Submission", function () {
    it("Should allow users to submit data brokers", async function () {
      const tx = await removalNinja.connect(addr1).submitDataBroker(
        "Test Broker",
        "https://testbroker.com",
        "Contact support to remove data"
      );

      await tx.wait();

      const broker = await removalNinja.dataBrokers(1);
      expect(broker.name).to.equal("Test Broker");
      expect(broker.submitter).to.equal(addr1.address);
      expect(broker.verified).to.equal(false);

      // Check if submitter received reward
      const balance = await removalNinja.balanceOf(addr1.address);
      expect(balance).to.equal(ethers.parseEther("100"));
    });

    it("Should not allow empty broker names", async function () {
      await expect(
        removalNinja.connect(addr1).submitDataBroker(
          "",
          "https://testbroker.com",
          "Contact support"
        )
      ).to.be.revertedWith("Name cannot be empty");
    });
  });

  describe("Processor Registration", function () {
    it("Should allow users to register as processors", async function () {
      // First, transfer tokens to addr1
      await removalNinja.transfer(addr1.address, ethers.parseEther("2000"));
      
      // Register as processor
      const tx = await removalNinja.connect(addr1).registerAsProcessor(
        ethers.parseEther("1000"),
        "Trusted processor service"
      );

      await tx.wait();

      const processor = await removalNinja.processors(addr1.address);
      expect(processor.active).to.equal(true);
      expect(processor.stakedAmount).to.equal(ethers.parseEther("1000"));
      expect(processor.description).to.equal("Trusted processor service");

      expect(await removalNinja.isProcessor(addr1.address)).to.equal(true);
    });

    it("Should require minimum stake", async function () {
      await removalNinja.transfer(addr1.address, ethers.parseEther("500"));
      
      await expect(
        removalNinja.connect(addr1).registerAsProcessor(
          ethers.parseEther("500"),
          "Insufficient stake"
        )
      ).to.be.revertedWith("Insufficient stake amount");
    });
  });

  describe("User Staking", function () {
    it("Should allow users to stake for removal list", async function () {
      // Setup: Create a processor first
      await removalNinja.transfer(addr1.address, ethers.parseEther("2000"));
      await removalNinja.connect(addr1).registerAsProcessor(
        ethers.parseEther("1000"),
        "Test processor"
      );

      // Transfer tokens to addr2 for staking
      await removalNinja.transfer(addr2.address, ethers.parseEther("100"));

      // Stake for removal list
      const tx = await removalNinja.connect(addr2).stakeForRemovalList(
        ethers.parseEther("10"),
        [addr1.address]
      );

      await tx.wait();

      const user = await removalNinja.users(addr2.address);
      expect(user.onRemovalList).to.equal(true);
      expect(user.stakedAmount).to.equal(ethers.parseEther("10"));

      const selectedProcessors = await removalNinja.getUserSelectedProcessors(addr2.address);
      expect(selectedProcessors[0]).to.equal(addr1.address);
    });

    it("Should require minimum user stake", async function () {
      await removalNinja.transfer(addr2.address, ethers.parseEther("5"));
      
      await expect(
        removalNinja.connect(addr2).stakeForRemovalList(
          ethers.parseEther("5"),
          [addr1.address]
        )
      ).to.be.revertedWith("Insufficient stake amount");
    });
  });

  describe("Removal Requests", function () {
    beforeEach(async function () {
      // Setup: Create broker, processor, and user
      await removalNinja.connect(addr1).submitDataBroker(
        "Test Broker",
        "https://testbroker.com",
        "Contact support"
      );
      
      await removalNinja.verifyDataBroker(1);

      await removalNinja.transfer(addr1.address, ethers.parseEther("2000"));
      await removalNinja.connect(addr1).registerAsProcessor(
        ethers.parseEther("1000"),
        "Test processor"
      );

      await removalNinja.transfer(addr2.address, ethers.parseEther("100"));
      await removalNinja.connect(addr2).stakeForRemovalList(
        ethers.parseEther("10"),
        [addr1.address]
      );
    });

    it("Should allow users to request removal", async function () {
      const tx = await removalNinja.connect(addr2).requestRemoval(1);
      await tx.wait();

      const request = await removalNinja.removalRequests(1);
      expect(request.brokerId).to.equal(1);
      expect(request.user).to.equal(addr2.address);
      expect(request.completed).to.equal(false);
    });

    it("Should allow processors to complete removals", async function () {
      // Request removal
      await removalNinja.connect(addr2).requestRemoval(1);

      // Process removal
      const tx = await removalNinja.connect(addr1).processRemoval(1);
      await tx.wait();

      const request = await removalNinja.removalRequests(1);
      expect(request.completed).to.equal(true);
      expect(request.processor).to.equal(addr1.address);

      // Check processor received reward
      const balance = await removalNinja.balanceOf(addr1.address);
      expect(balance).to.equal(ethers.parseEther("1050")); // 1000 from transfer + 50 reward
    });
  });
});