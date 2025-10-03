import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:skydash_financial_tracker/src/constants/app_colors.dart';
import 'package:skydash_financial_tracker/src/providers/transaction_provider.dart';
import 'package:skydash_financial_tracker/src/utils/category_icon_mapper.dart';
import 'package:skydash_financial_tracker/src/features/budget/budget_screen.dart';
import 'package:skydash_financial_tracker/src/features/goals/goals_screen.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  String _formatCurrency(num amount, {bool compact = false}) {
    if (compact) {
      return NumberFormat.compactCurrency(locale: 'id_ID', symbol: 'Rp', decimalDigits: 1).format(amount);
    }
    final format = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
    return format.format(amount);
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<TransactionProvider>(
      builder: (context, provider, child) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Dashboard'),
            actions: [
              // IconButton(
              //   icon: const Icon(Icons.logout),
              //   onPressed: () {
              //   },
              // ),
            ],
          ),
          body: RefreshIndicator(
            onRefresh: () => provider.fetchTransactionsAndSummary(),
            child: _buildBody(context, provider),
          ),
        );
      },
    );
  }

  Widget _buildBody(BuildContext context, TransactionProvider provider) {
    if (provider.isLoading && provider.summary == null) {
      return const Center(child: CircularProgressIndicator());
    }
    if (provider.error != null) {
      return Center(child: Text(provider.error!));
    }
    if (provider.summary == null) {
      return const Center(child: Text('Data tidak tersedia.'));
    }

    final summary = provider.summary!;
    final recentTransactions = provider.transactions.take(5).toList();

    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        _buildSummaryCard(
          title: 'Total Pemasukan',
          amount: summary['total_income'],
          color: Colors.green,
          icon: Icons.arrow_downward,
        ),
        const SizedBox(height: 16),
        _buildSummaryCard(
          title: 'Total Pengeluaran',
          amount: summary['total_expense'],
          color: Colors.red,
          icon: Icons.arrow_upward,
        ),
        const SizedBox(height: 16),
        _buildSummaryCard(
          title: 'Saldo Saat Ini',
          amount: summary['balance'],
          color: Theme.of(context).colorScheme.primary,
          icon: Icons.account_balance_wallet,
        ),
        const SizedBox(height: 32),
        Text('Pengeluaran 7 Hari Terakhir', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 16),
        SizedBox(
          height: 150,
          child: _buildWeeklyChart(context, provider.weeklyExpensesData),
        ),

        const SizedBox(height: 32),
        Text('Transaksi Terakhir', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 8),
        if (recentTransactions.isEmpty)
          const Padding(
            padding: EdgeInsets.only(top: 16.0),
            child: Text('Belum ada transaksi.'),
          )
        else
          ...recentTransactions.map((trx) => _buildRecentTransactionTile(trx)),
        const SizedBox(height: 16),
        Card(
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => const BudgetScreen()));
            },
            child: const ListTile(
              leading: Icon(Icons.wallet_outlined),
              title: Text('Anggaran Bulanan', style: TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text('Kelola batas pengeluaranmu'),
              trailing: Icon(Icons.chevron_right),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Card(
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => const GoalsScreen()));
            },
            child: const ListTile(
              leading: Icon(Icons.flag_outlined),
              title: Text('Target Tabungan', style: TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text('Lihat progres impianmu'),
              trailing: Icon(Icons.chevron_right),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRecentTransactionTile(Map<String, dynamic> trx) {
    final isExpense = trx['category_type'] == 'expense';
    final visual = CategoryIconMapper.getVisual(trx['category_name']);
    final amount = num.parse(trx['amount'].toString());

    return Card(
      margin: const EdgeInsets.only(top: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: visual.color.withOpacity(0.15),
          child: Icon(visual.icon, color: visual.color, size: 20),
        ),
        title: Text(trx['category_name']),
        trailing: Text(
          '${isExpense ? '-' : '+'} ${_formatCurrency(amount)}',
          style: TextStyle(
            color: isExpense ? Colors.red : Colors.green,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildWeeklyChart(BuildContext context, Map<int, double> weeklyData) {
    final dayLabels = ['Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab', 'Min'];
    final maxValue = weeklyData.values.fold(0.0, (max, v) => v > max ? v : max) * 1.2;

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: maxValue == 0 ? 10000 : maxValue,
        barTouchData: BarTouchData(
          touchTooltipData: BarTouchTooltipData(
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              return BarTooltipItem(
                _formatCurrency(rod.toY),
                TextStyle(color: Theme.of(context).colorScheme.onPrimary),
              );
            },
          ),
        ),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (double value, TitleMeta meta) {
                return SideTitleWidget(
                  axisSide: meta.axisSide,
                  child: Text(dayLabels[value.toInt() - 1], style: const TextStyle(fontSize: 10)),
                );
              },
              reservedSize: 24,
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        gridData: FlGridData(show: false),
        barGroups: weeklyData.entries.map((entry) {
          return BarChartGroupData(
            x: entry.key,
            barRods: [
              BarChartRodData(
                toY: entry.value,
                color: Theme.of(context).colorScheme.primary,
                width: 15,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(4),
                  topRight: Radius.circular(4),
                ),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildSummaryCard({
    required String title,
    required num amount,
    required Color color,
    required IconData icon,
  }) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 18,
                    color: AppColors.textSecondary,
                  ),
                ),
                Icon(icon, color: color),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              _formatCurrency(amount),
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
