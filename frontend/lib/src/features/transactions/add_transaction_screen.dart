import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:skydash_financial_tracker/src/features/transactions/category_picker_screen.dart';
import 'package:skydash_financial_tracker/src/providers/transaction_provider.dart';
import 'package:skydash_financial_tracker/src/services/api_service.dart';
import 'package:skydash_financial_tracker/src/utils/category_icon_mapper.dart';
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

  Map<String, dynamic>? _selectedCategory;

  DateTime _selectedDate = DateTime.now();
  bool _isLoading = false;
  late bool _isEditMode;

  @override
  void initState() {
    super.initState();
    _isEditMode = widget.transaction != null;

    if (_isEditMode) {
      final transaction = widget.transaction!;
      _amountController.text = num.parse(
        transaction['amount'].toString(),
      ).toString();
      _descriptionController.text = transaction['description'] ?? '';
      _selectedDate = DateTime.parse(transaction['transaction_date']);
      _selectedCategory = {
        'id': transaction['category_id'],
        'name': transaction['category_name'],
        'type': transaction['category_type'],
      };
    }
  }

  Future<void> _pickCategory() async {
    final result = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(builder: (context) => const CategoryPickerScreen()),
    );
    if (result != null) {
      setState(() {
        _selectedCategory = result;
      });
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
    if (_selectedCategory == null) {
      NotificationHelper.showError(
        context,
        title: 'Error',
        message: 'Kategori harus dipilih',
      );
      return;
    }

    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      final Map<String, dynamic> result;
      final categoryId = _selectedCategory!['id'];

      if (_isEditMode) {
        result = await _apiService.updateTransaction(
          transactionId: widget.transaction!['id'],
          categoryId: categoryId,
          amount: double.parse(_amountController.text),
          description: _descriptionController.text,
          transactionDate: DateFormat('yyyy-MM-dd').format(_selectedDate),
        );
      } else {
        result = await _apiService.createTransaction(
          categoryId: categoryId,
          amount: double.parse(_amountController.text),
          description: _descriptionController.text,
          transactionDate: DateFormat('yyyy-MM-dd').format(_selectedDate),
        );
      }

      setState(() => _isLoading = false);

      if (mounted) {
        final success = _isEditMode
            ? (result['statusCode'] == 200)
            : (result['statusCode'] == 201);
        if (success) {
          Provider.of<TransactionProvider>(
            context,
            listen: false,
          ).fetchTransactionsAndSummary();
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
          NotificationHelper.showError(
            context,
            title: 'Gagal',
            message: result['body']['message'],
          );
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
      appBar: AppBar(
        title: Text(_isEditMode ? 'Edit Transaksi' : 'Tambah Transaksi Baru'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            TextFormField(
              controller: _amountController,
              decoration: const InputDecoration(labelText: 'Jumlah (Rp)'),
              keyboardType: TextInputType.number,
              validator: (value) =>
                  value!.isEmpty ? 'Jumlah tidak boleh kosong' : null,
            ),
            const SizedBox(height: 16),
            ListTile(
              contentPadding: const EdgeInsets.symmetric(
                vertical: 8,
                horizontal: 12,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
                side: BorderSide(color: Colors.grey.shade400),
              ),
              leading: _selectedCategory == null
                  ? const Icon(Icons.category_outlined)
                  : CircleAvatar(
                      backgroundColor: CategoryIconMapper.getVisual(
                        _selectedCategory!['name'],
                      ).color.withOpacity(0.15),
                      child: Icon(
                        CategoryIconMapper.getVisual(
                          _selectedCategory!['name'],
                        ).icon,
                        color: CategoryIconMapper.getVisual(
                          _selectedCategory!['name'],
                        ).color,
                      ),
                    ),
              title: Text(
                _selectedCategory == null
                    ? 'Pilih Kategori'
                    : _selectedCategory!['name'],
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: _pickCategory,
            ),

            const SizedBox(height: 16),
            InkWell(
              onTap: () => _selectDate(context),
              child: InputDecorator(
                decoration: const InputDecoration(labelText: 'Tanggal'),
                child: Text(
                  DateFormat('d MMMM yyyy', 'id_ID').format(_selectedDate),
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Deskripsi (Opsional)',
              ),
            ),
            const SizedBox(height: 32),

            ElevatedButton(
              onPressed: _isLoading ? null : _submitTransaction,
              child: _isLoading
                  ? const CircularProgressIndicator()
                  : const Text('SIMPAN'),
            ),
          ],
        ),
      ),
    );
  }
}
