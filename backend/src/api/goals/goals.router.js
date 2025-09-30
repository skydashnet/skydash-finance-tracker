const express = require('express');
const router = express.Router();
const goalsController = require('./goals.controller');
const authenticateToken = require('../../middleware/auth.middleware');

router.use(authenticateToken);

router.post('/', goalsController.createGoal);
router.get('/', goalsController.getUserGoals);
router.put('/:id/add-savings', goalsController.addSavings);
router.delete('/:id', goalsController.deleteGoal);

module.exports = router;