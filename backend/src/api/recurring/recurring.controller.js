const pool = require('../../config/database');
const { RRule } = require('rrule');

const recurringController = {
  createRecurringRule: async (req, res) => {
    try {
      const {
        category_id,
        amount,
        description,
        recurrence_rule,
        start_date,
        end_date,
      } = req.body;
      const userId = req.user.userId;

      if (!category_id || !amount || !recurrence_rule || !start_date) {
        return res.status(400).json({ message: 'Field wajib tidak boleh kosong.' });
      }

      const rrule = RRule.fromString(`DTSTART:${new Date(start_date).toISOString()}\nRRULE:${recurrence_rule}`);
      const nextRunDate = rrule.after(new Date(new Date(start_date).getTime() - 1)) || new Date(start_date);

      const sql = `
        INSERT INTO recurring_transactions 
        (user_id, category_id, amount, description, recurrence_rule, start_date, next_run_date, end_date) 
        VALUES (?, ?, ?, ?, ?, ?, ?, ?)
      `;
      
      await pool.query(sql, [
        userId,
        category_id,
        amount,
        description,
        recurrence_rule,
        start_date,
        nextRunDate.toISOString().slice(0, 10),
        end_date || null,
      ]);
      
      res.status(201).json({ message: 'Aturan transaksi berulang berhasil dibuat.' });
    } catch (error) {
      console.error('Error creating recurring rule:', error);
      res.status(500).json({ message: 'Server error' });
    }
  },

  getUserRecurringRules: async (req, res) => {
    try {
      const userId = req.user.userId;
      const sql = `
        SELECT rt.*, c.name as category_name, c.type as category_type 
        FROM recurring_transactions rt
        JOIN categories c ON rt.category_id = c.id
        WHERE rt.user_id = ?
        ORDER BY rt.created_at DESC
      `;
      const [rules] = await pool.query(sql, [userId]);
      res.status(200).json(rules);
    } catch (error) {
      console.error('Error fetching recurring rules:', error);
      res.status(500).json({ message: 'Server error' });
    }
  },

  deleteRecurringRule: async (req, res) => {
    try {
      const { id } = req.params;
      const userId = req.user.userId;
      const [result] = await pool.query('DELETE FROM recurring_transactions WHERE id = ? AND user_id = ?', [id, userId]);

      if (result.affectedRows === 0) {
        return res.status(404).json({ message: 'Aturan tidak ditemukan atau Anda tidak punya izin.' });
      }
      
      res.status(200).json({ message: 'Aturan berhasil dihapus.' });
    } catch (error) {
      console.error('Error deleting recurring rule:', error);
      res.status(500).json({ message: 'Server error' });
    }
  },
};

module.exports = recurringController;