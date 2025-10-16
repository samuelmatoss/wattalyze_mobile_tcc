
import 'package:flutter/material.dart';
import 'alert_rules_screen.dart';
import 'active_alerts_screen.dart';
import 'alert_history_screen.dart';
import 'alert_navegation.dart';

class AlertMainScreen extends StatefulWidget {
  final String token;

  const AlertMainScreen({Key? key, required this.token}) : super(key: key);

  @override
  _AlertMainScreenState createState() => _AlertMainScreenState();
}

class _AlertMainScreenState extends State<AlertMainScreen> {
  int _currentIndex = 0;
  final PageController _pageController = PageController();

  final List<Widget> _screens = [
    const AlertRulesScreen(),
    const ActiveAlertsScreen(),
    const AlertHistoryScreen(),
  ];

  void _onNavTap(int index) {
    setState(() {
      _currentIndex = index;
    });
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFF5F7FA), Color(0xFFC3CFE2)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Navigation
              AlertNavigation(
                currentIndex: _currentIndex,
                onTap: _onNavTap,
              ),
              
              // Page Content
              Expanded(
                child: PageView(
                  controller: _pageController,
                  onPageChanged: (index) {
                    setState(() {
                      _currentIndex = index;
                    });
                  },
                  children: _screens,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }
}
