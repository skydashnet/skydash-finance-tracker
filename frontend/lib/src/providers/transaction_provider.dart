import 'package:flutter/material.dart';
import 'package:skydash_financial_tracker/src/services/api_service.dart';

class TransactionProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService();

  Map<String, dynamic>? _summary;
  List<dynamic> _transactions = [];
  bool _isLoading = false;
  String? _error;

  Map<String, dynamic>? get summary => _summary;
  List<dynamic> get transactions => _transactions;
  bool get isLoading => _isLoading;
  String? get error => _error;
  DateTime _filterDate = DateTime.now();
  int? _filterCategoryId;

  DateTime get filterDate => _filterDate;
  int? get filterCategoryId => _filterCategoryId;

  TransactionProvider() {
    fetchTransactionsAndSummary();
  }

  Future<void> fetchTransactionsAndSummary({bool keepFilters = false}) async {
    _isLoading = true;
    if (!keepFilters) {
      _error = null;
    }
    notifyListeners();

    final transactionResult = await _apiService.getTransactions(
      year: _filterDate.year,
      month: _filterDate.month,
      categoryId: _filterCategoryId,
    );

    final summaryResult = await _apiService.getSummary();

    if (summaryResult['statusCode'] == 200 &&
        transactionResult['statusCode'] == 200) {
      _summary = summaryResult['body']['summary'];
      _transactions = transactionResult['body'];
    } else {
      _error = "Gagal memuat data.";
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> applyFilter({DateTime? date, int? categoryId}) async {
    _filterDate = date ?? _filterDate;
    _filterCategoryId = categoryId;
    await fetchTransactionsAndSummary(keepFilters: true);
  }

  Future<void> clearFilters() async {
    _filterDate = DateTime.now();
    _filterCategoryId = null;
    await fetchTransactionsAndSummary();
  }
}
