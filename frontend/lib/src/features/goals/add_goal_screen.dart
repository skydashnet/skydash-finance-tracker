import 'package:flutter/material.dart';
import 'package:skydash_financial_tracker/src/services/api_service.dart';
import 'package:skydash_financial_tracker/src/utils/notification_helper.dart';

class AddGoalScreen extends StatefulWidget {
  const AddGoalScreen({super.key});

  @override
  State<AddGoalScreen> createState() => _AddGoalScreenState();
}

class _AddGoalScreenState extends State<AddGoalScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _amountController = TextEditingController();
  final ApiService _apiService = ApiService();
  bool _isLoading = false;

  Future<void> _submitGoal() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      final result = await _apiService.createGoal(
        name: _nameController.text,
        targetAmount: double.parse(_amountController.text),
      );
      
      if (mounted) {
        if (result['statusCode'] == 201) {
          Navigator.pop(context, true);
        } else {
          NotificationHelper.showError(context, title: 'Gagal', message: result['body']['message']);
          setState(() => _isLoading = false);
        }
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Buat Target Baru'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Nama Target (misal: Sepatu Baru)'),
              validator: (v) => v!.isEmpty ? 'Nama tidak boleh kosong' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _amountController,
              decoration: const InputDecoration(labelText: 'Jumlah Target (Rp)'),
              keyboardType: TextInputType.number,
              validator: (v) => v!.isEmpty ? 'Jumlah tidak boleh kosong' : null,
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _isLoading ? null : _submitGoal,
              child: _isLoading ? const CircularProgressIndicator() : const Text('SIMPAN TARGET'),
            ),
          ],
        ),
      ),
    );
  }
}