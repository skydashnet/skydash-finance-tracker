const pool = require('../../config/database');
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');

const defaultCategories = [
  { name: 'Gaji', type: 'income' },
  { name: 'Bonus', type: 'income' },
  { name: 'Investasi', type: 'income' },
  { name: 'Hadiah', type: 'income' },
  { name: 'Lainnya', type: 'income' },
  { name: 'Makan Siang', type: 'expense' },
  { name: 'Kopi', type: 'expense' },
  { name: 'Restoran', type: 'expense' },
  { name: 'Snack', type: 'expense' },
  { name: 'Supermarket', type: 'expense' },
  { name: 'Kebutuhan Rumah', type: 'expense' },
  { name: 'Minimarket', type: 'expense' },
  { name: 'BBM', type: 'expense' },
  { name: 'Parkir', type: 'expense' },
  { name: 'Tol', type: 'expense' },
  { name: 'Ojek Online', type: 'expense' },
  { name: 'Tiket Transportasi', type: 'expense' },
  { name: 'Nonton Film', type: 'expense' },
  { name: 'Game', type: 'expense' },
  { name: 'Musik', type: 'expense' },
  { name: 'Langganan Streaming', type: 'expense' },
  { name: 'Obat', type: 'expense' },
  { name: 'Dokter', type: 'expense' },
  { name: 'Vitamin', type: 'expense' },
  { name: 'Asuransi Kesehatan', type: 'expense' },
  { name: 'Buku', type: 'expense' },
  { name: 'Kursus', type: 'expense' },
  { name: 'Sekolah/Kuliah', type: 'expense' },
  { name: 'Listrik', type: 'expense' },
  { name: 'Air', type: 'expense' },
  { name: 'Internet', type: 'expense' },
  { name: 'Pulsa/Paket Data', type: 'expense' },
  { name: 'Pakaian', type: 'expense' },
  { name: 'Aksesoris', type: 'expense' },
  { name: 'Skincare', type: 'expense' },
  { name: 'Donasi', type: 'expense' },
  { name: 'Hadiah Ulang Tahun', type: 'expense' },
  { name: 'Sumbangan', type: 'expense' },
  { name: 'Pengeluaran Lain', type: 'expense' },
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