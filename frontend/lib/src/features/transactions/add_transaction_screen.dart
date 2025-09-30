import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:skydash_financial_tracker/src/providers/transaction_provider.dart';
import 'package:skydash_financial_tracker/src/services/api_service.dart';
import 'package:skydash_financial_tracker/src/utils/notification_helper.dart';

class AddTransactionScreen extends StatefulWidget {
  final Map<String, dynamic>? transaction;

  const AddTransactionScreen({super.key, this.transaction});

  @override
  State<AddTransactionScreen> createState() => _AddTransactionScreenState();
}

class _AddTransactionScreenState extends State<AddTransactionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();
  
  final ApiService _apiService = ApiService();
  
  int? _selectedCategoryId;
  DateTime _selectedDate = DateTime.now();
  bool _isLoading = false;
  late bool _isEditMode;

  late Future<List<dynamic>> _categoriesFuture;

  @override
  void initState() {
    super.initState();
    _isEditMode = widget.transaction != null;
    _categoriesFuture = _fetchCategories();

    if (_isEditMode) {
      final transaction = widget.transaction!;
      _amountController.text = num.parse(transaction['amount'].toString()).toString();
      _descriptionController.text = transaction['description'] ?? '';
      _selectedDate = DateTime.parse(transaction['transaction_date']);
    }
  }

  Future<List<dynamic>> _fetchCategories() async {
    final result = await _apiService.getCategories();
    if (result['statusCode'] == 200) {
      if (_isEditMode) {
        final categoryName = widget.transaction!['category_name'];
        final categories = result['body'] as List;
        _selectedCategoryId = categories.firstWhere((cat) => cat['name'] == categoryName, orElse: () => null)?['id'];
      }
      return result['body'];
    } else {
      throw Exception('Failed to load categories');
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _submitTransaction() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      
      final Map<String, dynamic> result;
      if (_isEditMode) {
        result = await _apiService.updateTransaction(
          transactionId: widget.transaction!['id'],
          categoryId: _selectedCategoryId!,
          amount: double.parse(_amountController.text),
          description: _descriptionController.text,
          transactionDate: DateFormat('yyyy-MM-dd').format(_selectedDate),
        );
      } else {
        result = await _apiService.createTransaction(
          categoryId: _selectedCategoryId!,
          amount: double.parse(_amountController.text),
          description: _descriptionController.text,
          transactionDate: DateFormat('yyyy-MM-dd').format(_selectedDate),
        );
      }

      setState(() => _isLoading = false);

      if (mounted) {
        final success = _isEditMode ? (result['statusCode'] == 200) : (result['statusCode'] == 201);
        if (success) {
          Provider.of<TransactionProvider>(context, listen: false).fetchTransactionsAndSummary();
          Navigator.pop(context, true);

          final unlockedAchievement = result['body']['unlockedAchievement'];
          if (unlockedAchievement != null) {
            Future.delayed(const Duration(milliseconds: 500), () {
              final scaffoldMessenger = ScaffoldMessenger.maybeOf(context);
              if (scaffoldMessenger != null) {
                NotificationHelper.showAchievementUnlocked(
                  scaffoldMessenger.context,
                  achievement: unlockedAchievement,
                );
              }
            });
          }
        } else {
          NotificationHelper.showError(context, title: 'Gagal', message: result['body']['message']);
        }
      }
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_isEditMode ? 'Edit Transaksi' : 'Tambah Transaksi Baru')),
      body: FutureBuilder<List<dynamic>>(
        future: _categoriesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return const Center(child: Text('Gagal memuat kategori.'));
          }
          final categories = snapshot.data!;
          final incomeCategories = categories.where((c) => c['type'] == 'income').toList();
          final expenseCategories = categories.where((c) => c['type'] == 'expense').toList();

          return Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(16.0),
              children: [
                TextFormField(
                  controller: _amountController,
                  decoration: const InputDecoration(labelText: 'Jumlah (Rp)'),
                  keyboardType: TextInputType.number,
                  validator: (value) => value!.isEmpty ? 'Jumlah tidak boleh kosong' : null,
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<int>(
                  value: _selectedCategoryId,
                  hint: const Text('Pilih Kategori'),
                  isExpanded: true,
                  items: [
                    const DropdownMenuItem<int>(
                      enabled: false,
                      child: Text('PEMASUKAN', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
                    ),
                    ...incomeCategories.map<DropdownMenuItem<int>>((category) {
                      return DropdownMenuItem<int>(
                        value: category['id'],
                        child: Text("  ${category['name']}"),
                      );
                    }).toList(),
                    const DropdownMenuItem<int>(
                      enabled: false,
                      child: Divider(),
                    ),
                    const DropdownMenuItem<int>(
                      enabled: false,
                      child: Text('PENGELUARAN', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red)),
                    ),
                    ...expenseCategories.map<DropdownMenuItem<int>>((category) {
                      return DropdownMenuItem<int>(
                        value: category['id'],
                        child: Text("  ${category['name']}"),
                      );
                    }).toList(),
                  ],
                  onChanged: (value) => setState(() => _selectedCategoryId = value),
                  validator: (value) => value == null ? 'Kategori harus dipilih' : null,
                ),
                const SizedBox(height: 16),
                
                InkWell(
                  onTap: () => _selectDate(context),
                  child: InputDecorator(
                    decoration: const InputDecoration(labelText: 'Tanggal'),
                    child: Text(DateFormat('d MMMM yyyy', 'id_ID').format(_selectedDate)),
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _descriptionController,
                  decoration: const InputDecoration(labelText: 'Deskripsi (Opsional)'),
                ),
                const SizedBox(height: 32),
                ElevatedButton(
                  onPressed: _isLoading ? null : _submitTransaction,
                  child: _isLoading ? const CircularProgressIndicator() : const Text('SIMPAN'),
                )
              ],
            ),
          );
        },
      ),
    );
  }
}