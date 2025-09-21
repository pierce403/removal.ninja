const express = require('express');
const { ethers } = require('ethers');
const router = express.Router();

// Import contract ABI and address
let contractABI;
try {
  contractABI = require('../../contracts/artifacts/contracts/RemovalNinja.sol/RemovalNinja.json').abi;
} catch (error) {
  console.warn('Contract artifacts not found. Compile contracts first.');
  contractABI = [];
}

let contractAddress;
try {
  contractAddress = require('../contract-address.json').contractAddress;
} catch (error) {
  console.warn('Contract address not found. Deploy contracts first.');
}

// Provider setup
const provider = new ethers.JsonRpcProvider(process.env.RPC_URL || 'http://localhost:8545');

// Get contract instance
router.get('/contract-info', (req, res) => {
  res.json({
    contractAddress,
    rpcUrl: process.env.RPC_URL || 'http://localhost:8545',
    hasContract: !!contractAddress
  });
});

// Get token balance for address
router.get('/balance/:address', async (req, res) => {
  try {
    if (!contractAddress) {
      return res.status(400).json({ error: 'Contract not deployed' });
    }

    const contract = new ethers.Contract(contractAddress, contractABI, provider);
    const balance = await contract.balanceOf(req.params.address);
    
    res.json({
      address: req.params.address,
      balance: ethers.formatEther(balance),
      balanceWei: balance.toString()
    });
  } catch (error) {
    console.error('Error getting balance:', error);
    res.status(500).json({ error: 'Failed to get balance' });
  }
});

// Get contract stats
router.get('/stats', async (req, res) => {
  try {
    if (!contractAddress) {
      return res.status(400).json({ error: 'Contract not deployed' });
    }

    const contract = new ethers.Contract(contractAddress, contractABI, provider);
    
    const totalSupply = await contract.totalSupply();
    const nextBrokerId = await contract.nextBrokerId();
    const nextRequestId = await contract.nextRequestId();
    
    res.json({
      totalSupply: ethers.formatEther(totalSupply),
      totalBrokers: (nextBrokerId - 1n).toString(),
      totalRequests: (nextRequestId - 1n).toString(),
      contractAddress
    });
  } catch (error) {
    console.error('Error getting stats:', error);
    res.status(500).json({ error: 'Failed to get contract stats' });
  }
});

// Get all data brokers
router.get('/brokers', async (req, res) => {
  try {
    if (!contractAddress) {
      return res.status(400).json({ error: 'Contract not deployed' });
    }

    const contract = new ethers.Contract(contractAddress, contractABI, provider);
    const activeBrokerIds = await contract.getActiveBrokers();
    
    const brokers = [];
    for (const id of activeBrokerIds) {
      const broker = await contract.dataBrokers(id);
      brokers.push({
        id: broker.id.toString(),
        name: broker.name,
        website: broker.website,
        removalInstructions: broker.removalInstructions,
        submitter: broker.submitter,
        verified: broker.verified,
        timestamp: new Date(Number(broker.timestamp) * 1000).toISOString()
      });
    }
    
    res.json(brokers);
  } catch (error) {
    console.error('Error getting brokers:', error);
    res.status(500).json({ error: 'Failed to get brokers' });
  }
});

// Get processor info
router.get('/processor/:address', async (req, res) => {
  try {
    if (!contractAddress) {
      return res.status(400).json({ error: 'Contract not deployed' });
    }

    const contract = new ethers.Contract(contractAddress, contractABI, provider);
    const processor = await contract.processors(req.params.address);
    const isProcessor = await contract.isProcessor(req.params.address);
    
    if (!isProcessor) {
      return res.json({ isProcessor: false });
    }
    
    res.json({
      address: processor.addr,
      stakedAmount: ethers.formatEther(processor.stakedAmount),
      active: processor.active,
      completedRequests: processor.completedRequests.toString(),
      slashedAmount: ethers.formatEther(processor.slashedAmount),
      description: processor.description,
      isProcessor: true
    });
  } catch (error) {
    console.error('Error getting processor:', error);
    res.status(500).json({ error: 'Failed to get processor info' });
  }
});

// Get user info
router.get('/user/:address', async (req, res) => {
  try {
    if (!contractAddress) {
      return res.status(400).json({ error: 'Contract not deployed' });
    }

    const contract = new ethers.Contract(contractAddress, contractABI, provider);
    const user = await contract.users(req.params.address);
    const selectedProcessors = await contract.getUserSelectedProcessors(req.params.address);
    
    res.json({
      address: user.addr,
      stakedAmount: ethers.formatEther(user.stakedAmount),
      onRemovalList: user.onRemovalList,
      selectedProcessors: selectedProcessors
    });
  } catch (error) {
    console.error('Error getting user:', error);
    res.status(500).json({ error: 'Failed to get user info' });
  }
});

module.exports = router;