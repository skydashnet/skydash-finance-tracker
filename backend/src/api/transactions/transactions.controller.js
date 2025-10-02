const pool = require('../../config/database');
const { Parser } = require('json2csv');

const awardAchievement = async (connection, userId, achievementId) => {
  await connection.query('INSERT IGNORE INTO user_achievements (user_id, achievement_id) VALUES (?, ?)', [userId, 1]);
  
  const [achievementCount] = await connection.query('SELECT COUNT(*) as count FROM user_achievements WHERE user_id = ?', [userId]);
  if (achievementCount[0].count >= 5) {
    await connection.query('INSERT IGNORE INTO user_achievements (user_id, achievement_id) VALUES (?, ?)', [userId, 9]);
  }
};

const transactionsController = {
  createTransaction: async (req, res) => {
    const connection = await pool.getConnection();
    try {
      await connection.beginTransaction();

      const { category_id, amount, description, transaction_date } = req.body;
      const userId = req.user.userId;

      const sql = 'INSERT INTO transactions (user_id, category_id, amount, description, transaction_date) VALUES (?, ?, ?, ?, ?)';
      await connection.query(sql, [userId, category_id, amount, description, transaction_date]);
      
      const [userTransactions] = await connection.query('SELECT COUNT(*) as count FROM transactions WHERE user_id = ?', [userId]);
      if (userTransactions[0].count === 1) {
        await awardAchievement(connection, userId, 1);
      }

      const transactionHour = new Date().getHours();
      if (transactionHour >= 0 && transactionHour < 4) {
        await awardAchievement(connection, userId, 10);
      } else if (transactionHour >= 4 && transactionHour < 6) {
        await awardAchievement(connection, userId, 11);
      }
      
      const [userData] = await connection.query('SELECT last_transaction_date, current_streak FROM users WHERE id = ?', [userId]);
      const { last_transaction_date, current_streak } = userData[0];
      const today = new Date(transaction_date);
      let newStreak = current_streak;

      if (last_transaction_date) {
        const lastDate = new Date(last_transaction_date);
        const diffTime = today - lastDate;
        const diffDays = Math.ceil(diffTime / (1000 * 60 * 60 * 24));

        if (diffDays === 1) {
          newStreak++;
        } else if (diffDays > 1) {
          newStreak = 1;
        }
      } else {
        newStreak = 1;
      }
      
      await connection.query('UPDATE users SET last_transaction_date = ?, current_streak = ? WHERE id = ?', [transaction_date, newStreak, userId]);
      
      if (newStreak >= 3) await awardAchievement(connection, userId, 4);
      if (newStreak >= 7) await awardAchievement(connection, userId, 5);
      if (newStreak >= 30) await awardAchievement(connection, userId, 6);
      if (newStreak >= 100) await awardAchievement(connection, userId, 7);

      const [newAchievements] = await connection.query(
        `SELECT a.name, a.description, a.icon_name 
        FROM achievements a 
        JOIN user_achievements ua ON a.id = ua.achievement_id 
        WHERE ua.user_id = ? AND ua.unlocked_at > NOW() - INTERVAL 5 SECOND`, 
        [userId]
      );
      
      await connection.commit();
      
      res.status(201).json({ 
        message: 'Transaction created successfully',
        unlockedAchievement: newAchievements.length > 0 ? newAchievements[0] : null,
      });

    } catch (error) {
      await connection.rollback();
      console.error(error);
      res.status(500).json({ message: 'Server error' });
    } finally {
      if (connection) connection.release();
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
},
exportTransactions: async (req, res) => {
    try {
      const userId = req.user.userId;
      const { year, month } = req.query;

      if (!year || !month) {
        return res.status(400).json({ message: 'Tahun dan bulan wajib disertakan.' });
      }

      const sql = `
        SELECT 
          t.transaction_date as Tanggal, 
          c.name as Kategori,
          c.type as Tipe,
          t.amount as Jumlah,
          t.description as Deskripsi
        FROM transactions t
        JOIN categories c ON t.category_id = c.id
        WHERE t.user_id = ? AND YEAR(t.transaction_date) = ? AND MONTH(t.transaction_date) = ?
        ORDER BY t.transaction_date ASC
      `;
      const [transactions] = await pool.query(sql, [userId, year, month]);

      if (transactions.length === 0) {
        return res.status(404).json({ message: 'Tidak ada data transaksi untuk periode ini.' });
      }
      const json2csvParser = new Parser();
      const csv = json2csvParser.parse(transactions);
      const fileName = `laporan-transaksi-${year}-${month}.csv`;
      res.header('Content-Type', 'text/csv');
      res.attachment(fileName);
      res.status(200).send(csv);

    } catch (error) {
      console.error('Error exporting transactions:', error);
      res.status(500).json({ message: 'Server error' });
    }
  }
};



module.exports = transactionsController;