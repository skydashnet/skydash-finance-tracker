const pool = require('../../config/database');

const transactionsController = {
  createTransaction: async (req, res) => {
    try {
      const { category_id, amount, description, transaction_date } = req.body;
      const userId = req.user.userId;

      if (!category_id || !amount || !transaction_date) {
        return res.status(400).json({ message: 'Category, amount, and date are required' });
      }

      const connection = await pool.getConnection();
      const sql = 'INSERT INTO transactions (user_id, category_id, amount, description, transaction_date) VALUES (?, ?, ?, ?, ?)';
      const [result] = await connection.query(sql, [userId, category_id, amount, description, transaction_date]);
      connection.release();
      const [userTransactions] = await connection.query('SELECT COUNT(*) as count FROM transactions WHERE user_id = ?', [userId]);
        if (userTransactions[0].count === 1) {
          await connection.query('INSERT IGIGNORE INTO user_achievements (user_id, achievement_id) VALUES (?, ?)', [userId, 1]);
        }
      res.status(201).json({
        message: 'Transaction created successfully',
        transactionId: result.insertId
      });
    } catch (error) {
      console.error(error);
      res.status(500).json({ message: 'Server error' });
    }
  },

  getTransactions: async (req, res) => {
    try {
      const userId = req.user.userId;
      
      const connection = await pool.getConnection();
      const sql = `
        SELECT 
          t.id, 
          t.amount, 
          t.description, 
          t.transaction_date, 
          c.name as category_name, 
          c.type as category_type 
        FROM transactions t
        JOIN categories c ON t.category_id = c.id
        WHERE t.user_id = ?
        ORDER BY t.transaction_date DESC, t.id DESC
      `;
      const [transactions] = await connection.query(sql, [userId]);
      connection.release();

      res.status(200).json(transactions);
    } catch (error) {
      console.error(error);
      res.status(500).json({ message: 'Server error' });
    }
  },
  
  deleteTransaction: async (req, res) => {
    try {
        const { id } = req.params;
        const userId = req.user.userId;

        const connection = await pool.getConnection();
        const sql = 'DELETE FROM transactions WHERE id = ? AND user_id = ?';
        const [result] = await connection.query(sql, [id, userId]);
        connection.release();

        if (result.affectedRows === 0) {
            return res.status(404).json({ message: 'Transaction not found or you do not have permission.' });
        }

        res.status(200).json({ message: 'Transaction deleted successfully' });
    } catch (error) {
        console.error(error);
        res.status(500).json({ message: 'Server error' });
    }
  },

  updateTransaction: async (req, res) => {
  try {
    const { id } = req.params;
    const userId = req.user.userId;
    const { category_id, amount, description, transaction_date } = req.body;

    if (!category_id || !amount || !transaction_date) {
      return res.status(400).json({ message: 'All fields are required' });
    }

    const connection = await pool.getConnection();
    const sql = `
      UPDATE transactions 
      SET category_id = ?, amount = ?, description = ?, transaction_date = ? 
      WHERE id = ? AND user_id = ?
    `;
    const [result] = await connection.query(sql, [category_id, amount, description, transaction_date, id, userId]);
    connection.release();

    if (result.affectedRows === 0) {
      return res.status(404).json({ message: 'Transaction not found or you do not have permission' });
    }

    res.status(200).json({ message: 'Transaction updated successfully' });
  } catch (error) {
    console.error(error);
    res.status(500).json({ message: 'Server error' });
  }
}
};



module.exports = transactionsController;