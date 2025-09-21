const express = require('express');
const router = express.Router();

// Get all data brokers (from blockchain)
router.get('/', async (req, res) => {
  try {
    // This will fetch from blockchain via the blockchain route
    res.redirect('/api/blockchain/brokers');
  } catch (error) {
    console.error('Error getting brokers:', error);
    res.status(500).json({ error: 'Failed to get brokers' });
  }
});

// Get specific broker details
router.get('/:id', async (req, res) => {
  try {
    const brokerId = req.params.id;
    // Implementation would fetch specific broker from blockchain
    res.json({ message: `Broker ${brokerId} details would be fetched from blockchain` });
  } catch (error) {
    console.error('Error getting broker:', error);
    res.status(500).json({ error: 'Failed to get broker' });
  }
});

// Submit new data broker (requires blockchain transaction)
router.post('/submit', async (req, res) => {
  try {
    const { name, website, removalInstructions, userAddress } = req.body;
    
    if (!name || !website || !userAddress) {
      return res.status(400).json({ error: 'Missing required fields' });
    }

    // Return transaction data that frontend can use
    res.json({
      message: 'Use the blockchain contract to submit this broker',
      contractMethod: 'submitDataBroker',
      parameters: { name, website, removalInstructions },
      reward: '100 RN tokens'
    });
  } catch (error) {
    console.error('Error submitting broker:', error);
    res.status(500).json({ error: 'Failed to submit broker' });
  }
});

module.exports = router;