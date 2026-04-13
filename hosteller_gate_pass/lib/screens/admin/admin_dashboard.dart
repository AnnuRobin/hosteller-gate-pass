import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/staff_auth_provider.dart';
import '../../services/admin_service.dart';
import '../../models/user_model.dart';
import '../../utils/constants.dart';
import '../shared/common_settings_screen.dart';
import 'departments_screen.dart';
import 'edit_user_screen.dart';
import 'audit_logs_screen.dart';
import 'bulk_create_class_screen.dart';
import 'create_user_screen.dart';
import 'advisors_list_page.dart';
import 'hods_list_page.dart';
import 'user_details_page.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({Key? key}) : super(key: key);

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  final AdminService _adminService = AdminService();
  List<UserModel> _allUsers = [];
  bool _isLoading = false;
  int _selectedIndex = 0;
  String _searchQuery = '';
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  String _getGreeting() {
    var hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning';
    if (hour < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  String _getFormattedDate() {
    final now = DateTime.now();
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December'
    ];
    const weekdays = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday'
    ];
    return '${months[now.month - 1]} ${now.day}, ${now.year}\n${weekdays[now.weekday - 1]}, it\'s ${now.hour}:${now.minute.toString().padLeft(2, '0')} today';
  }

  Future<void> _loadUsers() async {
    setState(() => _isLoading = true);
    try {
      final users = await _adminService.getAllUsers();
      setState(() {
        _allUsers = users;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading users: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _onNavItemSelected(int index) {
    if (_scaffoldKey.currentState?.isDrawerOpen ?? false) {
      Navigator.pop(context);
    }
    if (index == 4) {
      _handleLogout();
      return;
    }
    setState(() {
      _selectedIndex = index;
    });
  }

  Future<void> _handleLogout() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final staffAuthProvider =
        Provider.of<StaffAuthProvider>(context, listen: false);
    if (staffAuthProvider.isAuthenticated) {
      await staffAuthProvider.logout();
    } else {
      await authProvider.signOut();
    }
    if (mounted) {
      Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 800;

    final staffProvider =
        Provider.of<StaffAuthProvider>(context, listen: false);
    final authProvider = Provider.of<AuthProvider>(context);
    final fullName = authProvider.userProfile?.fullName ??
        staffProvider.userProfile?.fullName ??
        'Admin';
    final initials = fullName.isNotEmpty ? fullName[0].toUpperCase() : 'A';

    final studentCount = _allUsers.where((u) => u.role == 'student').length;
    final wardenCount = _allUsers.where((u) => u.role == 'warden').length;
    final hodCount = _allUsers.where((u) => u.role == 'hod').length;
    final advisorCount = _allUsers.where((u) => u.role == 'advisor').length;

    return PopScope(
      canPop: _selectedIndex == 0,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        setState(() => _selectedIndex = 0);
      },
      child: Scaffold(
        key: _scaffoldKey,
        backgroundColor: Colors.grey[50],
        drawer: _buildDrawer(context, fullName, initials),
        body: Column(
          children: [
            if (_selectedIndex == 0)
              _buildHeader(
                context,
                fullName,
                studentCount: studentCount,
                wardenCount: wardenCount,
                hodCount: hodCount,
                advisorCount: advisorCount,
              )
            else
              _buildSecondaryTopBar(context, isMobile),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _buildMainContent(isMobile),
            ),
          ],
        ),
      ),
    );
  }

  // ─────────────────── HEADER (overview only) ───────────────────────────────
  Widget _buildHeader(
    BuildContext context,
    String fullName, {
    int studentCount = 0,
    int wardenCount = 0,
    int hodCount = 0,
    int advisorCount = 0,
  }) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppConstants.primaryColor,
        borderRadius:
            const BorderRadius.vertical(bottom: Radius.circular(30)),
      ),
      padding: EdgeInsets.fromLTRB(
          24, MediaQuery.of(context).padding.top + 24, 14, 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Top row: date | menu ──────────────────────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 12.0),
                child: Text(
                  _getFormattedDate().split('\n')[0],
                  style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.8),
                      fontSize: 14),
                ),
              ),
              Builder(
                builder: (ctx) => IconButton(
                  icon: const Icon(Icons.menu, color: Colors.white),
                  onPressed: () => Scaffold.of(ctx).openDrawer(),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // ── Greeting ──────────────────────────────────────────────────
          Text(
            '${_getGreeting()},',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.9),
              fontSize: 34,
              fontWeight: FontWeight.w400,
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            fullName,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 30,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 32),
          // ── Stat row ──────────────────────────────────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildStatItem(
                'Students',
                studentCount.toString(),
                () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const DepartmentsScreen(),
                  ),
                ),
              ),
              Container(
                  height: 40,
                  width: 1,
                  color: Colors.white.withValues(alpha: 0.2)),
              _buildStatItem(
                'Wardens',
                wardenCount.toString(),
                () => setState(() => _selectedIndex = 2),
              ),
              Container(
                  height: 40,
                  width: 1,
                  color: Colors.white.withValues(alpha: 0.2)),
              _buildStatItem(
                'HODs',
                hodCount.toString(),
                () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const HodsListPage()),
                ).then((_) => _loadUsers()),
              ),
              Container(
                  height: 40,
                  width: 1,
                  color: Colors.white.withValues(alpha: 0.2)),
              _buildStatItem(
                'Advisors',
                advisorCount.toString(),
                () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const AdvisorsListPage()),
                ).then((_) => _loadUsers()),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Column(
          children: [
            Text(
              value == '0' ? '0' : value.padLeft(2, '0'),
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Color(0xFF8DE8C4),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Colors.white.withValues(alpha: 0.9),
                height: 1.2,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─────────────────── SECONDARY TOP BAR (non-overview tabs) ────────────────
  Widget _buildSecondaryTopBar(BuildContext context, bool isMobile) {
    final titles = ['', 'Departments', 'Hostels', 'Settings'];
    final title =
        _selectedIndex < titles.length ? titles[_selectedIndex] : '';
    return Container(
      color: AppConstants.primaryColor,
      padding: EdgeInsets.fromLTRB(
          4, MediaQuery.of(context).padding.top + 4, 16, 8),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => setState(() => _selectedIndex = 0),
          ),
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────── DRAWER ───────────────────────────────────────────────
  Widget _buildDrawer(
      BuildContext context, String fullName, String initials) {
    return Drawer(
      child: Container(
        color: AppConstants.primaryColor,
        child: Column(
          children: [
            // ── Header ────────────────────────────────────────────────
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(20, 60, 20, 28),
              color: AppConstants.primaryColor,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: Colors.white.withValues(alpha: 0.25),
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
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      'Administrator',
                      style:
                          TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            // ── Nav items ─────────────────────────────────────────────
            _drawerItem(
                icon: Icons.grid_view_outlined,
                activeIcon: Icons.grid_view,
                label: 'Dashboard',
                index: 0),
            _drawerItem(
                icon: Icons.menu_book_outlined,
                activeIcon: Icons.menu_book,
                label: 'Department',
                index: 1),
            _drawerItem(
                icon: Icons.apartment_outlined,
                activeIcon: Icons.apartment,
                label: 'Hostel',
                index: 2),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Divider(
                  height: 24,
                  color: Colors.white.withValues(alpha: 0.15)),
            ),
            _drawerItem(
                icon: Icons.settings_outlined,
                activeIcon: Icons.settings,
                label: 'Settings',
                index: 3),
            const Spacer(),
            // ── Logout ────────────────────────────────────────────────
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              child: ListTile(
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.logout,
                      color: Colors.white70, size: 20),
                ),
                title: const Text(
                  'Logout',
                  style: TextStyle(
                      color: Colors.white70,
                      fontWeight: FontWeight.w600),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _handleLogout();
                },
              ),
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
      padding: const EdgeInsets.only(right: 20, bottom: 4),
      child: ListTile(
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
            topRight: Radius.circular(30),
            bottomRight: Radius.circular(30),
          ),
        ),
        tileColor: isSelected
            ? Colors.white.withValues(alpha: 0.15)
            : Colors.transparent,
        leading: Icon(
          isSelected ? activeIcon : icon,
          color: isSelected
              ? const Color(0xFF8DE8C4)
              : Colors.white70,
          size: 22,
        ),
        title: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.white70,
            fontWeight:
                isSelected ? FontWeight.w700 : FontWeight.w400,
            fontSize: 15,
            letterSpacing: 0.3,
          ),
        ),
        onTap: () {
          setState(() => _selectedIndex = index);
          Navigator.pop(context);
        },
      ),
    );
  }

  Widget _buildMainContent(bool isMobile) {
    switch (_selectedIndex) {
      case 0:
        return _buildOverviewTab(isMobile);
      case 1:
        return const DepartmentsScreen(embedded: true);
      case 2:
        return _buildHostelsTab();
      case 3:
        return _buildSettingsTab();
      default:
        return _buildOverviewTab(isMobile);
    }
  }

  Widget _buildHostelsTab() {
    final List<String> activeHostels = _allUsers
        .map((u) => u.hostelName)
        .where((h) => h != null && h.isNotEmpty)
        .cast<String>()
        .toSet()
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(24, 24, 24, 8),
          child: Text(
            'Active Hostels Network',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1E3A8A),
            ),
          ),
        ),
        Expanded(
          child: activeHostels.isEmpty
              ? const Center(
                  child: Text("No hostels found in user database",
                      style: TextStyle(color: Colors.grey)))
              : ListView.builder(
                  padding: const EdgeInsets.all(24),
                  itemCount: activeHostels.length,
                  itemBuilder: (context, index) {
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(color: Colors.grey.shade200),
                      ),
                      child: ListTile(
                        onTap: () {
                          final hostelName = activeHostels[index];
                          final hostelWardens = _allUsers
                              .where((u) =>
                                  u.role == 'warden' &&
                                  u.hostelName != null &&
                                  u.hostelName!.toLowerCase().trim() ==
                                      hostelName.toLowerCase().trim())
                              .toList();

                          if (hostelWardens.isNotEmpty) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => UserDetailsPage(user: hostelWardens.first),
                              ),
                            );
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('No warden assigned to $hostelName'),
                                backgroundColor: AppConstants.warningColor,
                              ),
                            );
                          }
                        },
                        contentPadding: const EdgeInsets.all(16),
                        leading: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppConstants.primaryColor
                                .withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(Icons.apartment,
                              color: AppConstants.primaryColor),
                        ),
                        title: Text(
                          activeHostels[index],
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        trailing:
                            const Icon(Icons.chevron_right, color: Colors.grey),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildSettingsTab() {
    return const CommonSettingsScreen();
  }


  Widget _buildOverviewTab(bool isMobile) {
    return RefreshIndicator(
      onRefresh: _loadUsers,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
        children: [
          // ── Search bar ────────────────────────────────────────────────
          Container(
            height: 48,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                const SizedBox(width: 14),
                Icon(Icons.search, color: Colors.grey[400], size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    onChanged: (value) =>
                        setState(() => _searchQuery = value),
                    decoration: InputDecoration(
                      hintText: 'Search users...',
                      hintStyle:
                          TextStyle(color: Colors.grey[400], fontSize: 14),
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding:
                          const EdgeInsets.symmetric(vertical: 14),
                    ),
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.black87,
                    ),
                  ),
                ),
                if (_searchQuery.isNotEmpty)
                  IconButton(
                    icon: Icon(Icons.clear,
                        color: Colors.grey[400], size: 18),
                    onPressed: () =>
                        setState(() => _searchQuery = ''),
                  ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // ── Quick Actions ─────────────────────────────────────────────
          if (_searchQuery.isEmpty) ...[
            const Text(
              'Quick Actions',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 16),
            // Two square cards: Audit Logs | Bulk Create Class
            Row(
              children: [
                Expanded(
                  child: _buildQuickActionCard(
                    label: 'Audit Logs',
                    subLabel: 'View system logs',
                    icon: Icons.history,
                    iconBg: const Color(0xFFEEF2FF),
                    iconColor: AppConstants.primaryColor,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const AuditLogsScreen()),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildQuickActionCard(
                    label: 'Bulk Create Class',
                    subLabel: 'Create classes at once',
                    icon: Icons.group_add,
                    iconBg: const Color(0xFFECFDF5),
                    iconColor: AppConstants.successColor,
                    onTap: () async {
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const BulkCreateClassScreen(),
                        ),
                      );
                      if (result == true) _loadUsers();
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Wide banner: Add New User
            _buildAddUserBanner(() {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const CreateUserScreen(),
                ),
              ).then((result) {
                if (result == true) _loadUsers();
              });
            }),
            const SizedBox(height: 32),
          ],

          // ── Users list section ────────────────────────────────────────
          Text(
            _searchQuery.isEmpty
                ? 'All Registered Users'
                : 'Results for "$_searchQuery"',
            style: TextStyle(
              fontSize: _searchQuery.isEmpty ? 18 : 14,
              fontWeight: FontWeight.bold,
              color:
                  _searchQuery.isEmpty ? Colors.black87 : Colors.grey[600],
            ),
          ),
          const SizedBox(height: 16),
          _buildUsersTable(),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required String title,
    required String count,
    required IconData icon,
    required Color color,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(height: 16),
            Text(
              count,
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.black54,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Square card-style quick action (like Morning / Night scene reference)
  Widget _buildQuickActionCard({
    required String label,
    required String subLabel,
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: iconBg,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: iconColor, size: 22),
            ),
            const SizedBox(height: 16),
            Text(
              label,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subLabel,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Wide banner-style quick action (like "You created 8 scenes" reference)
  Widget _buildAddUserBanner(VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF7ED),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.person_add,
                  color: Color(0xFFF59E0B), size: 22),
            ),
            const SizedBox(width: 16),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Add New User',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Register a student, warden or staff',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: Colors.grey.shade400,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUsersTable() {
    var displayUsers = _allUsers;
    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      displayUsers = _allUsers
          .where((u) =>
              u.fullName.toLowerCase().contains(q) ||
              u.email.toLowerCase().contains(q) ||
              u.role.toLowerCase().contains(q))
          .toList();
    }

    if (displayUsers.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(32),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child:
            const Text('No users found.', style: TextStyle(color: Colors.grey)),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: displayUsers.length > 5 && _searchQuery.isEmpty
              ? 5
              : displayUsers.length, // Preview just top 5 unless searching
          separatorBuilder: (context, index) => const Divider(height: 1),
          itemBuilder: (context, index) {
            final user = displayUsers[index];
            return ListTile(
              onTap: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => UserDetailsPage(user: user)),
                );
                if (result == true) _loadUsers();
              },
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              leading: CircleAvatar(
                backgroundColor:
                    _getRoleColor(user.role).withValues(alpha: 0.1),
                child: Text(
                  user.fullName[0].toUpperCase(),
                  style: TextStyle(
                    color: _getRoleColor(user.role),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              title: Text(
                user.fullName,
                style:
                    const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
              ),
              subtitle: Text(
                user.email,
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
              trailing: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: _getRoleColor(user.role).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  user.role.toUpperCase(),
                  style: TextStyle(
                    color: _getRoleColor(user.role),
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildUserList(List<UserModel> users, String title) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1E3A8A),
            ),
          ),
        ),
        Expanded(
          child: users.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.people_outline,
                          size: 80, color: Colors.grey[300]),
                      const SizedBox(height: 16),
                      Text(
                        'No users found in this category',
                        style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadUsers,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(24),
                    itemCount: users.length,
                    itemBuilder: (context, index) {
                      final user = users[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(color: Colors.grey.shade200),
                        ),
                        child: ListTile(
                          onTap: () async {
                            final result = await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => UserDetailsPage(user: user),
                              ),
                            );
                            if (result == true) _loadUsers();
                          },
                          contentPadding: const EdgeInsets.all(16),
                          leading: CircleAvatar(
                            backgroundColor: _getRoleColor(user.role),
                            child: Text(
                              user.fullName[0].toUpperCase(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          title: Text(
                            user.fullName,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(user.email),
                          trailing: const Icon(Icons.chevron_right, color: Colors.grey),
                        ),
                      );
                    },
                  ),
                ),
        ),
      ],
    );
  }

  Color _getRoleColor(String role) {
    switch (role) {
      case 'student':
        return AppConstants.primaryColor;
      case 'warden':
        return AppConstants.successColor;
      case 'hod':
        return AppConstants.warningColor;
      case 'advisor':
        return AppConstants.secondaryColor;
      case 'admin':
        return AppConstants.errorColor;
      default:
        return Colors.grey;
    }
  }
}
