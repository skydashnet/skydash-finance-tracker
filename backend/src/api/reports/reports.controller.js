const pool = require('../../config/database');

const reportsController = {
  getSummary: async (req, res) => {
    try {
      const userId = req.user.userId;
      const { period, year, month } = req.query;

      let startDate, endDate;

      if (period === 'monthly' && year && month) {
        const monthIndex = parseInt(month) - 1;
        startDate = new Date(year, monthIndex, 1);
        endDate = new Date(year, monthIndex + 1, 0); 
      } else {
        const now = new Date();
        startDate = new Date(now.getFullYear(), now.getMonth(), 1);
        endDate = new Date(now.getFullYear(), now.getMonth() + 1, 0);
      }

      const formattedStartDate = startDate.toISOString().split('T')[0];
      const formattedEndDate = endDate.toISOString().split('T')[0];

      const connection = await pool.getConnection();
      const sql = `
        SELECT
          COALESCE(SUM(CASE WHEN c.type = 'income' THEN t.amount ELSE 0 END), 0) AS total_income,
          COALESCE(SUM(CASE WHEN c.type = 'expense' THEN t.amount ELSE 0 END), 0) AS total_expense
        FROM transactions t
        JOIN categories c ON t.category_id = c.id
        WHERE t.user_id = ? AND t.transaction_date BETWEEN ? AND ?
      `;
      
      const [rows] = await connection.query(sql, [userId, formattedStartDate, formattedEndDate]);
      connection.release();

      const summary = {
        total_income: parseFloat(rows[0].total_income),
        total_expense: parseFloat(rows[0].total_expense),
        balance: parseFloat(rows[0].total_income) - parseFloat(rows[0].total_expense)
      };

      res.status(200).json({
        period: {
          start: formattedStartDate,
          end: formattedEndDate
        },
        summary: summary
      });

    } catch (error) {
      console.error(error);
      res.status(500).json({ message: 'Server error' });
    }
  }
};

module.exports = reportsController;