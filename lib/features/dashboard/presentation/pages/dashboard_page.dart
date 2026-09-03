import 'package:flutter/material.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../leave/presentation/pages/leave_requests_page.dart';
import '../../../profile/presentation/pages/profile_page.dart';
import 'approver_dashboard_page.dart';

class DashboardPage extends StatefulWidget {
  final int initialTabIndex;
  const DashboardPage({super.key, this.initialTabIndex = 0});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialTabIndex;
  }

  void _onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> tabs = [
      ApproverDashboardPage(
        onNavigateToRequests: () => _onTabTapped(1),
        onNavigateToProfile: () => _onTabTapped(2),
      ),
      LeaveRequestsPage(
        isTab: true,
        onNavigateHome: () => _onTabTapped(0),
        onNavigateProfile: () => _onTabTapped(2),
      ),
      const ProfilePage(isTab: true),
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FC),
      body: IndexedStack(
        index: _currentIndex,
        children: tabs,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(
            top: BorderSide(color: AppColors.border.withAlpha(100), width: 1),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(8),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: _onTabTapped,
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.white,
          selectedItemColor: const Color(0xFF083E2F),
          unselectedItemColor: const Color(0xFF64748B),
          selectedLabelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
          unselectedLabelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
          elevation: 0,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              activeIcon: Icon(Icons.home_rounded),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.assignment_outlined),
              activeIcon: Icon(Icons.assignment_rounded),
              label: 'Requests',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline_rounded),
              activeIcon: Icon(Icons.person_rounded),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }
}
