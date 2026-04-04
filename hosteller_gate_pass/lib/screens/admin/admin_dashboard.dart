import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/staff_auth_provider.dart';
import '../../services/admin_service.dart';
import '../../models/user_model.dart';
import '../../utils/constants.dart';
import 'departments_screen.dart';
import 'create_user_screen.dart';
import 'edit_user_screen.dart';
import 'audit_logs_screen.dart';
import 'bulk_create_class_screen.dart';

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
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    const weekdays = [
      'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'
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
    if (Scaffold.maybeOf(context)?.isDrawerOpen ?? false) {
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
    final staffAuthProvider = Provider.of<StaffAuthProvider>(context, listen: false);
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
    final size = MediaQuery.of(context).size;
    final isMobile = size.width < 800;

    Widget body = Row(
      children: [
        if (!isMobile) _buildSideNavigation(),
        Expanded(
          child: Container(
            color: const Color(0xFFF3F6F9), // Light background for the content
            child: Column(
              children: [
                _buildTopBar(isMobile),
                Expanded(
                  child: _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : _buildMainContent(isMobile),
                ),
              ],
            ),
          ),
        ),
      ],
    );

    return Scaffold(
      backgroundColor: Colors.white,
      drawer: isMobile ? Drawer(child: _buildSideNavigationContent()) : null,
      body: body,
    );
  }

  Widget _buildTopBar(bool isMobile) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      color: const Color(0xFFF8F9FA),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (isMobile)
                Builder(
                  builder: (context) => IconButton(
                    icon: const Icon(Icons.menu, color: Colors.black87),
                    onPressed: () {
                      Scaffold.of(context).openDrawer();
                    },
                  ),
                ),
              // Search bar matching reference UI
              Expanded(
                flex: 2,
                child: Container(
                  height: 44,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.search, color: Color(0xFF5B61DB)),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          onChanged: (value) {
                            setState(() {
                              _searchQuery = value;
                            });
                          },
                          decoration: const InputDecoration(
                            hintText: 'Search',
                            hintStyle: TextStyle(color: Colors.black38, fontSize: 14),
                            border: InputBorder.none,
                            isDense: true,
                            contentPadding: EdgeInsets.zero,
                          ),
                          style: const TextStyle(fontSize: 14),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (!isMobile) const Spacer(flex: 1),
              if (!isMobile)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      _getFormattedDate().split('\n')[0],
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    Text(
                      _getFormattedDate().split('\n')[1],
                      style: const TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                  ],
                ),
              const SizedBox(width: 16),
              const Icon(Icons.notifications_none, color: Color(0xFF5B61DB)),
              const SizedBox(width: 16),
              Consumer<AuthProvider>(
                builder: (context, authProvider, child) {
                  final staffProvider = Provider.of<StaffAuthProvider>(context, listen: false);
                  final userName = authProvider.userProfile?.fullName ?? 
                                   staffProvider.userProfile?.fullName ?? 'James';
                  return CircleAvatar(
                    radius: 18,
                    backgroundColor: Colors.grey.shade300,
                    child: Text(
                      userName.isNotEmpty ? userName[0].toUpperCase() : 'J',
                      style: const TextStyle(
                        color: Colors.black54,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 24),
          // Greeting under the top bar
          Consumer<AuthProvider>(
            builder: (context, authProvider, child) {
              final staffProvider = Provider.of<StaffAuthProvider>(context, listen: false);
              final userName = authProvider.userProfile?.fullName ?? 
                               staffProvider.userProfile?.fullName ?? 'James';
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _getGreeting(),
                    style: const TextStyle(color: Colors.black54, fontSize: 16),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Welcome, $userName!',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  // Wraps the side navigation content in a static width container for desktop
  Widget _buildSideNavigation() {
    return Container(
      width: 260,
      color: Colors.white,
      child: _buildSideNavigationContent(),
    );
  }

  // The actual content of the side navigation
  Widget _buildSideNavigationContent() {
    return Container(
      color: const Color(0xFF5B61DB), // Muted purple-blue matching reference
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 40),
          // Top Logo area
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            alignment: Alignment.centerLeft,
            child: Row(
              children: [
                const Text(
                  'MyCollege', // Changing logo to match aesthetic
                  style: TextStyle(
                    fontSize: 24,
                    fontStyle: FontStyle.italic,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 48),
          // Navigation Items
          _buildNavItem(icon: Icons.grid_view, title: 'Dashboard', index: 0),
          _buildNavItem(icon: Icons.menu_book, title: 'Department', index: 1),
          _buildNavItem(icon: Icons.apartment, title: 'Hostel', index: 2),
          _buildNavItem(icon: Icons.settings_outlined, title: 'Settings', index: 3),
          const Spacer(),
          _buildNavItem(icon: Icons.logout, title: 'Logout', index: 4),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildNavItem({required IconData icon, required String title, required int index}) {
    final isSelected = _selectedIndex == index;
    return InkWell(
      onTap: () => _onNavItemSelected(index),
      child: Container(
        margin: const EdgeInsets.only(right: 24, bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white.withValues(alpha: 0.15) : Colors.transparent,
          borderRadius: const BorderRadius.only(
            topRight: Radius.circular(30),
            bottomRight: Radius.circular(30),
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: Colors.white,
              size: 22,
            ),
            const SizedBox(width: 16),
            Text(
              title,
              style: TextStyle(
                color: Colors.white,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                fontSize: 15,
                letterSpacing: 0.3,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMainContent(bool isMobile) {
    switch (_selectedIndex) {
      case 0:
        return _buildOverviewTab(isMobile);
      case 1:
        return const DepartmentsScreen();
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
              ? const Center(child: Text("No hostels found in user database", style: TextStyle(color: Colors.grey)))
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
                        contentPadding: const EdgeInsets.all(16),
                        leading: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppConstants.primaryColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(Icons.apartment, color: AppConstants.primaryColor),
                        ),
                        title: Text(
                          activeHostels[index],
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        trailing: const Icon(Icons.chevron_right, color: Colors.grey),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildSettingsTab() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Settings',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1E3A8A),
            ),
          ),
          const SizedBox(height: 24),
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: Colors.grey.shade200),
            ),
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.palette_outlined),
                  title: const Text('App Theme'),
                  trailing: const Text('Light', style: TextStyle(color: Colors.grey)),
                  onTap: () {},
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.language),
                  title: const Text('Language'),
                  trailing: const Text('English', style: TextStyle(color: Colors.grey)),
                  onTap: () {},
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.notifications_outlined),
                  title: const Text('Push Notifications'),
                  trailing: Switch(value: true, onChanged: (v) {}),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOverviewTab(bool isMobile) {
    final studentCount = _allUsers.where((u) => u.role == 'student').length;
    final wardenCount = _allUsers.where((u) => u.role == 'warden').length;
    final hodCount = _allUsers.where((u) => u.role == 'hod').length;
    final advisorCount = _allUsers.where((u) => u.role == 'advisor').length;

    return RefreshIndicator(
      onRefresh: _loadUsers,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Overview',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E3A8A),
              ),
            ),
            const SizedBox(height: 24),
            if (isMobile)
              Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _buildStatCard(
                          title: 'Students',
                          count: studentCount.toString(),
                          icon: Icons.school,
                          color: AppConstants.primaryColor,
                          onTap: () => setState(() => _searchQuery = 'student'),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildStatCard(
                          title: 'Wardens',
                          count: wardenCount.toString(),
                          icon: Icons.security,
                          color: AppConstants.successColor,
                          onTap: () => setState(() => _searchQuery = 'warden'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _buildStatCard(
                          title: 'HODs',
                          count: hodCount.toString(),
                          icon: Icons.account_balance,
                          color: AppConstants.warningColor,
                          onTap: () => setState(() => _searchQuery = 'hod'),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildStatCard(
                          title: 'Advisors',
                          count: advisorCount.toString(),
                          icon: Icons.person_pin,
                          color: AppConstants.secondaryColor,
                          onTap: () => setState(() => _searchQuery = 'advisor'),
                        ),
                      ),
                    ],
                  ),
                ],
              )
            else
              Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      title: 'Students',
                      count: studentCount.toString(),
                      icon: Icons.school,
                      color: AppConstants.primaryColor,
                      onTap: () => setState(() => _searchQuery = 'student'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildStatCard(
                      title: 'Wardens',
                      count: wardenCount.toString(),
                      icon: Icons.security,
                      color: AppConstants.successColor,
                      onTap: () => setState(() => _searchQuery = 'warden'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildStatCard(
                      title: 'HODs',
                      count: hodCount.toString(),
                      icon: Icons.account_balance,
                      color: AppConstants.warningColor,
                      onTap: () => setState(() => _searchQuery = 'hod'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildStatCard(
                      title: 'Advisors',
                      count: advisorCount.toString(),
                      icon: Icons.person_pin,
                      color: AppConstants.secondaryColor,
                      onTap: () => setState(() => _searchQuery = 'advisor'),
                    ),
                  ),
                ],
              ),
            const SizedBox(height: 32),
            const Text(
              'Quick Actions',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 16,
              runSpacing: 16,
              children: [
                _buildActionChip('Create Users', Icons.group_add, () async {
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const BulkCreateClassScreen(),
                    ),
                  );
                  if (result == true) _loadUsers();
                }),
                _buildActionChip('Audit Logs', Icons.history, () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const AuditLogsScreen()),
                  );
                }),
              ],
            ),
            const SizedBox(height: 32),
            const Text(
              'All Registered Users',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 16),
            _buildUsersTable(),
          ],
        ),
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

  Widget _buildActionChip(String label, IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: AppConstants.primaryColor),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
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
      displayUsers = _allUsers.where((u) => 
        u.fullName.toLowerCase().contains(q) || 
        u.email.toLowerCase().contains(q) ||
        u.role.toLowerCase().contains(q)
      ).toList();
    }

    if (displayUsers.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(32),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Text('No users found.', style: TextStyle(color: Colors.grey)),
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
          itemCount: displayUsers.length > 5 && _searchQuery.isEmpty ? 5 : displayUsers.length, // Preview just top 5 unless searching
          separatorBuilder: (context, index) => const Divider(height: 1),
          itemBuilder: (context, index) {
            final user = displayUsers[index];
            return ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              leading: CircleAvatar(
                backgroundColor: _getRoleColor(user.role).withValues(alpha: 0.1),
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
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
              ),
              subtitle: Text(
                user.email,
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
              trailing: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
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
                      Icon(Icons.people_outline, size: 80, color: Colors.grey[300]),
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
                          trailing: PopupMenuButton(
                            itemBuilder: (context) => [
                              const PopupMenuItem(
                                value: 'edit',
                                child: Row(
                                  children: [
                                    Icon(Icons.edit, size: 20),
                                    SizedBox(width: 8),
                                    Text('Edit'),
                                  ],
                                ),
                              ),
                              const PopupMenuItem(
                                value: 'delete',
                                child: Row(
                                  children: [
                                    Icon(Icons.delete, size: 20, color: Colors.red),
                                    SizedBox(width: 8),
                                    Text('Delete', style: TextStyle(color: Colors.red)),
                                  ],
                                ),
                              ),
                            ],
                            onSelected: (value) async {
                              if (value == 'edit') {
                                final result = await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => EditUserScreen(user: user),
                                  ),
                                );
                                if (result == true) {
                                  _loadUsers();
                                }
                              } else if (value == 'delete') {
                                _confirmDeleteUser(user);
                              }
                            },
                          ),
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

  Future<void> _confirmDeleteUser(UserModel user) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete User'),
        content: Text('Are you sure you want to delete ${user.fullName}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _adminService.deleteUser(user.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${user.fullName} deleted successfully'),
              backgroundColor: AppConstants.successColor,
            ),
          );
          _loadUsers();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error deleting user: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }
}
