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
    const connection = await pool.getConnection();
    try {
      await connection.beginTransaction();

      const { id } = req.params;
      const { amount } = req.body;
      const userId = req.user.userId;

      if (!amount || amount <= 0) {
        return res.status(400).json({ message: 'Invalid amount' });
      }
      await connection.query('UPDATE goals SET current_amount = current_amount + ? WHERE id = ? AND user_id = ?', [amount, id, userId]);
      const [goalData] = await connection.query('SELECT current_amount, target_amount FROM goals WHERE id = ?', [id]);
      const { current_amount, target_amount } = goalData[0];

      if (parseFloat(current_amount) >= parseFloat(target_amount)) {
        await connection.query('INSERT IGNORE INTO user_achievements (user_id, achievement_id) VALUES (?, ?)', [userId, 8]);
      }
      const [lunasAchievement] = await connection.query('SELECT * FROM achievements WHERE id = 8');
      await connection.commit();
      res.status(200).json({ 
        message: 'Savings added successfully',
        unlockedAchievement: (parseFloat(current_amount) >= parseFloat(target_amount)) ? lunasAchievement[0] : null
      });
    } catch (error) {
      await connection.rollback();
      console.error(error);
      res.status(500).json({ message: 'Server error' });
    } finally {
      if(connection) connection.release();
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