const pool = require('../../config/database');

const budgetController = {
  createOrUpdateBudget: async (req, res) => {
    try {
      const { category_id, amount, period } = req.body;
      const userId = req.user.userId;

      if (!category_id || !amount || !period) {
        return res.status(400).json({ message: 'Field wajib tidak boleh kosong.' });
      }
      const sql = `
        INSERT INTO budgets (user_id, category_id, amount, period)
        VALUES (?, ?, ?, ?)
        ON DUPLICATE KEY UPDATE amount = VALUES(amount)
      `;
      
      await pool.query(sql, [userId, category_id, amount, period]);
      res.status(201).json({ message: 'Budget berhasil disimpan.' });
    } catch (error) {
      console.error('Error creating/updating budget:', error);
      res.status(500).json({ message: 'Server error' });
    }
  },

  getBudgetsForCurrentMonth: async (req, res) => {
    try {
      const userId = req.user.userId;
      const currentPeriod = new Date().toISOString().slice(0, 7);

      const sql = `
        SELECT
          b.id,
          b.amount,
          b.period,
          c.id as category_id,
          c.name as category_name,
          -- Subquery untuk menjumlahkan semua transaksi di kategori & periode ini
          (SELECT COALESCE(SUM(t.amount), 0)
           FROM transactions t
           WHERE t.user_id = b.user_id
             AND t.category_id = b.category_id
             AND DATE_FORMAT(t.transaction_date, '%Y-%m') = b.period
          ) AS spent_amount
        FROM budgets b
        JOIN categories c ON b.category_id = c.id
        WHERE b.user_id = ? AND b.period = ?
        ORDER BY c.name
      `;

      const [budgets] = await pool.query(sql, [userId, currentPeriod]);
      res.status(200).json(budgets);
    } catch (error) {
      console.error('Error fetching budgets:', error);
      res.status(500).json({ message: 'Server error' });
    }
  },

  deleteBudget: async (req, res) => {
    try {
      const { id } = req.params;
      const userId = req.user.userId;

      const [result] = await pool.query('DELETE FROM budgets WHERE id = ? AND user_id = ?', [id, userId]);
      if (result.affectedRows === 0) {
        return res.status(404).json({ message: 'Budget tidak ditemukan.' });
      }
      res.status(200).json({ message: 'Budget berhasil dihapus.' });
    } catch (error) {
      console.error('Error deleting budget:', error);
      res.status(500).json({ message: 'Server error' });
    }
  }
};

module.exports = budgetController;