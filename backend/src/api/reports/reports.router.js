const express = require('express');
const router = express.Router();
const reportsController = require('./reports.controller');
const authenticateToken = require('../../middleware/auth.middleware');

router.use(authenticateToken);

router.get('/summary', reportsController.getSummary);

module.exports = router;