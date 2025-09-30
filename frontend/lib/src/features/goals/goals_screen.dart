import 'dart:math';
import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:skydash_financial_tracker/src/features/goals/add_goal_screen.dart';
import 'package:skydash_financial_tracker/src/providers/transaction_provider.dart';
import 'package:skydash_financial_tracker/src/services/api_service.dart';
import 'package:skydash_financial_tracker/src/utils/notification_helper.dart';

class GoalsScreen extends StatefulWidget {
  const GoalsScreen({super.key});

  @override
  State<GoalsScreen> createState() => _GoalsScreenState();
}

class _GoalsScreenState extends State<GoalsScreen> {
  final ApiService _apiService = ApiService();
  late Future<List<dynamic>> _goalsFuture;
  late ConfettiController _confettiController;

  @override
  void initState() {
    super.initState();
    _loadGoals();
    _confettiController = ConfettiController(duration: const Duration(seconds: 3));
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  void _loadGoals() {
    setState(() {
      _goalsFuture = _fetchGoals();
    });
  }

  Future<List<dynamic>> _fetchGoals() async {
    final result = await _apiService.getUserGoals();
    if (result['statusCode'] == 200) {
      return result['body'];
    } else {
      throw Exception('Gagal memuat target');
    }
  }

  void _showAddSavingsDialog(BuildContext context, Map<String, dynamic> goal) {
    final amountController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text('Tambah Tabungan untuk "${goal['name']}"'),
          content: Form(
            key: formKey,
            child: TextFormField(
              controller: amountController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'Jumlah (Rp)',
                prefixText: 'Rp ',
              ),
              validator: (value) {
                if (value == null || value.isEmpty) return 'Jumlah tidak boleh kosong';
                if (double.tryParse(value) == null) return 'Masukkan angka yang valid';
                return null;
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (formKey.currentState!.validate()) {
                  final amount = double.parse(amountController.text);
                  Navigator.pop(dialogContext);

                  final transactionProvider = Provider.of<TransactionProvider>(context, listen: false);
                  final categoriesResult = await _apiService.getCategories();
                  if (!context.mounted) return;

                  if (categoriesResult['statusCode'] != 200) {
                    NotificationHelper.showError(context, title: 'Error', message: 'Gagal memuat daftar kategori.');
                    return;
                  }
                  
                  final categories = categoriesResult['body'] as List;
                  final Map<String, dynamic>? savingsCategory = categories.firstWhere(
                    (cat) => cat['name'] == 'Tabungan' && cat['type'] == 'expense',
                    orElse: () => null,
                  );

                  if (savingsCategory == null) {
                     NotificationHelper.showError(context, title: 'Error', message: "Kategori 'Tabungan' (tipe: Pengeluaran) tidak ditemukan.");
                     return;
                  }

                  final trxResult = await _apiService.createTransaction(
                    categoryId: savingsCategory['id'],
                    amount: amount,
                    description: 'Menabung untuk ${goal['name']}',
                    transactionDate: DateFormat('yyyy-MM-dd').format(DateTime.now()),
                  );

                  if (!context.mounted) return;

                  if (trxResult['statusCode'] != 201) {
                     NotificationHelper.showError(context, title: 'Gagal', message: 'Gagal membuat transaksi tabungan.');
                     return;
                  }

                  final goalResult = await _apiService.addSavingsToGoal(goal['id'], amount);

                  if (context.mounted) {
                    if (goalResult['statusCode'] == 200) {
                      NotificationHelper.showSuccess(context, title: 'Berhasil!', message: 'Tabungan berhasil ditambahkan.');
                      transactionProvider.fetchTransactionsAndSummary();
                      _loadGoals();

                      final updatedGoalAmount = num.parse(goal['current_amount'].toString()) + amount;
                      final targetAmount = num.parse(goal['target_amount'].toString());
                      if (updatedGoalAmount >= targetAmount && num.parse(goal['current_amount'].toString()) < targetAmount) {
                         _confettiController.play();
                      }
                    } else {
                      NotificationHelper.showError(context, title: 'Gagal', message: goalResult['body']['message']);
                    }
                  }
                }
              },
              child: const Text('Simpan'),
            ),
          ],
        );
      },
    );
  }

  void _deleteGoal(int goalId, String goalName) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Konfirmasi Hapus'),
        content: Text('Apakah kamu yakin ingin menghapus target "$goalName"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Batal')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Hapus')),
        ],
      ),
    );

    if (confirm == true && mounted) {
      final result = await _apiService.deleteGoal(goalId);
      if (mounted) {
        if (result['statusCode'] == 200) {
          NotificationHelper.showSuccess(context, title: 'Berhasil', message: result['body']['message']);
          _loadGoals();
          Provider.of<TransactionProvider>(context, listen: false).fetchTransactionsAndSummary();
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
        title: const Text('Target Tabungan'),
      ),
      body: Stack(
        children: [
          FutureBuilder<List<dynamic>>(
            future: _goalsFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}'));
              }
              final goals = snapshot.data!;
              if (goals.isEmpty) {
                return const Center(child: Text('Kamu belum punya target. Ayo buat satu!'));
              }
              return RefreshIndicator(
                onRefresh: () async => _loadGoals(),
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: goals.length,
                  itemBuilder: (context, index) {
                    return _buildGoalCard(goals[index]);
                  },
                ),
              );
            },
          ),
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confettiController,
              blastDirectionality: BlastDirectionality.explosive,
              shouldLoop: false,
              colors: const [Colors.green, Colors.blue, Colors.pink, Colors.orange, Colors.purple],
              createParticlePath: drawStar,
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AddGoalScreen()),
          );
          if (result == true) {
            _loadGoals();
          }
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Path drawStar(Size size) {
    double degToRad(double deg) => deg * (pi / 180.0);
    const numberOfPoints = 5;
    final halfWidth = size.width / 2;
    final outerRadius = halfWidth;
    final innerRadius = halfWidth / 2.5;
    final Path path = Path();
    final double a = degToRad(90.0);
    path.moveTo(halfWidth + outerRadius * cos(a), halfWidth + outerRadius * sin(a));
    for (int i = 1; i <= numberOfPoints * 2; i++) {
      final double r = (i % 2) == 0 ? outerRadius : innerRadius;
      final double a = degToRad(90.0 + (360 / (numberOfPoints * 2)) * i);
      path.lineTo(halfWidth + r * cos(a), halfWidth + r * sin(a));
    }
    path.close();
    return path;
  }

  Widget _buildGoalCard(Map<String, dynamic> goal) {
    final target = num.parse(goal['target_amount'].toString());
    final current = num.parse(goal['current_amount'].toString());
    final progress = (target > 0) ? (current / target) : 0.0;
    final formatCurrency = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

    return Card(
      clipBehavior: Clip.antiAlias,
      margin: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            alignment: Alignment.bottomLeft,
            children: [
              Image.network(
                goal['image_url'] != null && goal['image_url'].isNotEmpty
                    ? goal['image_url']
                    : 'https://picsum.photos/400/200?random=${goal['id']}',
                height: 180,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  height: 180,
                  color: Colors.grey[200],
                  child: Icon(Icons.broken_image, color: Colors.grey[400], size: 50),
                ),
              ),
              Container(
                height: 180,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.transparent, Color.fromRGBO(0, 0, 0, 0.7)],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(12.0),
                child: Text(
                  goal['name'],
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
                ),
              ),
              Positioned.fill(
                child: Align(
                  alignment: Alignment.bottomCenter,
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 6,
                    backgroundColor: Colors.white30,
                    valueColor: AlwaysStoppedAnimation<Color>(Theme.of(context).colorScheme.primary),
                  ),
                ),
              ),
              Positioned(
                top: 8,
                right: 8,
                child: IconButton(
                  icon: const Icon(Icons.delete_forever, color: Colors.white, size: 28),
                  onPressed: () => _deleteGoal(goal['id'], goal['name']),
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Terkumpul', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                    Text(formatCurrency.format(current), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('dari Target', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                    Text(formatCurrency.format(target), style: TextStyle(fontSize: 16, color: Colors.grey[800])),
                  ],
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 8, 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => _showAddSavingsDialog(context, goal),
                  child: const Text('TAMBAH TABUNGAN'),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }
}