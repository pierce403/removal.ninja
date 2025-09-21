const express = require('express');
const router = express.Router();

// Get processor information
router.get('/:address', async (req, res) => {
  try {
    // Redirect to blockchain route for processor info
    res.redirect(`/api/blockchain/processor/${req.params.address}`);
  } catch (error) {
    console.error('Error getting processor:', error);
    res.status(500).json({ error: 'Failed to get processor' });
  }
});

// Register as processor (requires blockchain transaction)
router.post('/register', async (req, res) => {
  try {
    const { address, stakeAmount, description } = req.body;
    
    if (!address || !stakeAmount || !description) {
      return res.status(400).json({ error: 'Missing required fields' });
    }

    // Return transaction data for frontend
    res.json({
      message: 'Use the blockchain contract to register as processor',
      contractMethod: 'registerAsProcessor',
      parameters: { stakeAmount, description },
      minimumStake: '1000 RN tokens'
    });
  } catch (error) {
    console.error('Error registering processor:', error);
    res.status(500).json({ error: 'Failed to register processor' });
  }
});

// Process a removal request (requires blockchain transaction)
router.post('/:requestId/process', async (req, res) => {
  try {
    const { requestId } = req.params;
    const { processorAddress } = req.body;
    
    if (!processorAddress) {
      return res.status(400).json({ error: 'Processor address required' });
    }

    res.json({
      message: 'Use the blockchain contract to process removal',
      contractMethod: 'processRemoval',
      parameters: { requestId },
      reward: '50 RN tokens'
    });
  } catch (error) {
    console.error('Error processing removal:', error);
    res.status(500).json({ error: 'Failed to process removal' });
  }
});

module.exports = router;