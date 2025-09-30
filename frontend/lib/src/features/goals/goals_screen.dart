import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:skydash_financial_tracker/src/features/goals/add_goal_screen.dart';
import 'package:skydash_financial_tracker/src/services/api_service.dart';

class GoalsScreen extends StatefulWidget {
  const GoalsScreen({super.key});

  @override
  State<GoalsScreen> createState() => _GoalsScreenState();
}

class _GoalsScreenState extends State<GoalsScreen> {
  final ApiService _apiService = ApiService();
  late Future<List<dynamic>> _goalsFuture;

  @override
  void initState() {
    super.initState();
    _loadGoals();
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

  void _showAddSavingsDialog(Map<String, dynamic> goal) {
    final amountController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Tambah Tabungan untuk "${goal['name']}"'),
          content: Form(
            key: formKey,
            child: TextFormField(
              controller: amountController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Jumlah (Rp)',
                prefixText: 'Rp ',
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Jumlah tidak boleh kosong';
                }
                if (double.tryParse(value) == null) {
                  return 'Masukkan angka yang valid';
                }
                return null;
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (formKey.currentState!.validate()) {
                  final amount = double.parse(amountController.text);
                  final result = await _apiService.addSavingsToGoal(goal['id'], amount);
                  
                  if (mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(result['body']['message']),
                        backgroundColor: result['statusCode'] == 200 ? Colors.green : Colors.red,
                      ),
                    );
                    if (result['statusCode'] == 200) {
                      _loadGoals();
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Target Tabungan'),
      ),
      body: FutureBuilder<List<dynamic>>(
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
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.transparent, const Color.fromRGBO(0, 0, 0, 0.7)],
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
                  onPressed: () => _showAddSavingsDialog(goal),
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