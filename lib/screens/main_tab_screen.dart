import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/auth_service.dart';
import '../screens/dashboard_screen.dart';
import '../screens/environments/index_screen.dart';
import '../screens/devices/index_screen.dart';
import '../screens/alerts/alert_main_screen.dart';
import '../screens/reports/index_screen.dart';
import '../screens/settings/index_screen.dart';


class MainTabScreen extends StatefulWidget {
  final String token;

  const MainTabScreen({Key? key, required this.token}) : super(key: key);

  @override
  State<MainTabScreen> createState() => _MainTabScreenState();
}

class _MainTabScreenState extends State<MainTabScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  late AnimationController _fabAnimationController;
  late Animation<double> _fabAnimation;
  int _currentIndex = 0;
  bool _hasNotifications = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 6, vsync: this);
    _fabAnimationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _fabAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _fabAnimationController, curve: Curves.easeInOut),
    );

    _tabController.addListener(() {
      setState(() {
        _currentIndex = _tabController.index;
      });

      if (_currentIndex == 2) {
        _fabAnimationController.forward();
      } else {
        _fabAnimationController.reverse();
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _fabAnimationController.dispose();
    super.dispose();
  }

  Future<void> _handleLogout() async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(30),
                ),
                child: const Icon(
                  Icons.exit_to_app_rounded,
                  color: Colors.red,
                  size: 30,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Sair do App',
                style: GoogleFonts.roboto(
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                  color: const Color(0xFF2c3e50),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Tem certeza que deseja sair do aplicativo?',
                textAlign: TextAlign.center,
                style: GoogleFonts.roboto(
                  color: Colors.grey[600],
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(color: Colors.grey[300]!),
                        ),
                      ),
                      child: Text(
                        'Cancelar',
                        style: GoogleFonts.roboto(
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.of(context).pop(true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        'Sair',
                        style: GoogleFonts.roboto(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    if (shouldLogout == true) {
      try {
        final authService = AuthService();
        await authService.logout();

        if (mounted) {
          Navigator.of(context).pushReplacementNamed('/login');
        }
      } catch (e) {
        throw Exception(e);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      extendBody: true, 
      appBar: _buildCustomAppBar(),
      body: Stack(
        children: [
          // ConteÃºdo principal
          TabBarView(
            controller: _tabController,
            children: [
              DashboardScreen(token: widget.token),
              EnvironmentsScreen(token: widget.token),
              DeviceIndexScreen(token: widget.token),
              AlertMainScreen(token: widget.token),
              ReportsScreen(token: widget.token),
              SettingsScreen(token: widget.token),
            ],
          ),
          // Menu flutuante
          Positioned(
            bottom: 30,
            left: 20,
            right: 20,
            child: _buildBottomNavigationBar(),
          ),
        ],
      ),
      
    );
  }

  PreferredSizeWidget _buildCustomAppBar() {
    return AppBar(
      automaticallyImplyLeading: false,
      toolbarHeight: 70,
      backgroundColor: Colors.white,
      elevation: 2,
      shadowColor: Colors.black.withOpacity(0.1),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF27ae60), Color(0xFF2ecc71)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.flash_on_rounded,
              color: Colors.white,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            'Wattalyze',
            style: GoogleFonts.roboto(
              fontWeight: FontWeight.bold,
              color: const Color(0xFF2c3e50),
              fontSize: 22,
            ),
          ),
        ],
      ),
      actions: [
        Stack(
          children: [
            IconButton(
              onPressed: () {
                _tabController.animateTo(3);
                setState(() {
                  _hasNotifications = false;
                });
              },
              icon: const Icon(
                Icons.notifications_outlined,
                color: Color(0xFF2c3e50),
              ),
            ),
            if (_hasNotifications)
              Positioned(
                right: 11,
                top: 11,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: Color(0xFF27ae60),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
          ],
        ),
        PopupMenuButton<String>(
          onSelected: (value) {
            switch (value) {
              case 'profile':
                _tabController.animateTo(5);
                break;
              case 'logout':
                _handleLogout();
                break;
            }
          },
          itemBuilder: (context) => [
            PopupMenuItem(
              value: 'profile',
              child: Row(
                children: [
                  const Icon(Icons.person_outline, color: Color(0xFF2c3e50)),
                  const SizedBox(width: 12),
                  Text(
                    'Perfil',
                    style: GoogleFonts.roboto(color: const Color(0xFF2c3e50)),
                  ),
                ],
              ),
            ),
            const PopupMenuDivider(),
            PopupMenuItem(
              value: 'logout',
              child: Row(
                children: [
                  const Icon(Icons.exit_to_app, color: Colors.red),
                  const SizedBox(width: 12),
                  Text(
                    'Sair',
                    style: GoogleFonts.roboto(color: Colors.red),
                  ),
                ],
              ),
            ),
          ],
          icon: const Icon(
            Icons.account_circle,
            color: Color(0xFF2c3e50),
            size: 28,
          ),
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildBottomNavigationBar() {
    return Container(
      height: 70,
      decoration: BoxDecoration(
        color: const Color(0xFF2c3e50),
        borderRadius: BorderRadius.circular(35),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 20,
            spreadRadius: 0,
            offset: const Offset(0, 10),
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 40,
            spreadRadius: 0,
            offset: const Offset(0, 20),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(35),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildNavIcon(Icons.dashboard_outlined, Icons.dashboard_rounded, 0),
            _buildNavIcon(Icons.business_outlined, Icons.business_rounded, 1),
            _buildNavIcon(Icons.devices_outlined, Icons.devices_rounded, 2),
            _buildNavIcon(Icons.warning_amber_outlined, Icons.warning_amber_rounded, 3),
            _buildNavIcon(Icons.analytics_outlined, Icons.analytics_rounded, 4),
            _buildNavIcon(Icons.settings_outlined, Icons.settings_rounded, 5),
          ],
        ),
      ),
    );
  }

  Widget _buildNavIcon(IconData outlinedIcon, IconData filledIcon, int index) {
    final isSelected = _currentIndex == index;

    return GestureDetector(
      onTap: () => _tabController.animateTo(index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF27ae60).withOpacity(0.2)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(
          isSelected ? filledIcon : outlinedIcon,
          size: 28,
          color: isSelected ? const Color(0xFF27ae60) : Colors.white70,
        ),
      ),
    );
  }
}