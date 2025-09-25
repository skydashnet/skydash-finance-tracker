import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:skydash_financial_tracker/src/providers/transaction_provider.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  int touchedIndex = -1;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Laporan Keuangan'),
      ),
      body: Consumer<TransactionProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading && provider.transactions.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }
          if (provider.transactions.isEmpty) {
            return const Center(child: Text('Tidak ada data untuk ditampilkan.'));
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text('Ringkasan Pengeluaran', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 8),
              Text(
                'Berdasarkan kategori bulan ini',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 20),
              SizedBox(
                height: 200,
                child: _buildPieChart(provider),
              ),
              const SizedBox(height: 40),
              Text('Tren Pemasukan vs Pengeluaran', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 8),
              Text(
                'Beberapa bulan terakhir',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 20),
              SizedBox(
                height: 250,
                child: _buildBarChart(provider),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildPieChart(TransactionProvider provider) {
    final sections = _createPieChartSections(provider);
    if (sections.isEmpty) {
      return const Center(child: Text('Tidak ada data pengeluaran.'));
    }

    return PieChart(
      PieChartData(
        pieTouchData: PieTouchData(
          touchCallback: (FlTouchEvent event, pieTouchResponse) {
            setState(() {
              if (!event.isInterestedForInteractions ||
                  pieTouchResponse == null ||
                  pieTouchResponse.touchedSection == null) {
                touchedIndex = -1;
                return;
              }
              touchedIndex = pieTouchResponse.touchedSection!.touchedSectionIndex;
            });
          },
        ),
        borderData: FlBorderData(show: false),
        sectionsSpace: 2,
        centerSpaceRadius: 40,
        sections: sections,
      ),
    );
  }

  List<PieChartSectionData> _createPieChartSections(TransactionProvider provider) {
    final expenses = provider.transactions.where((t) => t['category_type'] == 'expense');
    if (expenses.isEmpty) return [];

    final Map<String, double> categoryTotals = {};
    for (var exp in expenses) {
      final categoryName = exp['category_name'];
      // --- PERBAIKAN DI SINI ---
      final amount = num.parse(exp['amount'].toString()).toDouble();
      categoryTotals[categoryName] = (categoryTotals[categoryName] ?? 0) + amount;
    }
    
    final totalExpense = categoryTotals.values.fold(0.0, (sum, item) => sum + item);
    int colorIndex = 0;
    final colors = [Colors.blue, Colors.red, Colors.green, Colors.orange, Colors.purple, Colors.teal];

    return categoryTotals.entries.map((entry) {
      final isTouched = categoryTotals.keys.toList().indexOf(entry.key) == touchedIndex;
      final fontSize = isTouched ? 16.0 : 12.0;
      final radius = isTouched ? 60.0 : 50.0;
      final percentage = (entry.value / totalExpense * 100).toStringAsFixed(1);
      
      final section = PieChartSectionData(
        color: colors[colorIndex % colors.length],
        value: entry.value,
        title: '${entry.key}\n($percentage%)',
        radius: radius,
        titleStyle: TextStyle(
            fontSize: fontSize,
            fontWeight: FontWeight.bold,
            color: const Color(0xffffffff),
            shadows: const [Shadow(color: Colors.black, blurRadius: 2)]),
      );
      colorIndex++;
      return section;
    }).toList();
  }

  Widget _buildBarChart(TransactionProvider provider) {
    final Map<String, Map<String, double>> monthlyData = {};
    for (var t in provider.transactions) {
      final date = DateTime.parse(t['transaction_date']);
      final monthKey = DateFormat('yyyy-MM').format(date);
      // --- PERBAIKAN DI SINI ---
      final amount = num.parse(t['amount'].toString()).toDouble();
      
      monthlyData.putIfAbsent(monthKey, () => {'income': 0, 'expense': 0});
      
      if (t['category_type'] == 'income') {
        monthlyData[monthKey]!['income'] = (monthlyData[monthKey]!['income'] ?? 0) + amount;
      } else {
        monthlyData[monthKey]!['expense'] = (monthlyData[monthKey]!['expense'] ?? 0) + amount;
      }
    }

    final sortedKeys = monthlyData.keys.toList()..sort();
    
    return BarChart(
      BarChartData(
        barGroups: List.generate(sortedKeys.length, (index) {
          final key = sortedKeys[index];
          final data = monthlyData[key]!;
          return BarChartGroupData(
            x: index,
            barRods: [
              BarChartRodData(toY: data['income']!, color: Colors.green, width: 15),
              BarChartRodData(toY: data['expense']!, color: Colors.red, width: 15),
            ],
          );
        }),
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (double value, TitleMeta meta) {
                if (value.toInt() >= sortedKeys.length) return const SizedBox.shrink();
                final monthAbbr = DateFormat('MMM').format(DateTime.parse('${sortedKeys[value.toInt()]}-01'));
                return SideTitleWidget(axisSide: meta.axisSide, child: Text(monthAbbr));
              },
              reservedSize: 38,
            ),
          ),
          leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
      ),
    );
  }
}