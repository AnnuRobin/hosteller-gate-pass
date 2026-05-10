import 'package:flutter/material.dart';
import '../../models/user_model.dart';
import '../../models/department_model.dart';
import '../../services/admin_service.dart';
import '../../services/department_service.dart';
import '../../utils/constants.dart';
import 'user_details_page.dart';

class AdvisorsListPage extends StatefulWidget {
  const AdvisorsListPage({Key? key}) : super(key: key);

  @override
  State<AdvisorsListPage> createState() => _AdvisorsListPageState();
}

class _AdvisorsListPageState extends State<AdvisorsListPage> {
  final AdminService _adminService = AdminService();
  final DepartmentService _departmentService = DepartmentService();
  
  List<UserModel> _allAdvisors = [];
  List<DepartmentModel> _departments = [];
  bool _isLoading = false;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final results = await Future.wait([
        _adminService.getUsersByRole('advisor'),
        _departmentService.getAllDepartments(),
      ]);
      
      if (mounted) {
        setState(() {
          _allAdvisors = results[0] as List<UserModel>;
          _departments = results[1] as List<DepartmentModel>;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading data: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  List<UserModel> get _filteredUsers {
    // Filter users who have a department and match the search query
    return _allAdvisors.where((u) {
      if (u.departmentId == null) return false; // Filter out "Others"
      
      final dept = _departments.firstWhere(
        (d) => d.id == u.departmentId, 
        orElse: () => DepartmentModel(id: '', name: '', createdAt: DateTime.now())
      );
      
      if (dept.id.isEmpty) return false;

      final query = _searchQuery.toLowerCase();
      return u.fullName.toLowerCase().contains(query) ||
             dept.name.toLowerCase().contains(query) ||
             (dept.departmentCode?.toLowerCase().contains(query) ?? false);
    }).toList();
  }

  Map<String, List<UserModel>> get _groupedUsers {
    final filtered = _filteredUsers;
    final Map<String, List<UserModel>> groups = {};

    for (var user in filtered) {
      final deptId = user.departmentId!;
      if (!groups.containsKey(deptId)) {
        groups[deptId] = [];
      }
      groups[deptId]!.add(user);
    }

    // Sort users within groups alphabetically by name
    for (var key in groups.keys) {
      groups[key]!.sort((a, b) => a.fullName.toLowerCase().compareTo(b.fullName.toLowerCase()));
    }

    return groups;
  }

  List<String> get _sortedGroupKeys {
    final grouped = _groupedUsers;
    final keys = grouped.keys.toList();

    keys.sort((a, b) {
      final deptA = _departments.firstWhere((d) => d.id == a);
      final deptB = _departments.firstWhere((d) => d.id == b);
      
      // Sort by code primarily, fallback to name
      final valA = deptA.departmentCode ?? deptA.name;
      final valB = deptB.departmentCode ?? deptB.name;
      
      return valA.toLowerCase().compareTo(valB.toLowerCase());
    });

    return keys;
  }

  @override
  Widget build(BuildContext context) {
    final grouped = _groupedUsers;
    final sortedKeys = _sortedGroupKeys;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: Column(
        children: [
          // Header Section (Matched with Admin Home)
          _buildHeader(context),

          // Search Section
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
            child: _buildSearchBar(),
          ),

          // List Section
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : sortedKeys.isEmpty
                    ? _buildEmptyState()
                    : RefreshIndicator(
                        onRefresh: _loadData,
                        child: ListView.builder(
                          padding: const EdgeInsets.all(20),
                          itemCount: sortedKeys.length,
                          itemBuilder: (context, index) {
                            final deptId = sortedKeys[index];
                            final dept = _departments.firstWhere((d) => d.id == deptId);
                            final users = grouped[deptId]!;
                            
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildDepartmentHeader(dept),
                                const SizedBox(height: 12),
                                ...users.map((user) => _buildUserTile(user)),
                                const SizedBox(height: 24),
                              ],
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppConstants.primaryColor,
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(30)),
      ),
      padding: EdgeInsets.fromLTRB(24, MediaQuery.of(context).padding.top + 20, 24, 30),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => Navigator.pop(context),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
              const SizedBox(width: 16),
              const Text(
                'Advisors',
                style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              if (!_isLoading)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${_filteredUsers.length} Total',
                    style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      height: 50,
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
      child: TextField(
        onChanged: (v) => setState(() => _searchQuery = v),
        decoration: InputDecoration(
          hintText: 'Search by name, dept, or code...',
          hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
          prefixIcon: Icon(Icons.search, color: Colors.grey[400], size: 20),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 15),
          suffixIcon: _searchQuery.isNotEmpty 
            ? IconButton(
                icon: const Icon(Icons.close, size: 18), 
                onPressed: () => setState(() => _searchQuery = '')
              ) 
            : null,
        ),
      ),
    );
  }

  Widget _buildDepartmentHeader(DepartmentModel dept) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppConstants.primaryColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              dept.departmentCode ?? '??',
              style: TextStyle(color: AppConstants.primaryColor, fontWeight: FontWeight.bold, fontSize: 13),
            ),
          ),
          const SizedBox(width: 10),
          Text(
            dept.name,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.black87),
          ),
        ],
      ),
    );
  }

  Widget _buildUserTile(UserModel user) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: ListTile(
        onTap: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => UserDetailsPage(user: user)),
          );
          if (result == true) _loadData();
        },
        leading: CircleAvatar(
          backgroundColor: const Color(0xFF8B5CF6).withValues(alpha: 0.1),
          child: Text(
            user.fullName[0].toUpperCase(),
            style: const TextStyle(color: Color(0xFF8B5CF6), fontWeight: FontWeight.bold),
          ),
        ),
        title: Text(
          user.fullName,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
        ),
        subtitle: Text(
          user.email,
          style: TextStyle(color: Colors.grey[600], fontSize: 12),
        ),
        trailing: const Icon(Icons.chevron_right, color: Colors.grey, size: 18),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.person_search_outlined, size: 60, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            _searchQuery.isEmpty ? 'No Advisors found' : 'No matching Advisors',
            style: TextStyle(color: Colors.grey[500], fontSize: 16),
          ),
        ],
      ),
    );
  }
}
