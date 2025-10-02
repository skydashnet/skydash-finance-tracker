import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:skydash_financial_tracker/src/features/transactions/category_picker_screen.dart';
import 'package:skydash_financial_tracker/src/services/api_service.dart';
import 'package:skydash_financial_tracker/src/utils/category_icon_mapper.dart';
import 'package:skydash_financial_tracker/src/utils/notification_helper.dart';

class AddEditBudgetScreen extends StatefulWidget {
  final Map<String, dynamic>? budget;

  const AddEditBudgetScreen({super.key, this.budget});

  @override
  State<AddEditBudgetScreen> createState() => _AddEditBudgetScreenState();
}

class _AddEditBudgetScreenState extends State<AddEditBudgetScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final ApiService _apiService = ApiService();
  
  Map<String, dynamic>? _selectedCategory;
  late bool _isEditMode;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _isEditMode = widget.budget != null;
    if (_isEditMode) {
      final budget = widget.budget!;
      _amountController.text = num.parse(budget['amount'].toString()).toStringAsFixed(0);
      _selectedCategory = {
        'id': budget['category_id'],
        'name': budget['category_name'],
      };
    }
  }

  Future<void> _pickCategory() async {
    final result = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(builder: (context) => const CategoryPickerScreen()),
    );
    if (result != null) {
      if (result['type'] == 'income') {
        NotificationHelper.showError(context, title: 'Kategori Salah', message: 'Budget hanya bisa dibuat untuk kategori pengeluaran.');
        return;
      }
      setState(() {
        _selectedCategory = result;
      });
    }
  }

  Future<void> _submitBudget() async {
    if (_selectedCategory == null) {
      NotificationHelper.showError(context, title: 'Error', message: 'Kategori harus dipilih.');
      return;
    }

    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      
      final result = await _apiService.createOrUpdateBudget(
        categoryId: _selectedCategory!['id'],
        amount: double.parse(_amountController.text),
        period: DateFormat('yyyy-MM').format(DateTime.now()),
      );
      
      if (mounted) {
        if (result['statusCode'] == 201) {
          Navigator.pop(context, true);
          NotificationHelper.showSuccess(context, title: 'Berhasil', message: result['body']['message']);
        } else {
          NotificationHelper.showError(context, title: 'Gagal', message: result['body']['message']);
          setState(() => _isLoading = false);
        }
      }
    }
  }
  
  Future<void> _deleteBudget() async {
     final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Konfirmasi'),
        content: const Text('Hapus budget untuk kategori ini?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Batal')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Hapus')),
        ],
      ),
    );

    if (confirm == true && mounted) {
      final result = await _apiService.deleteBudget(widget.budget!['id']);
       if (mounted) {
        if (result['statusCode'] == 200) {
          Navigator.pop(context, true);
          NotificationHelper.showSuccess(context, title: 'Berhasil', message: result['body']['message']);
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
        title: Text(_isEditMode ? 'Edit Budget' : 'Buat Budget Baru'),
        actions: [
          if (_isEditMode)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: _deleteBudget,
            )
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            ListTile(
              enabled: !_isEditMode,
              contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
                side: BorderSide(color: Colors.grey.shade400),
              ),
              leading: _selectedCategory == null
                  ? const Icon(Icons.category_outlined)
                  : CircleAvatar(
                      backgroundColor: CategoryIconMapper.getVisual(_selectedCategory!['name']).color.withOpacity(0.15),
                      child: Icon(
                        CategoryIconMapper.getVisual(_selectedCategory!['name']).icon,
                        color: CategoryIconMapper.getVisual(_selectedCategory!['name']).color,
                      ),
                    ),
              title: Text(_selectedCategory == null ? 'Pilih Kategori Pengeluaran' : _selectedCategory!['name']),
              trailing: _isEditMode ? null : const Icon(Icons.chevron_right),
              onTap: _isEditMode ? null : _pickCategory,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _amountController,
              decoration: const InputDecoration(labelText: 'Jumlah Budget (Rp)'),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              validator: (v) => v!.isEmpty ? 'Jumlah tidak boleh kosong' : null,
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _isLoading ? null : _submitBudget,
              child: _isLoading ? const CircularProgressIndicator() : const Text('SIMPAN BUDGET'),
            ),
          ],
        ),
      ),
    );
  }
}