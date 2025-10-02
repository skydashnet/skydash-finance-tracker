import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:skydash_financial_tracker/src/features/budget/add_edit_budget_screen.dart';
import 'package:skydash_financial_tracker/src/services/api_service.dart';
import 'package:skydash_financial_tracker/src/utils/category_icon_mapper.dart';

class BudgetScreen extends StatefulWidget {
  const BudgetScreen({super.key});

  @override
  State<BudgetScreen> createState() => _BudgetScreenState();
}

class _BudgetScreenState extends State<BudgetScreen> {
  final ApiService _apiService = ApiService();
  late Future<List<dynamic>> _budgetsFuture;

  @override
  void initState() {
    super.initState();
    _loadBudgets();
  }

  void _loadBudgets() {
    setState(() {
      _budgetsFuture = _fetchBudgets();
    });
  }

  Future<List<dynamic>> _fetchBudgets() async {
    final result = await _apiService.getBudgets();
    if (result['statusCode'] == 200) {
      return result['body'];
    } else {
      throw Exception('Gagal memuat budget');
    }
  }
  
  String _formatCurrency(num amount) {
    return NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0).format(amount);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Budget Bulan ${DateFormat('MMMM').format(DateTime.now())}'),
      ),
      body: FutureBuilder<List<dynamic>>(
        future: _budgetsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          final budgets = snapshot.data!;
          if (budgets.isEmpty) {
            return const Center(child: Text('Belum ada budget dibuat untuk bulan ini.'));
          }
          
          return RefreshIndicator(
            onRefresh: () async => _loadBudgets(),
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: budgets.length,
              itemBuilder: (context, index) {
                final budget = budgets[index];
                return _buildBudgetCard(context, budget);
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AddEditBudgetScreen()),
          );
          if (result == true) {
            _loadBudgets();
          }
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildBudgetCard(BuildContext context, Map<String, dynamic> budget) {
    final amount = num.parse(budget['amount'].toString());
    final spentAmount = num.parse(budget['spent_amount'].toString());
    final remainingAmount = amount - spentAmount;
    final progress = amount > 0 ? (spentAmount / amount) : 1.0;
    
    final visual = CategoryIconMapper.getVisual(budget['category_name']);
    final progressColor = progress > 1 ? Colors.red : (progress > 0.8 ? Colors.orange : Theme.of(context).colorScheme.primary);
    
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () async {
           final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => AddEditBudgetScreen(budget: budget)),
          );
          if (result == true) {
            _loadBudgets();
          }
        },
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: visual.color.withOpacity(0.15),
                    child: Icon(visual.icon, color: visual.color, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Text(budget['category_name'], style: const TextStyle(fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 12),
              LinearProgressIndicator(
                value: progress.clamp(0.0, 1.0),
                minHeight: 8,
                borderRadius: BorderRadius.circular(4),
                backgroundColor: progressColor.withOpacity(0.2),
                valueColor: AlwaysStoppedAnimation<Color>(progressColor),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(_formatCurrency(spentAmount), style: const TextStyle(fontWeight: FontWeight.bold)),
                  Text(_formatCurrency(amount), style: TextStyle(color: Colors.grey[600])),
                ],
              ),
              const SizedBox(height: 4),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  remainingAmount >= 0 
                    ? 'Sisa: ${_formatCurrency(remainingAmount)}'
                    : 'Lebih: ${_formatCurrency(remainingAmount.abs())}',
                  style: TextStyle(fontSize: 12, color: remainingAmount >= 0 ? Colors.green : Colors.red),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}