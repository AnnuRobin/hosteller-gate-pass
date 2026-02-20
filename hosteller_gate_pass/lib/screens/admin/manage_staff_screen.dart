import 'package:flutter/material.dart';
import '../../models/user_model.dart';
import '../../services/admin_service.dart';
import '../../utils/constants.dart';
import 'create_user_screen.dart';
import 'edit_user_screen.dart';

class ManageStaffScreen extends StatefulWidget {
  const ManageStaffScreen({Key? key}) : super(key: key);

  @override
  State<ManageStaffScreen> createState() => _ManageStaffScreenState();
}

class _ManageStaffScreenState extends State<ManageStaffScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final AdminService _adminService = AdminService();
  final TextEditingController _searchController = TextEditingController();

  List<UserModel> _allStaff = [];
  bool _isLoading = false;
  String _searchQuery = '';

  final List<String> _tabRoles = ['all', 'hod', 'warden', 'advisor'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadStaff();
    _searchController.addListener(() {
      setState(() => _searchQuery = _searchController.text.toLowerCase());
    });
  }

  Future<void> _loadStaff() async {
    setState(() => _isLoading = true);
    try {
      final users = await _adminService.getAllUsers();
      setState(() {
        _allStaff = users
            .where((u) =>
                u.role == 'hod' ||
                u.role == 'warden' ||
                u.role == 'advisor')
            .toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading staff: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  List<UserModel> _getFilteredStaff(String role) {
    List<UserModel> list =
        role == 'all' ? _allStaff : _allStaff.where((u) => u.role == role).toList();

    if (_searchQuery.isNotEmpty) {
      list = list
          .where((u) =>
              u.fullName.toLowerCase().contains(_searchQuery) ||
              u.email.toLowerCase().contains(_searchQuery))
          .toList();
    }
    return list;
  }

  Color _getRoleColor(String role) {
    switch (role) {
      case 'hod':
        return AppConstants.warningColor;
      case 'warden':
        return AppConstants.successColor;
      case 'advisor':
        return AppConstants.secondaryColor;
      default:
        return Colors.grey;
    }
  }

  IconData _getRoleIcon(String role) {
    switch (role) {
      case 'hod':
        return Icons.business_center;
      case 'warden':
        return Icons.security;
      case 'advisor':
        return Icons.person_pin;
      default:
        return Icons.person;
    }
  }

  String _getRoleLabel(String role) {
    switch (role) {
      case 'all':
        return 'All Staff';
      case 'hod':
        return 'HODs';
      case 'warden':
        return 'Wardens';
      case 'advisor':
        return 'Advisors';
      default:
        return role;
    }
  }

  String _getSingularLabel(String role) {
    switch (role) {
      case 'hod':
        return 'HOD';
      case 'warden':
        return 'Warden';
      case 'advisor':
        return 'Advisor';
      default:
        return 'Staff';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Column(
          children: [
            // Search bar
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search by name or email...',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _searchController.clear();
                          },
                        )
                      : null,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
              ),
            ),

            // Role Tabs
            TabBar(
              controller: _tabController,
              isScrollable: true,
              labelColor: AppConstants.primaryColor,
              unselectedLabelColor: Colors.grey,
              indicatorColor: AppConstants.primaryColor,
              tabs: _tabRoles
                  .map((role) => Tab(text: _getRoleLabel(role)))
                  .toList(),
            ),

            // Tab Views
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : TabBarView(
                      controller: _tabController,
                      children: _tabRoles
                          .map((role) => _buildStaffList(
                                _getFilteredStaff(role),
                                role,
                              ))
                          .toList(),
                    ),
            ),
          ],
        ),

        // Add Staff FAB
        Positioned(
          bottom: 16,
          right: 16,
          child: FloatingActionButton.extended(
            heroTag: 'addStaffFab',
            onPressed: () {
              final activeRole = _tabRoles[_tabController.index];
              _openAddStaff(activeRole);
            },
            icon: const Icon(Icons.person_add),
            label: Text(
              _tabController.index == 0
                  ? 'Add Staff'
                  : 'Add ${_getSingularLabel(_tabRoles[_tabController.index])}',
            ),
            backgroundColor: AppConstants.primaryColor,
          ),
        ),
      ],
    );
  }

  Widget _buildStaffList(List<UserModel> staff, String role) {
    if (staff.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _getRoleIcon(role == 'all' ? 'advisor' : role),
              size: 80,
              color: Colors.grey[300],
            ),
            const SizedBox(height: 16),
            Text(
              _searchQuery.isNotEmpty
                  ? 'No results for "$_searchQuery"'
                  : 'No ${_getRoleLabel(role)} found',
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
            if (_searchQuery.isEmpty) ...[
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: () => _openAddStaff(role),
                icon: const Icon(Icons.person_add),
                label: Text('Add ${_getRoleLabel(role)}'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppConstants.primaryColor,
                ),
              ),
            ],
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadStaff,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: staff.length,
        itemBuilder: (context, index) {
          final user = staff[index];
          final roleColor = _getRoleColor(user.role);
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Avatar
                  CircleAvatar(
                    backgroundColor: roleColor,
                    radius: 26,
                    child: Text(
                      user.fullName[0].toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),

                  // Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user.fullName,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          user.email,
                          style: TextStyle(
                              fontSize: 13, color: Colors.grey[600]),
                        ),
                        if (user.phone != null && user.phone!.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            user.phone!,
                            style: TextStyle(
                                fontSize: 13, color: Colors.grey[600]),
                          ),
                        ],
                        const SizedBox(height: 8),
                        // Role badge
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: roleColor.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(_getRoleIcon(user.role),
                                  size: 14, color: roleColor),
                              const SizedBox(width: 4),
                              Text(
                                user.role.toUpperCase(),
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: roleColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Actions
                  PopupMenuButton<String>(
                    onSelected: (value) async {
                      if (value == 'edit') {
                        final result = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => EditUserScreen(user: user),
                          ),
                        );
                        if (result == true) _loadStaff();
                      } else if (value == 'reset_password') {
                        _showResetPasswordDialog(user);
                      } else if (value == 'delete') {
                        _confirmDeleteUser(user);
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(Icons.edit, size: 20),
                            SizedBox(width: 10),
                            Text('Edit'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'reset_password',
                        child: Row(
                          children: [
                            Icon(Icons.lock_reset, size: 20,
                                color: Colors.orange),
                            SizedBox(width: 10),
                            Text('Reset Password'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete, size: 20, color: Colors.red),
                            SizedBox(width: 10),
                            Text('Delete',
                                style: TextStyle(color: Colors.red)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _openAddStaff(String role) async {
    // Determine the initial role for the CreateUserScreen
    // 'all' tab → default to 'hod', otherwise use the specific role
    final initialRole = (role == 'all') ? 'hod' : role;
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CreateUserScreen(initialRole: initialRole),
      ),
    );
    if (result == true) _loadStaff();
  }

  Future<void> _confirmDeleteUser(UserModel user) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Staff Member'),
        content: Text(
            'Are you sure you want to delete ${user.fullName} (${user.role.toUpperCase()})?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
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
          _loadStaff();
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

  Future<void> _showResetPasswordDialog(UserModel user) async {
    final passwordController = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset Password'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Reset password for ${user.fullName}?'),
            const SizedBox(height: 16),
            TextField(
              controller: passwordController,
              decoration: const InputDecoration(
                labelText: 'New Password',
                hintText: 'Minimum 8 characters',
                border: OutlineInputBorder(),
              ),
              obscureText: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (passwordController.text.length >= 8) {
                Navigator.pop(context, true);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Password must be at least 8 characters'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
                backgroundColor: AppConstants.warningColor),
            child: const Text('Reset'),
          ),
        ],
      ),
    );

    if (confirmed == true && passwordController.text.isNotEmpty) {
      try {
        await _adminService.resetUserPassword(user.id, passwordController.text);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Password reset successfully!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error resetting password: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
    passwordController.dispose();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }
}
