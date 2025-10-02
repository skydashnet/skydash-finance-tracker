import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:rrule/rrule.dart';
import 'package:skydash_financial_tracker/src/features/transactions/category_picker_screen.dart';
import 'package:skydash_financial_tracker/src/services/api_service.dart';
import 'package:skydash_financial_tracker/src/utils/category_icon_mapper.dart';
import 'package:skydash_financial_tracker/src/utils/notification_helper.dart';

class AddRecurringScreen extends StatefulWidget {
  const AddRecurringScreen({super.key});

  @override
  State<AddRecurringScreen> createState() => _AddRecurringScreenState();
}

class _AddRecurringScreenState extends State<AddRecurringScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();
  final ApiService _apiService = ApiService();
  
  Map<String, dynamic>? _selectedCategory;
  final DateTime _startDate = DateTime.now();
  
  Frequency _frequency = Frequency.monthly;
  int _dayOfMonth = 1;
  int _dayOfWeek = DateTime.monday;

  bool _isLoading = false;

  Future<void> _pickCategory() async {
    final result = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(builder: (context) => const CategoryPickerScreen()),
    );
    if (result != null) {
      setState(() => _selectedCategory = result);
    }
  }

  String _buildRruleString() {
    if (_frequency == Frequency.monthly) {
      return 'FREQ=MONTHLY;BYMONTHDAY=$_dayOfMonth';
    } else if (_frequency == Frequency.weekly) {
      final days = ['MO', 'TU', 'WE', 'TH', 'FR', 'SA', 'SU'];
      return 'FREQ=WEEKLY;BYDAY=${days[_dayOfWeek - 1]}';
    }
    return 'FREQ=DAILY';
  }

  Future<void> _submitRule() async {
    if (_selectedCategory == null) {
      NotificationHelper.showError(context, title: 'Error', message: 'Kategori harus dipilih');
      return;
    }
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      
      final result = await _apiService.createRecurringRule(
        categoryId: _selectedCategory!['id'],
        amount: double.parse(_amountController.text),
        description: _descriptionController.text,
        recurrenceRule: _buildRruleString(),
        startDate: DateFormat('yyyy-MM-dd').format(_startDate),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Buat Aturan Baru')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _amountController,
              decoration: const InputDecoration(labelText: 'Jumlah (Rp)'),
              keyboardType: TextInputType.number,
              validator: (v) => v!.isEmpty ? 'Jumlah tidak boleh kosong' : null,
            ),
            const SizedBox(height: 16),
            
            ListTile(
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
              title: Text(_selectedCategory == null ? 'Pilih Kategori' : _selectedCategory!['name']),
              trailing: const Icon(Icons.chevron_right),
              onTap: _pickCategory,
            ),
            const SizedBox(height: 24),

            Text('Aturan Berulang', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            DropdownButtonFormField<Frequency>(
              value: _frequency,
              items: const [
                DropdownMenuItem(value: Frequency.monthly, child: Text('Setiap Bulan')),
                DropdownMenuItem(value: Frequency.weekly, child: Text('Setiap Minggu')),
                DropdownMenuItem(value: Frequency.daily, child: Text('Setiap Hari')),
              ],
              onChanged: (value) {
                if (value != null) setState(() => _frequency = value);
              },
            ),
            const SizedBox(height: 16),

            if (_frequency == Frequency.monthly)
              DropdownButtonFormField<int>(
                value: _dayOfMonth,
                hint: const Text('Pilih Tanggal'),
                items: List.generate(31, (index) => DropdownMenuItem(value: index + 1, child: Text('Tanggal ${index + 1}'))),
                onChanged: (value) {
                  if (value != null) setState(() => _dayOfMonth = value);
                },
              ),
            
            if (_frequency == Frequency.weekly)
              DropdownButtonFormField<int>(
                value: _dayOfWeek,
                hint: const Text('Pilih Hari'),
                items: const [
                  DropdownMenuItem(value: DateTime.monday, child: Text('Hari Senin')),
                  DropdownMenuItem(value: DateTime.tuesday, child: Text('Hari Selasa')),
                  DropdownMenuItem(value: DateTime.wednesday, child: Text('Hari Rabu')),
                  DropdownMenuItem(value: DateTime.thursday, child: Text('Hari Kamis')),
                  DropdownMenuItem(value: DateTime.friday, child: Text('Hari Jumat')),
                  DropdownMenuItem(value: DateTime.saturday, child: Text('Hari Sabtu')),
                  DropdownMenuItem(value: DateTime.sunday, child: Text('Hari Minggu')),
                ],
                onChanged: (value) {
                  if (value != null) setState(() => _dayOfWeek = value);
                },
              ),
            
            const SizedBox(height: 16),
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(labelText: 'Deskripsi (Opsional)'),
            ),
            const SizedBox(height: 32),
            
            ElevatedButton(
              onPressed: _isLoading ? null : _submitRule,
              child: _isLoading ? const CircularProgressIndicator() : const Text('SIMPAN ATURAN'),
            )
          ],
        ),
      ),
    );
  }
}