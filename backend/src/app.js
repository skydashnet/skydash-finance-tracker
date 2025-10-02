require('dotenv').config();
const express = require('express');
const cors = require('cors');

const authRouter = require('./api/auth/auth.router');
const userRouter = require('./api/users/user.router');
const transactionRouter = require('./api/transactions/transactions.router');
const categoryRouter = require('./api/categories/categories.router');
const reportRouter = require('./api/reports/reports.router');
const goalRouter = require('./api/goals/goals.router');
const recurringRouter = require('./api/recurring/recurring.router');

const app = express();
require('./cron');
app.use(cors());
app.use(express.json());

app.get('/api', (req, res) => {
  res.json({ message: 'Skydash.NET Financial Tracker API is running! 🚀' });
});

app.use('/api/auth', authRouter);
app.use('/api/users', userRouter);
app.use('/api/transactions', transactionRouter);
app.use('/api/categories', categoryRouter);
app.use('/api/reports', reportRouter);
app.use('/api/goals', goalRouter);
app.use('/api/recurring', recurringRouter);

const PORT = process.env.PORT;
app.listen(PORT, () => {
  console.log(`Server is running on port ${PORT}`);
});