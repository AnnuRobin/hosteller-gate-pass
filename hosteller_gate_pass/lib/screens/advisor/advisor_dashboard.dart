import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/gate_pass_provider.dart';
import '../../utils/constants.dart';
import '../../widgets/request_card.dart';
import '../shared/common_settings_screen.dart';
import 'manage_students_screen.dart';
import 'add_student_screen.dart';
import 'bulk_upload_students_screen.dart';
import '../shared/student_gate_pass_history_screen.dart';

class AdvisorDashboard extends StatefulWidget {
  const AdvisorDashboard({Key? key}) : super(key: key);

  @override
  State<AdvisorDashboard> createState() => _AdvisorDashboardState();
}

class _AdvisorDashboardState extends State<AdvisorDashboard> {
  // 0 = Home, 1 = Pending, 2 = Active, 3 = Completed, 4 = Manage Students, 5 = Add Student, 6 = Bulk Add, 7 = Settings
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    // Defer data load until after the first frame to avoid
    // setState() called during build errors.
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadData());
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final gatePassProvider =
        Provider.of<GatePassProvider>(context, listen: false);

    if (authProvider.userProfile?.classId != null) {
      await gatePassProvider.loadAdvisorRequests(
        classId: authProvider.userProfile!.classId!,
        departmentId: authProvider.userProfile!.departmentId!,
      );
    }
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning';
    if (hour < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final gatePassProvider = Provider.of<GatePassProvider>(context);

    final pendingRequests = gatePassProvider.requests
        .where((r) => r.advisorStatus == 'pending')
        .toList();

    final activeRequests = gatePassProvider.requests
        .where((r) => r.advisorStatus == 'approved')
        .toList();

    final completedRequests = gatePassProvider.requests
        .where((r) =>
            r.advisorStatus == 'rejected' || r.advisorStatus == 'completed')
        .toList();

    final fullName = authProvider.userProfile?.fullName ?? 'Advisor';
    final initials = fullName.isNotEmpty ? fullName[0].toUpperCase() : 'A';

    Widget body;
    switch (_selectedIndex) {
      case 1:
        body = _buildListPage(
          title: 'Pending Requests',
          requests: pendingRequests,
          type: 'pending',
          icon: Icons.pending_actions,
          isLoading: gatePassProvider.isLoading,
        );
        break;
      case 2:
        body = _buildListPage(
          title: 'Active Requests',
          requests: activeRequests,
          type: 'active',
          icon: Icons.verified_outlined,
          isLoading: gatePassProvider.isLoading,
        );
        break;
      case 3:
        body = _buildListPage(
          title: 'Completed Requests',
          requests: completedRequests,
          type: 'completed',
          icon: Icons.check_circle_outline,
          isLoading: gatePassProvider.isLoading,
        );
        break;
      case 4:
        body = const ManageStudentsScreen();
        break;
      case 5:
        body = AddStudentScreen(
          onStudentCreated: () => setState(() => _selectedIndex = 0),
        );
        break;
      case 6:
        body = const BulkUploadStudentsScreen();
        break;
      case 7:
        body = const CommonSettingsScreen();
        break;
      default:
        body = _buildHomePage(
          pendingCount: pendingRequests.length,
          activeCount: activeRequests.length,
          completedCount: completedRequests.length,
          isLoading: gatePassProvider.isLoading,
        );
    }

    return PopScope(
      // Allow natural pop (exits app) only when on Home; otherwise go to Home.
      canPop: _selectedIndex == 0,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        // On a sub-section ΓÇö go back to Home
        setState(() => _selectedIndex = 0);
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F7FA),
        drawer: _buildDrawer(context, authProvider, fullName, initials),
        body: SafeArea(
          child: Column(
            children: [
              if (_selectedIndex == 0)
                _buildHeader(context, fullName, initials,
                    pendingCount: pendingRequests.length),
              Expanded(child: body),
            ],
          ),
        ),
      ),
    );
  }

  // ΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇ TOP HEADER ΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇ

  Widget _buildHeader(BuildContext context, String fullName, String initials,
      {int pendingCount = 0}) {
    final hasPending = pendingCount > 0;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Hamburger menu
              Builder(
                builder: (ctx) => GestureDetector(
                  onTap: () => Scaffold.of(ctx).openDrawer(),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0F4FF),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.menu,
                        color: AppConstants.primaryColor, size: 22),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Search bar
              Expanded(
                child: Container(
                  height: 42,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0F4FF),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const TextField(
                    decoration: InputDecoration(
                      hintText: 'Search requests...',
                      hintStyle:
                          TextStyle(color: Color(0xFF94A3B8), fontSize: 14),
                      prefixIcon: Icon(Icons.search,
                          color: Color(0xFF94A3B8), size: 20),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Notification bell ΓÇö red dot only when pending passes exist
              GestureDetector(
                onTap: () {
                  // Navigate to Pending Requests section
                  setState(() => _selectedIndex = 1);
                },
                child: Stack(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF0F4FF),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.notifications_outlined,
                          color: AppConstants.primaryColor, size: 22),
                    ),
                    if (hasPending)
                      Positioned(
                        right: 6,
                        top: 6,
                        child: Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: Color(0xFFEF4444),
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              // Avatar
              CircleAvatar(
                radius: 20,
                backgroundColor: AppConstants.primaryColor,
                child: Text(
                  initials,
                  style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16),
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),
          // Greeting
          Text(
            _getGreeting(),
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF64748B),
              fontStyle: FontStyle.italic,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            'Welcome, $fullName!',
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1E3A8A),
            ),
          ),
        ],
      ),
    );
  }

  // ΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇ DRAWER ΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇ

  Widget _buildDrawer(BuildContext context, AuthProvider authProvider,
      String fullName, String initials) {
    return Drawer(
      child: Container(
        color: Colors.white,
        child: Column(
          children: [
            // Drawer header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(20, 50, 20, 24),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppConstants.primaryColor,
                    AppConstants.secondaryColor,
                  ],
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: Colors.white.withOpacity(0.3),
                    child: Text(
                      initials,
                      style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 24),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    fullName,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      'Advisor',
                      style: TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            // Nav items
            _drawerItem(
              icon: Icons.home_outlined,
              activeIcon: Icons.home,
              label: 'Home',
              index: 0,
            ),
            _drawerItem(
              icon: Icons.pending_actions_outlined,
              activeIcon: Icons.pending_actions,
              label: 'Pending Request',
              index: 1,
            ),
            _drawerItem(
              icon: Icons.verified_outlined,
              activeIcon: Icons.verified,
              label: 'Active Request',
              index: 2,
            ),
            _drawerItem(
              icon: Icons.check_circle_outline,
              activeIcon: Icons.check_circle,
              label: 'Completed Request',
              index: 3,
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Divider(height: 24),
            ),
            _drawerItem(
              icon: Icons.people_outlined,
              activeIcon: Icons.people,
              label: 'Manage Students',
              index: 4,
            ),
            _drawerItem(
              icon: Icons.person_add_outlined,
              activeIcon: Icons.person_add,
              label: 'Add a Student',
              index: 5,
            ),
            _drawerItem(
              icon: Icons.upload_file_outlined,
              activeIcon: Icons.upload_file,
              label: 'Bulk Add',
              index: 6,
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Divider(height: 24),
            ),
            _drawerItem(
              icon: Icons.settings_outlined,
              activeIcon: Icons.settings,
              label: 'Settings',
              index: 7,
            ),
            const Spacer(),
            // Logout
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEE2E2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.logout,
                    color: Color(0xFFEF4444), size: 20),
              ),
              title: const Text(
                'Logout',
                style: TextStyle(
                    color: Color(0xFFEF4444), fontWeight: FontWeight.w600),
              ),
              onTap: () async {
                Navigator.pop(context);
                await authProvider.signOut();
              },
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _drawerItem({
    required IconData icon,
    required IconData activeIcon,
    required String label,
    required int index,
  }) {
    final isSelected = _selectedIndex == index;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      child: ListTile(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        tileColor: isSelected
            ? AppConstants.primaryColor.withOpacity(0.08)
            : Colors.transparent,
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: isSelected
                ? AppConstants.primaryColor.withOpacity(0.15)
                : const Color(0xFFF0F4FF),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            isSelected ? activeIcon : icon,
            color: isSelected
                ? AppConstants.primaryColor
                : const Color(0xFF64748B),
            size: 20,
          ),
        ),
        title: Text(
          label,
          style: TextStyle(
            color: isSelected
                ? AppConstants.primaryColor
                : const Color(0xFF334155),
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            fontSize: 14,
          ),
        ),
        onTap: () {
          setState(() => _selectedIndex = index);
          Navigator.pop(context);
        },
      ),
    );
  }

  // ΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇ HOME PAGE ΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇ

  Widget _buildHomePage({
    required int pendingCount,
    required int activeCount,
    required int completedCount,
    required bool isLoading,
  }) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'Overview',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppConstants.primaryColor,
              fontStyle: FontStyle.italic,
            ),
          ),
          const SizedBox(height: 16),
          _buildSummaryCard(
            label: 'Pending Requests',
            count: pendingCount,
            icon: Icons.pending_actions,
            color: const Color(0xFFF59E0B),
            bgColor: const Color(0xFFFFFBEB),
            onTap: () => setState(() => _selectedIndex = 1),
          ),
          const SizedBox(height: 14),
          _buildSummaryCard(
            label: 'Active Requests',
            count: activeCount,
            icon: Icons.verified_outlined,
            color: const Color(0xFF10B981),
            bgColor: const Color(0xFFECFDF5),
            onTap: () => setState(() => _selectedIndex = 2),
          ),
          const SizedBox(height: 14),
          _buildSummaryCard(
            label: 'Completed Requests',
            count: completedCount,
            icon: Icons.check_circle_outline,
            color: AppConstants.primaryColor,
            bgColor: const Color(0xFFEFF6FF),
            onTap: () => setState(() => _selectedIndex = 3),
          ),
          const SizedBox(height: 24),
          const Text(
            'Quick Actions',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF334155),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _quickActionButton(
                  icon: Icons.pending_actions,
                  label: 'Review Pending',
                  onTap: () => setState(() => _selectedIndex = 1),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _quickActionButton(
                  icon: Icons.refresh,
                  label: 'Refresh Data',
                  onTap: _loadData,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard({
    required String label,
    required int count,
    required IconData icon,
    required Color color,
    required Color bgColor,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$count',
                  style: TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF64748B),
                  ),
                ),
              ],
            ),
            const Spacer(),
            Icon(Icons.arrow_forward_ios,
                size: 16, color: Colors.grey.shade400),
          ],
        ),
      ),
    );
  }

  Widget _quickActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return OutlinedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 18, color: AppConstants.primaryColor),
      label: Text(
        label,
        style: const TextStyle(color: AppConstants.primaryColor, fontSize: 13),
      ),
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        side: const BorderSide(color: AppConstants.primaryColor),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  // ΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇ LIST PAGE ΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇ

  Widget _buildListPage({
    required String title,
    required List requests,
    required String type,
    required IconData icon,
    required bool isLoading,
  }) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (requests.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 80, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text(
              'No $title found',
              style: TextStyle(fontSize: 18, color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      color: const Color(0xFF2563EB),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: requests.length,
        itemBuilder: (context, index) {
          final request = requests[index];
          return RequestCard(
            request: request,
            isAdvisor: true,
            onActionComplete: _loadData,
          );
        },
      ),
    );
  }
}
