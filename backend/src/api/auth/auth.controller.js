const pool = require('../../config/database');
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');

const defaultCategories = [
  { name: 'Gaji', type: 'income' },
  { name: 'Bonus', type: 'income' },
  { name: 'Investasi', type: 'income' },
  { name: 'Lainnya', type: 'income' },
  { name: 'Makanan & Minuman', type: 'expense' },
  { name: 'Transportasi', type: 'expense' },
  { name: 'Tagihan', type: 'expense' },
  { name: 'Hiburan', type: 'expense' },
  { name: 'Belanja', type: 'expense' },
  { name: 'Kesehatan', type: 'expense' },
  { name: 'Pendidikan', type: 'expense' },
  { name: 'Keluarga', type: 'expense' },
];

const authController = {
  registerUser: async (req, res) => {
    const connection = await pool.getConnection();
    try {
      await connection.beginTransaction();

      const { username, email, password } = req.body;

      if (!username || !email || !password) {
        return res.status(400).json({ message: 'All fields are required' });
      }
      
      const salt = await bcrypt.genSalt(10);
      const password_hash = await bcrypt.hash(password, salt);
      
      const userSql = 'INSERT INTO users (username, email, password_hash) VALUES (?, ?, ?)';
      const [userResult] = await connection.query(userSql, [username, email, password_hash]);
      const newUserId = userResult.insertId;

      const categorySql = 'INSERT INTO categories (user_id, name, type) VALUES ?';
      const categoryValues = defaultCategories.map(cat => [newUserId, cat.name, cat.type]);
      
      await connection.query(categorySql, [categoryValues]);

      await connection.commit();
      connection.release();

      res.status(201).json({ message: 'User registered successfully' });
    } catch (error) {
      await connection.rollback();
      connection.release();

      console.error(error);
      if (error.code === 'ER_DUP_ENTRY') {
          return res.status(409).json({ message: 'Username or email already exists' });
      }
      res.status(500).json({ message: 'Server error' });
    }
  },

  loginUser: async (req, res) => {
    try {
      const { email, password } = req.body;

      if (!email || !password) {
        return res.status(400).json({ message: 'Email and password are required' });
      }

      const connection = await pool.getConnection();
      const sql = 'SELECT * FROM users WHERE email = ?';
      const [rows] = await connection.query(sql, [email]);
      connection.release();

      if (rows.length === 0) {
        return res.status(401).json({ message: 'Invalid credentials' });
      }

      const user = rows[0];
      const isMatch = await bcrypt.compare(password, user.password_hash);

      if (!isMatch) {
        return res.status(401).json({ message: 'Invalid credentials' });
      }

      const payload = {
        userId: user.id,
        username: user.username
      };

      const token = jwt.sign(
        payload,
        process.env.JWT_SECRET,
        { expiresIn: '30d' }
      );

      res.status(200).json({
        message: 'Login successful',
        token: token
      });

    } catch (error) {
      console.error(error);
      res.status(500).json({ message: 'Server error' });
    }
  }
};

module.exports = authController;