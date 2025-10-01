import 'package:animated_bottom_navigation_bar/animated_bottom_navigation_bar.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:skydash_financial_tracker/src/features/dashboard/dashboard_screen.dart';
import 'package:skydash_financial_tracker/src/features/reports/reports_screen.dart';
import 'package:skydash_financial_tracker/src/features/settings/settings_screen.dart';
import 'package:skydash_financial_tracker/src/features/transactions/add_transaction_screen.dart';
import 'package:skydash_financial_tracker/src/features/transactions/transaction_history_screen.dart';
import 'package:skydash_financial_tracker/src/providers/transaction_provider.dart';

const skydashnetGradient = LinearGradient(
  colors: [Color(0xFF00C6FF), Color(0xFF0072FF)],
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
);

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _bottomNavIndex = 0;
  final List<Widget> _pages = [
    const DashboardScreen(),
    TransactionHistoryScreen(),
    const ReportsScreen(),
    const SettingsScreen(),
  ];
  final List<IconData> _iconList = [
    Icons.dashboard_outlined,
    Icons.history_outlined,
    Icons.pie_chart_outline,
    Icons.settings_outlined,
  ];

  void _navigateToAddTransaction() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AddTransactionScreen()),
    );
    if (result == true && mounted) {
      Provider.of<TransactionProvider>(context, listen: false).fetchTransactionsAndSummary();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: _pages[_bottomNavIndex],
      floatingActionButton: FloatingActionButton(
        onPressed: _navigateToAddTransaction,
        shape: const CircleBorder(),
        child: Ink(
          decoration: const BoxDecoration(
            gradient: skydashnetGradient,
            shape: BoxShape.circle,
          ),
          child: const Center(
            child: Icon(Icons.add, color: Colors.white),
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: AnimatedBottomNavigationBar(
        icons: _iconList,
        activeIndex: _bottomNavIndex,
        gapLocation: GapLocation.center,
        notchSmoothness: NotchSmoothness.softEdge,
        leftCornerRadius: 32,
        rightCornerRadius: 32,
        onTap: (index) => setState(() => _bottomNavIndex = index),
        activeColor: theme.colorScheme.primary,
        inactiveColor: Colors.grey,
        backgroundColor: theme.bottomAppBarTheme.color,
      ),
    );
  }
}