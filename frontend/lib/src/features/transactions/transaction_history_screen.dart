import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:skydash_financial_tracker/src/constants/app_colors.dart';
import 'package:skydash_financial_tracker/src/features/transactions/add_transaction_screen.dart';
import 'package:skydash_financial_tracker/src/features/transactions/widgets/filter_bottom_sheet.dart';
import 'package:skydash_financial_tracker/src/providers/transaction_provider.dart';
import 'package:skydash_financial_tracker/src/services/api_service.dart';
import 'package:skydash_financial_tracker/src/utils/category_icon_mapper.dart';
import 'package:skydash_financial_tracker/src/utils/notification_helper.dart';

class TransactionHistoryScreen extends StatelessWidget {
  TransactionHistoryScreen({super.key});

  final ApiService _apiService = ApiService();
  Future<void> _deleteTransaction(BuildContext context, Map<String, dynamic> transaction) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Konfirmasi Hapus"),
          content: const Text("Apakah kamu yakin ingin menghapus transaksi ini?"),
          actions: <Widget>[
            TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text("BATAL")),
            TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text("HAPUS", style: TextStyle(color: Colors.red))),
          ],
        );
      },
    );

    if (confirm == true && context.mounted) {
      final result = await _apiService.deleteTransaction(transaction['id']);
      if (context.mounted) {
        if (result['statusCode'] == 200) {
          NotificationHelper.showSuccess(context, title: 'Berhasil', message: result['body']['message']);
          Provider.of<TransactionProvider>(context, listen: false).fetchTransactionsAndSummary();
        } else {
          NotificationHelper.showError(context, title: 'Gagal', message: result['body']['message']);
        }
      }
    }
  }

  void _showTransactionDetails(BuildContext context, Map<String, dynamic> transaction) {
    final visual = CategoryIconMapper.getVisual(transaction['category_name']);
    final isExpense = transaction['category_type'] == 'expense';
    final amount = num.parse(transaction['amount'].toString());

    showModalBottomSheet(
      context: context,
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: visual.color.withOpacity(0.15),
                    child: Icon(visual.icon, color: visual.color),
                  ),
                  const SizedBox(width: 16),
                  Text(transaction['category_name'], style: Theme.of(context).textTheme.titleLarge),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                '${isExpense ? '-' : '+'} ${_formatCurrency(amount)}',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: isExpense ? Colors.red : Colors.green,
                ),
              ),
              const Divider(height: 24),
              ListTile(
                leading: const Icon(Icons.calendar_today, size: 20),
                title: const Text('Tanggal'),
                subtitle: Text(_formatDate(transaction['transaction_date'])),
              ),
              if (transaction['description'] != null && transaction['description'].isNotEmpty)
                ListTile(
                  leading: const Icon(Icons.notes, size: 20),
                  title: const Text('Deskripsi'),
                  subtitle: Text(transaction['description']),
                ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.delete_outline),
                      label: const Text('HAPUS'),
                      style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
                      onPressed: () {
                        Navigator.pop(ctx);
                        _deleteTransaction(context, transaction);
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.edit_outlined),
                      label: const Text('EDIT'),
                      onPressed: () {
                        Navigator.pop(ctx);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => AddTransactionScreen(transaction: transaction),
                          ),
                        ).then((_) {
                          Provider.of<TransactionProvider>(context, listen: false).fetchTransactionsAndSummary();
                        });
                      },
                    ),
                  ),
                ],
              )
            ],
          ),
        );
      },
    );
  }

  void _navigateAndRefresh(BuildContext context) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AddTransactionScreen()),
    );
    if (result == true && context.mounted) {
      Provider.of<TransactionProvider>(context, listen: false).fetchTransactionsAndSummary();
    }
  }

  void _showFilterPanel(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => const FilterBottomSheet(),
    );
  }

  String _formatCurrency(num amount) {
    final format =
        NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
    return format.format(amount);
  }

  String _formatDate(String dateString) {
    final date = DateTime.parse(dateString);
    return DateFormat('d MMMM yyyy', 'id_ID').format(date);
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<TransactionProvider>(
      builder: (context, provider, child) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Riwayat Transaksi'),
            actions: [
              IconButton(
                icon: const Icon(Icons.filter_list),
                onPressed: () => _showFilterPanel(context),
              ),
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
    if (provider.isLoading && provider.transactions.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (provider.error != null) {
      return Center(child: Text(provider.error!));
    }

    if (provider.transactions.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.receipt_long_outlined,
                size: 100,
                color: Colors.grey[300],
              ),
              const SizedBox(height: 24),
              const Text(
                'Oops, Masih Kosong!',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Tidak ada transaksi yang cocok dengan filter ini. Coba hapus filter atau catat transaksi baru!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () => _navigateAndRefresh(context),
                icon: const Icon(Icons.add),
                label: const Text('Catat Transaksi'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
              )
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      itemCount: provider.transactions.length,
      itemBuilder: (context, index) {
        final transaction = provider.transactions[index];
        final isExpense = transaction['category_type'] == 'expense';

        return Dismissible(
          key: ValueKey(transaction['id']),
          direction: DismissDirection.endToStart,
          background: Container(
            color: Colors.red,
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: const Icon(Icons.delete_sweep, color: Colors.white),
          ),
          confirmDismiss: (direction) async => false,
          onDismissed: (direction) {
            _deleteTransaction(context, transaction);
          },
          child: Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            child: ListTile(
              onTap: () => _showTransactionDetails(context, transaction),
              leading: Builder(
                builder: (context) {
                  final visual = CategoryIconMapper.getVisual(transaction['category_name']);
                  return CircleAvatar(
                    backgroundColor: Color.fromRGBO(
                      (visual.color.r * 255.0).round() & 0xff,
                      (visual.color.g * 255.0).round() & 0xff,
                      (visual.color.b * 255.0).round() & 0xff,
                      0.15,
                    ),
                    child: Icon(
                      visual.icon,
                      color: visual.color,
                      size: 20,
                    ),
                  );
                },
              ),
              title: Text(
                transaction['category_name'],
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Text(
                _formatDate(transaction['transaction_date']),
                style: const TextStyle(color: AppColors.textSecondary),
              ),
              trailing: Text(
                _formatCurrency(num.parse(transaction['amount'].toString())),
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: isExpense ? Colors.red : Colors.green,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}