const pool = require('../../config/database');
const bcrypt = require('bcryptjs');

const userController = {
  changePassword: async (req, res) => {
    try {
      const userId = req.user.userId;
      const { currentPassword, newPassword } = req.body;

      if (!currentPassword || !newPassword) {
        return res.status(400).json({ message: 'Semua field wajib diisi' });
      }

      if (newPassword.length < 6) {
        return res.status(400).json({ message: 'Password baru minimal 6 karakter' });
      }

      const connection = await pool.getConnection();

      const [rows] = await connection.query('SELECT password_hash FROM users WHERE id = ?', [userId]);
      if (rows.length === 0) {
        connection.release();
        return res.status(404).json({ message: 'User tidak ditemukan' });
      }

      const isMatch = await bcrypt.compare(currentPassword, rows[0].password_hash);
      if (!isMatch) {
        connection.release();
        return res.status(401).json({ message: 'Password lama salah!' });
      }

      const newPasswordHash = await bcrypt.hash(newPassword, 10);
      await connection.query('UPDATE users SET password_hash = ? WHERE id = ?', [newPasswordHash, userId]);
      
      connection.release();
      res.status(200).json({ message: 'Password berhasil diubah' });

    } catch (error) {
      console.error(error);
      res.status(500).json({ message: 'Server error' });
    }
  },

  getUserAchievements: async (req, res) => {
    try {
      const userId = req.user.userId;
      const connection = await pool.getConnection();
      const sql = `
        SELECT 
          a.id, 
          a.name, 
          a.description, 
          a.icon_name, 
          ua.unlocked_at 
        FROM achievements a
        LEFT JOIN user_achievements ua ON a.id = ua.achievement_id AND ua.user_id = ?
        ORDER BY a.id;
      `;
      
      const [achievements] = await connection.query(sql, [userId]);
      connection.release();

      res.status(200).json(achievements);
    } catch (error) {
      console.error(error);
      res.status(500).json({ message: 'Server error' });
    }
  }
};

module.exports = userController;