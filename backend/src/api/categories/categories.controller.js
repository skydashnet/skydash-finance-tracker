const pool = require('../../config/database');

const categoriesController = {
  createCategory: async (req, res) => {
    try {
      const { name, type } = req.body;
      const userId = req.user.userId;

      if (!name || !type || !['income', 'expense'].includes(type)) {
        return res.status(400).json({ message: 'Invalid name or type provided.' });
      }

      const connection = await pool.getConnection();
      const sql = 'INSERT INTO categories (user_id, name, type) VALUES (?, ?, ?)';
      const [result] = await connection.query(sql, [userId, name, type]);
      connection.release();

      res.status(201).json({ 
        message: 'Category created successfully',
        categoryId: result.insertId 
      });
    } catch (error) {
      console.error(error);
      res.status(500).json({ message: 'Server error' });
    }
  },

  getCategoriesByUser: async (req, res) => {
    try {
      const userId = req.user.userId;
      
      const connection = await pool.getConnection();
      const sql = 'SELECT id, name, type FROM categories WHERE user_id = ?';
      const [categories] = await connection.query(sql, [userId]);
      connection.release();

      res.status(200).json(categories);
    } catch (error) {
      console.error(error);
      res.status(500).json({ message: 'Server error' });
    }
  },

  updateCategory: async (req, res) => {
    try {
      const { id } = req.params;
      const { name, type } = req.body;
      const userId = req.user.userId;

      if (!name || !type || !['income', 'expense'].includes(type)) {
        return res.status(400).json({ message: 'Invalid name or type' });
      }

      const connection = await pool.getConnection();
      const sql = 'UPDATE categories SET name = ?, type = ? WHERE id = ? AND user_id = ?';
      const [result] = await connection.query(sql, [name, type, id, userId]);
      connection.release();

      if (result.affectedRows === 0) {
        return res.status(404).json({ message: 'Category not found or you do not have permission' });
      }

      res.status(200).json({ message: 'Category updated successfully' });
    } catch (error) {
      console.error(error);
      res.status(500).json({ message: 'Server error' });
    }
  },

  deleteCategory: async (req, res) => {
    try {
      const { id } = req.params;
      const userId = req.user.userId;

      const connection = await pool.getConnection();
      const sql = 'DELETE FROM categories WHERE id = ? AND user_id = ?';
      const [result] = await connection.query(sql, [id, userId]);
      connection.release();

      if (result.affectedRows === 0) {
        return res.status(404).json({ message: 'Category not found or you do not have permission to delete it.' });
      }

      res.status(200).json({ message: 'Category deleted successfully' });
    } catch (error) {
      console.error(error);
      if (error.code === 'ER_ROW_IS_REFERENCED_2') {
        return res.status(409).json({ message: 'Cannot delete category because it is being used by one or more transactions.' });
      }
      res.status(500).json({ message: 'Server error' });
    }
  }
};

module.exports = categoriesController;