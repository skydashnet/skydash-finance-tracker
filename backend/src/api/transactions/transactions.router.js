const express = require('express');
const router = express.Router();
const transactionsController = require('./transactions.controller');
const authenticateToken = require('../../middleware/auth.middleware');

router.use(authenticateToken);

router.post('/', transactionsController.createTransaction);
router.get('/', transactionsController.getTransactions);
router.delete('/:id', transactionsController.deleteTransaction);
router.put('/:id', transactionsController.updateTransaction);

module.exports = router;