const express = require('express');
const router = express.Router();
const recurringController = require('./recurring.controller');
const authenticateToken = require('../../middleware/auth.middleware');

router.use(authenticateToken);

router.post('/', recurringController.createRecurringRule);
router.get('/', recurringController.getUserRecurringRules);
router.delete('/:id', recurringController.deleteRecurringRule);

module.exports = router;