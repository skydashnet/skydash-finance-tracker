import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:skydash_financial_tracker/src/constants/app_colors.dart';
import 'package:skydash_financial_tracker/src/providers/transaction_provider.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  String _formatCurrency(num amount) {
    final format = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );
    return format.format(amount);
  }

  @override
  Widget build(BuildContext context) {
    // 'Dengarkan' perubahan dari TransactionProvider
    return Consumer<TransactionProvider>(
      builder: (context, provider, child) {
        return Scaffold(
          appBar: AppBar(title: const Text('Dashboard')),
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
          color: AppColors.primary,
          icon: Icons.account_balance_wallet,
        ),
      ],
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
