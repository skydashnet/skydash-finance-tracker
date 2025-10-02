import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:rrule/rrule.dart';
import 'package:skydash_financial_tracker/src/features/recurring/add_recurring_screen.dart';
import 'package:skydash_financial_tracker/src/services/api_service.dart';
import 'package:skydash_financial_tracker/src/utils/category_icon_mapper.dart';
import 'package:skydash_financial_tracker/src/utils/notification_helper.dart';

class RecurringScreen extends StatefulWidget {
  const RecurringScreen({super.key});

  @override
  State<RecurringScreen> createState() => _RecurringScreenState();
}

class _RecurringScreenState extends State<RecurringScreen> {
  final ApiService _apiService = ApiService();
  late Future<List<dynamic>> _rulesFuture;

  @override
  void initState() {
    super.initState();
    _loadRules();
  }

  void _loadRules() {
    setState(() {
      _rulesFuture = _fetchRules();
    });
  }

  Future<List<dynamic>> _fetchRules() async {
    final result = await _apiService.getUserRecurringRules();
    if (result['statusCode'] == 200) {
      return result['body'];
    } else {
      throw Exception('Gagal memuat aturan');
    }
  }

  String _formatCurrency(num amount) {
    return NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0).format(amount);
  }

  Future<String> _rruleToText(String rruleString) async {
    try {
      final rrule = RecurrenceRule.fromString(rruleString);
      final l10n = await RruleL10nEn.create();
      return rrule.toText(l10n: l10n);
    } catch (e) {
      return 'Aturan tidak valid';
    }
  }

  void _deleteRule(int ruleId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Konfirmasi'),
        content: const Text('Hapus aturan transaksi berulang ini?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Batal')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Hapus')),
        ],
      ),
    );

    if (confirm == true && mounted) {
      final result = await _apiService.deleteRecurringRule(ruleId);
      if (mounted) {
        if (result['statusCode'] == 200) {
          NotificationHelper.showSuccess(context, title: 'Berhasil', message: result['body']['message']);
          _loadRules();
        } else {
          NotificationHelper.showError(context, title: 'Gagal', message: result['body']['message']);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Transaksi Berulang'),
      ),
      body: FutureBuilder<List<dynamic>>(
        future: _rulesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          final rules = snapshot.data!;
          if (rules.isEmpty) {
            return const Center(child: Text('Belum ada aturan transaksi berulang.'));
          }

          return RefreshIndicator(
            onRefresh: () async => _loadRules(),
            child: ListView.builder(
              padding: const EdgeInsets.all(8),
              itemCount: rules.length,
              itemBuilder: (context, index) {
                final rule = rules[index];
                final visual = CategoryIconMapper.getVisual(rule['category_name']);
                final isExpense = rule['category_type'] == 'expense';
                final amount = num.parse(rule['amount'].toString());
                
                return Card(
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: visual.color.withValues(alpha: 0.15),
                      child: Icon(visual.icon, color: visual.color),
                    ),
                    title: Text(rule['category_name']),
                    subtitle: FutureBuilder<String>(
                      future: _rruleToText(rule['recurrence_rule']),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const Text('...');
                        }
                        return Text(snapshot.data ?? 'Aturan tidak valid');
                      },
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '${isExpense ? '-' : '+'} ${_formatCurrency(amount)}',
                          style: TextStyle(
                            color: isExpense ? Colors.red : Colors.green,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline, color: Colors.grey),
                          onPressed: () => _deleteRule(rule['id']),
                        )
                      ],
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AddRecurringScreen()),
          );
          if (result == true) {
            _loadRules();
          }
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}