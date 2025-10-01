import 'package:flutter/material.dart';
import 'package:skydash_financial_tracker/src/services/api_service.dart';
import 'package:skydash_financial_tracker/src/utils/category_icon_mapper.dart';

class CategoryPickerScreen extends StatefulWidget {
  const CategoryPickerScreen({super.key});

  @override
  State<CategoryPickerScreen> createState() => _CategoryPickerScreenState();
}

class _CategoryPickerScreenState extends State<CategoryPickerScreen> {
  final ApiService _apiService = ApiService();
  late Future<Map<String, List<dynamic>>> _categoriesFuture;

  @override
  void initState() {
    super.initState();
    _categoriesFuture = _fetchAndGroupCategories();
  }

  Future<Map<String, List<dynamic>>> _fetchAndGroupCategories() async {
    final result = await _apiService.getCategories();
    if (result['statusCode'] == 200) {
      final List<dynamic> allCategories = result['body'];
      return {
        'expense': allCategories.where((c) => c['type'] == 'expense').toList(),
        'income': allCategories.where((c) => c['type'] == 'income').toList(),
      };
    } else {
      throw Exception('Failed to load categories');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pilih Kategori'),
      ),
      body: FutureBuilder<Map<String, List<dynamic>>>(
        future: _categoriesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return const Center(child: Text('Gagal memuat kategori.'));
          }

          final expenseCategories = snapshot.data!['expense']!;
          final incomeCategories = snapshot.data!['income']!;

          return ListView(
            padding: const EdgeInsets.all(16.0),
            children: [
              _buildCategoryGroup(context, 'PENGELUARAN', expenseCategories),
              const SizedBox(height: 24),
              _buildCategoryGroup(context, 'PEMASUKAN', incomeCategories),
            ],
          );
        },
      ),
    );
  }

  Widget _buildCategoryGroup(BuildContext context, String title, List<dynamic> categories) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        GridView.builder(
          physics: const NeverScrollableScrollPhysics(),
          shrinkWrap: true,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 4,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
          ),
          itemCount: categories.length,
          itemBuilder: (context, index) {
            final category = categories[index];
            final visual = CategoryIconMapper.getVisual(category['name']);
            return InkWell(
              onTap: () {
                Navigator.pop(context, category);
              },
              borderRadius: BorderRadius.circular(12),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: visual.color.withOpacity(0.15),
                    child: Icon(visual.icon, color: visual.color, size: 28),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    category['name'],
                    textAlign: TextAlign.center,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 12),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }
}