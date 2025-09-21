const express = require('express');
const router = express.Router();

// Get user information
router.get('/:address', async (req, res) => {
  try {
    // Redirect to blockchain route for user info
    res.redirect(`/api/blockchain/user/${req.params.address}`);
  } catch (error) {
    console.error('Error getting user:', error);
    res.status(500).json({ error: 'Failed to get user' });
  }
});

// Stake for removal list (requires blockchain transaction)
router.post('/stake', async (req, res) => {
  try {
    const { address, stakeAmount, selectedProcessors } = req.body;
    
    if (!address || !stakeAmount || !selectedProcessors || selectedProcessors.length === 0) {
      return res.status(400).json({ error: 'Missing required fields' });
    }

    res.json({
      message: 'Use the blockchain contract to stake for removal list',
      contractMethod: 'stakeForRemovalList',
      parameters: { stakeAmount, selectedProcessors },
      minimumStake: '10 RN tokens'
    });
  } catch (error) {
    console.error('Error staking for removal list:', error);
    res.status(500).json({ error: 'Failed to stake for removal list' });
  }
});

module.exports = router;