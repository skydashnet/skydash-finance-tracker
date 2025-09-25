import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:skydash_financial_tracker/src/providers/transaction_provider.dart';
import 'package:skydash_financial_tracker/src/services/api_service.dart';

class FilterBottomSheet extends StatefulWidget {
  const FilterBottomSheet({super.key});

  @override
  State<FilterBottomSheet> createState() => _FilterBottomSheetState();
}

class _FilterBottomSheetState extends State<FilterBottomSheet> {
  final ApiService _apiService = ApiService();
  late Future<List<dynamic>> _categoriesFuture;
  
  late DateTime _selectedDate;
  int? _selectedCategoryId;

  @override
  void initState() {
    super.initState();
    final provider = Provider.of<TransactionProvider>(context, listen: false);
    _selectedDate = provider.filterDate;
    _selectedCategoryId = provider.filterCategoryId;
    _categoriesFuture = _fetchCategories();
  }

  Future<List<dynamic>> _fetchCategories() async {
    final result = await _apiService.getCategories();
    if (result['statusCode'] == 200) {
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
      setState(() => _selectedDate = picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<TransactionProvider>(context, listen: false);

    return SingleChildScrollView(
      child: Padding(
        padding: EdgeInsets.fromLTRB(24, 24, 24, MediaQuery.of(context).viewInsets.bottom + 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Filter Transaksi', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 24),

            InkWell(
              onTap: () => _selectDate(context),
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'Bulan & Tahun', 
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.calendar_today),
                ),
                child: Text(DateFormat('MMMM yyyy', 'id_ID').format(_selectedDate)),
              ),
            ),
            const SizedBox(height: 16),
            
            FutureBuilder<List<dynamic>>(
              future: _categoriesFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return const Text('Gagal memuat kategori');
                }
                return DropdownButtonFormField<int>(
                  value: _selectedCategoryId,
                  hint: const Text('Semua Kategori'),
                  decoration: const InputDecoration(
                    labelText: 'Kategori', 
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.category)
                  ),
                  isExpanded: true,
                  items: snapshot.data!.map<DropdownMenuItem<int>>((category) {
                    return DropdownMenuItem<int>(
                      value: category['id'],
                      child: Text(category['name'], overflow: TextOverflow.ellipsis),
                    );
                  }).toList(),
                  onChanged: (value) => setState(() => _selectedCategoryId = value),
                );
              },
            ),
            const SizedBox(height: 24),
            
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () {
                      provider.clearFilters();
                      Navigator.pop(context);
                    },
                    child: const Text('HAPUS FILTER'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      provider.applyFilter(date: _selectedDate, categoryId: _selectedCategoryId);
                      Navigator.pop(context);
                    },
                    child: const Text('TERAPKAN'),
                  ),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}