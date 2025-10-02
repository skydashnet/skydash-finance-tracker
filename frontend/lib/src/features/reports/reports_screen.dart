import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:open_filex/open_filex.dart';
import 'package:skydash_financial_tracker/src/providers/transaction_provider.dart';
import 'package:skydash_financial_tracker/src/services/export_service.dart';
import 'package:skydash_financial_tracker/src/utils/category_icon_mapper.dart';
import 'package:skydash_financial_tracker/src/utils/notification_helper.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  int touchedIndex = -1;

  String _formatCurrency(num amount) {
    final format = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
    return format.format(amount);
  }

  void _showExportDialog(BuildContext context) {
    final ExportService exportService = ExportService();
    DateTime selectedDate = DateTime.now();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Ekspor Laporan'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Pilih format ekspor untuk bulan ini:'),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
          ElevatedButton.icon(
            icon: const Icon(Icons.description),
            label: const Text('CSV'),
            onPressed: () async {
              Navigator.pop(ctx);
              final path = await exportService.exportToCsv(selectedDate.year, selectedDate.month);
              if (path != null && mounted) {
                NotificationHelper.showSuccess(context, title: 'Berhasil', message: 'Laporan CSV disimpan di folder Download.');
                OpenFilex.open(path);
              } else if (mounted) {
                 NotificationHelper.showError(context, title: 'Gagal', message: 'Gagal mengekspor laporan.');
              }
            },
          ),
          ElevatedButton.icon(
            icon: const Icon(Icons.picture_as_pdf),
            label: const Text('PDF'),
            onPressed: () async {
              Navigator.pop(ctx);
              final path = await exportService.exportToPdf(selectedDate.year, selectedDate.month);
              if (path == 'no_data' && mounted) {
                NotificationHelper.showError(context, title: 'Info', message: 'Tidak ada data transaksi untuk diekspor.');
              } else if (path != null && mounted) {
                NotificationHelper.showSuccess(context, title: 'Berhasil', message: 'Laporan PDF disimpan di folder Download.');
                OpenFilex.open(path);
              } else if (mounted) {
                 NotificationHelper.showError(context, title: 'Gagal', message: 'Gagal mengekspor laporan.');
              }
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Laporan Keuangan'),
        actions: [
          IconButton(
            icon: const Icon(Icons.ios_share),
            onPressed: () => _showExportDialog(context),
          )
        ],
      ),
      body: Consumer<TransactionProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading && provider.transactions.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }
          if (provider.transactions.isEmpty) {
            return const Center(child: Text('Tidak ada data untuk ditampilkan.'));
          }
          final expenses = provider.transactions.where((t) => t['category_type'] == 'expense');
          final Map<String, double> categoryTotals = {};
          if (expenses.isNotEmpty) {
            for (var exp in expenses) {
              final categoryName = exp['category_name'];
              final amount = num.parse(exp['amount'].toString()).toDouble();
              categoryTotals[categoryName] = (categoryTotals[categoryName] ?? 0) + amount;
            }
          }
          final totalExpense = categoryTotals.values.fold(0.0, (sum, item) => sum + item);

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text('Ringkasan Pengeluaran', style: theme.textTheme.titleLarge),
              Text('Berdasarkan kategori bulan ini', style: theme.textTheme.bodyMedium),
              const SizedBox(height: 20),
              SizedBox(
                height: 200,
                child: _buildPieChart(provider, categoryTotals, totalExpense),
              ),
              const SizedBox(height: 40),

              Text('Tren Pemasukan vs Pengeluaran', style: theme.textTheme.titleLarge),
              Text('Beberapa bulan terakhir', style: theme.textTheme.bodyMedium),
              const SizedBox(height: 20),
              SizedBox(
                height: 250,
                child: _buildBarChart(provider),
              ),
              const SizedBox(height: 40),
              Text('Rincian Pengeluaran per Kategori', style: theme.textTheme.titleLarge),
              const SizedBox(height: 16),
              _buildCategoryAnalysis(context, categoryTotals, totalExpense),
            ],
          );
        },
      ),
    );
  }

  Widget _buildPieChart(TransactionProvider provider, Map<String, double> categoryTotals, double totalExpense) {
    if (categoryTotals.isEmpty) {
      return const Center(child: Text('Tidak ada data pengeluaran bulan ini.'));
    }

    int colorIndex = 0;
    final colors = [
      Colors.blue, Colors.red, Colors.green, Colors.orange, 
      Colors.purple, Colors.teal, Colors.pink, Colors.indigo, Colors.brown
    ];

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
        sections: categoryTotals.entries.map((entry) {
            final isTouched = categoryTotals.keys.toList().indexOf(entry.key) == touchedIndex;
            final fontSize = isTouched ? 14.0 : 10.0;
            final radius = isTouched ? 60.0 : 50.0;
            final percentage = (entry.value / totalExpense * 100).toStringAsFixed(0);
            
            final section = PieChartSectionData(
              color: colors[colorIndex % colors.length],
              value: entry.value,
              title: '$percentage%',
              radius: radius,
              titleStyle: TextStyle(
                  fontSize: fontSize,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xffffffff),
                  shadows: const [Shadow(color: Colors.black, blurRadius: 2)]),
            );
            colorIndex++;
            return section;
          }).toList(),
      ),
    );
  }

  Widget _buildBarChart(TransactionProvider provider) {
    final Map<String, Map<String, double>> monthlyData = {};
    for (var t in provider.transactions) {
      final date = DateTime.parse(t['transaction_date']);
      final monthKey = DateFormat('yyyy-MM').format(date);
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
        barTouchData: BarTouchData(
          touchTooltipData: BarTouchTooltipData(
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              String label;
              if (rod.color == Colors.green) {
                label = 'Pemasukan';
              } else {
                label = 'Pengeluaran';
              }
              return BarTooltipItem(
                '$label\n',
                TextStyle(color: Theme.of(context).colorScheme.onPrimary, fontWeight: FontWeight.bold),
                children: <TextSpan>[
                  TextSpan(
                    text: _formatCurrency(rod.toY),
                    style: TextStyle(color: Theme.of(context).colorScheme.onPrimary),
                  ),
                ],
              );
            },
          ),
        ),
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (double value, TitleMeta meta) {
                if (value.toInt() >= sortedKeys.length) return const SizedBox.shrink();
                final monthAbbr = DateFormat('MMM').format(DateTime.parse('${sortedKeys[value.toInt()]}-01'));
                return SideTitleWidget(axisSide: meta.axisSide, child: Text(monthAbbr, style: const TextStyle(fontSize: 10)));
              },
              reservedSize: 38,
            ),
          ),
          leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: false),
        gridData: const FlGridData(show: false),
        barGroups: List.generate(sortedKeys.length, (index) {
          final key = sortedKeys[index];
          final data = monthlyData[key]!;
          return BarChartGroupData(
            x: index,
            barRods: [
              BarChartRodData(toY: data['income']!, color: Colors.green, width: 15, borderRadius: const BorderRadius.all(Radius.circular(4))),
              BarChartRodData(toY: data['expense']!, color: Colors.red, width: 15, borderRadius: const BorderRadius.all(Radius.circular(4))),
            ],
          );
        }),
      ),
    );
  }
  Widget _buildCategoryAnalysis(BuildContext context, Map<String, double> categoryTotals, double totalExpense) {
    if (categoryTotals.isEmpty) {
      return const Card(child: Padding(padding: EdgeInsets.all(16), child: Text('Tidak ada data pengeluaran untuk dianalisis.')));
    }

    final sortedCategories = categoryTotals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
      
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: sortedCategories.map((entry) {
          final categoryName = entry.key;
          final amount = entry.value;
          final percentage = totalExpense > 0 ? (amount / totalExpense) : 0.0;
          final visual = CategoryIconMapper.getVisual(categoryName);

          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
            child: Column(
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: visual.color.withOpacity(0.15),
                      child: Icon(visual.icon, color: visual.color, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(child: Text(categoryName)),
                    Text(_formatCurrency(amount), style: const TextStyle(fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: LinearProgressIndicator(
                        value: percentage,
                        borderRadius: BorderRadius.circular(5),
                        minHeight: 6,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text('${(percentage * 100).toStringAsFixed(1)}%', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                  ],
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}