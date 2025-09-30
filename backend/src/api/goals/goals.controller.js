const pool = require('../../config/database');

const goalsController = {
  createGoal: async (req, res) => {
    try {
      const { name, target_amount, image_url } = req.body;
      const userId = req.user.userId;
      const sql = 'INSERT INTO goals (user_id, name, target_amount, image_url) VALUES (?, ?, ?, ?)';
      await pool.query(sql, [userId, name, target_amount, image_url]);
      res.status(201).json({ message: 'Goal created successfully' });
    } catch (error) {
      res.status(500).json({ message: 'Server error' });
    }
  },

  getUserGoals: async (req, res) => {
    try {
      const userId = req.user.userId;
      const [goals] = await pool.query('SELECT * FROM goals WHERE user_id = ? ORDER BY created_at DESC', [userId]);
      res.status(200).json(goals);
    } catch (error) {
      res.status(500).json({ message: 'Server error' });
    }
  },
  
  addSavings: async (req, res) => {
    try {
      const { id } = req.params;
      const { amount } = req.body;
      const userId = req.user.userId;

      if (!amount || amount <= 0) {
        return res.status(400).json({ message: 'Invalid amount' });
      }

      const sql = 'UPDATE goals SET current_amount = current_amount + ? WHERE id = ? AND user_id = ?';
      const [result] = await pool.query(sql, [amount, id, userId]);

      if (result.affectedRows === 0) {
        return res.status(404).json({ message: 'Goal not found' });
      }
      res.status(200).json({ message: 'Savings added successfully' });
    } catch (error) {
      res.status(500).json({ message: 'Server error' });
    }
  },

  deleteGoal: async (req, res) => {
    try {
      const { id } = req.params;
      const userId = req.user.userId;
      const [result] = await pool.query('DELETE FROM goals WHERE id = ? AND user_id = ?', [id, userId]);
      if (result.affectedRows === 0) {
        return res.status(404).json({ message: 'Goal not found' });
      }
      res.status(200).json({ message: 'Goal deleted successfully' });
    } catch (error) {
      res.status(500).json({ message: 'Server error' });
    }
  },
};

module.exports = goalsController;