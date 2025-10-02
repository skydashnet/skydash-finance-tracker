const cron = require('node-cron');
const { RRule } = require('rrule');
const pool = require('./config/database');

const processRecurringTransactions = async () => {
  console.log('[CRON] Running job: Processing recurring transactions...');
  const connection = await pool.getConnection();
  try {
    const today = new Date().toISOString().slice(0, 10);
    const [rulesToRun] = await connection.query(
      'SELECT * FROM recurring_transactions WHERE is_active = TRUE AND next_run_date <= ?',
      [today]
    );

    if (rulesToRun.length === 0) {
      console.log('[CRON] No transactions to process today.');
      return;
    }

    for (const rule of rulesToRun) {
      await connection.beginTransaction();
      await connection.query(
        'INSERT INTO transactions (user_id, category_id, amount, description, transaction_date) VALUES (?, ?, ?, ?, ?)',
        [rule.user_id, rule.category_id, rule.amount, rule.description, rule.next_run_date]
      );
      const rrule = RRule.fromString(`DTSTART:${rule.start_date.toISOString()}\nRRULE:${rule.recurrence_rule}`);
      const nextRun = rrule.after(new Date(rule.next_run_date));

      if (nextRun && (!rule.end_date || nextRun <= new Date(rule.end_date))) {
        await connection.query(
          'UPDATE recurring_transactions SET next_run_date = ? WHERE id = ?',
          [nextRun.toISOString().slice(0, 10), rule.id]
        );
      } else {
        await connection.query('UPDATE recurring_transactions SET is_active = FALSE WHERE id = ?', [rule.id]);
      }

      await connection.commit();
      console.log(`[CRON] Processed recurring transaction ID: ${rule.id}`);
    }

  } catch (error) {
    await connection.rollback();
    console.error('[CRON] Error processing recurring transactions:', error);
  } finally {
    if (connection) connection.release();
  }
};

cron.schedule('0 2 * * *', processRecurringTransactions, {
  scheduled: true,
  timezone: "Asia/Jakarta"
});

console.log('[CRON] Recurring transaction scheduler is running.');