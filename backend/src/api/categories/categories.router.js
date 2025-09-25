const express = require('express');
const router = express.Router();
const categoriesController = require('./categories.controller');
const authenticateToken = require('../../middleware/auth.middleware');

router.use(authenticateToken);

router.post('/', categoriesController.createCategory);
router.get('/', categoriesController.getCategoriesByUser);
router.delete('/:id', categoriesController.deleteCategory);
router.put('/:id', categoriesController.updateCategory);

module.exports = router;