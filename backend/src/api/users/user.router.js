const express = require('express');
const router = express.Router();
const userController = require('./user.controller');
const authenticateToken = require('../../middleware/auth.middleware');

router.use(authenticateToken);

router.put('/change-password', userController.changePassword);
router.get('/achievements', userController.getUserAchievements);

module.exports = router;