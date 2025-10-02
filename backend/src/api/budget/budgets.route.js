const express = require('express');
const router = express.Router();
const budgetController = require('./budgets.controller');
const authenticateToken = require('../../middleware/auth.middleware');

router.use(authenticateToken);

router.post('/', budgetController.createOrUpdateBudget);
router.get('/', budgetController.getBudgetsForCurrentMonth);
router.delete('/:id', budgetController.deleteBudget);

module.exports = router;