import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:skydash_financial_tracker/src/features/dashboard/dashboard_screen.dart';
import 'package:skydash_financial_tracker/src/features/goals/goals_screen.dart';
import 'package:skydash_financial_tracker/src/features/reports/reports_screen.dart';
import 'package:skydash_financial_tracker/src/features/settings/settings_screen.dart';
import 'package:skydash_financial_tracker/src/features/transactions/add_transaction_screen.dart';
import 'package:skydash_financial_tracker/src/features/transactions/transaction_history_screen.dart';
import 'package:skydash_financial_tracker/src/providers/transaction_provider.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  static final List<Widget> _pages = <Widget>[
    const DashboardScreen(),
    TransactionHistoryScreen(),
    const GoalsScreen(),
    const ReportsScreen(),
    const SettingsScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }
  
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
    return Scaffold(
      body: _pages.elementAt(_selectedIndex),
      floatingActionButton: FloatingActionButton(
        onPressed: _navigateToAddTransaction,
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
        shape: const CircleBorder(),
        child: const Icon(Icons.add),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        notchMargin: 8.0,
        child: BottomNavigationBar(
          type: BottomNavigationBarType.fixed,
          items: const <BottomNavigationBarItem>[
            BottomNavigationBarItem(icon: Icon(Icons.dashboard_outlined), label: 'Dashboard'),
            BottomNavigationBarItem(icon: Icon(Icons.history_outlined), label: 'History'),
            BottomNavigationBarItem(icon: Icon(Icons.flag_outlined), label: ''),
            BottomNavigationBarItem(icon: Icon(Icons.pie_chart_outline), label: 'Reports'),
            BottomNavigationBarItem(icon: Icon(Icons.settings_outlined), label: 'Settings'),
          ],
          currentIndex: _selectedIndex,
          selectedItemColor: Theme.of(context).colorScheme.primary,
          unselectedItemColor: Colors.grey,
          onTap: _onItemTapped,
          backgroundColor: Colors.transparent,
          elevation: 0,
          showSelectedLabels: true,
          showUnselectedLabels: true,
        ),
      ),
    );
  }
}