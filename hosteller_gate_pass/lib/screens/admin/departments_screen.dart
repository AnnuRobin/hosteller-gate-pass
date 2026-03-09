import 'package:flutter/material.dart';
import '../../services/department_service.dart';
import '../../models/department_model.dart';
import '../../models/user_model.dart';
import '../../utils/constants.dart';

class DepartmentsScreen extends StatefulWidget {
  const DepartmentsScreen({Key? key}) : super(key: key);

  @override
  State<DepartmentsScreen> createState() => _DepartmentsScreenState();
}

class _DepartmentsScreenState extends State<DepartmentsScreen> {
  final DepartmentService _departmentService = DepartmentService();
  List<Map<String, dynamic>> _departmentsWithCounts = [];
  bool _isLoading = false;
  DepartmentModel? _selectedDepartment;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadDepartments();
    });
  }

  Future<void> _loadDepartments() async {
    setState(() => _isLoading = true);
    try {
      final data = await _departmentService.getDepartmentsWithCounts();
      setState(() {
        _departmentsWithCounts = data;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading departments: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_selectedDepartment != null) {
      return _buildDepartmentDetailView(_selectedDepartment!);
    }

    return Scaffold(
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _departmentsWithCounts.isEmpty
              ? _buildEmptyState()
              : RefreshIndicator(
                  onRefresh: _loadDepartments,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _departmentsWithCounts.length,
                    itemBuilder: (context, index) {
                      final data = _departmentsWithCounts[index];
                      final department = data['department'] as DepartmentModel;
                      final studentCount = data['student_count'] as int;

                      return _buildDepartmentCard(
                        department,
                        studentCount,
                      );
                    },
                  ),
                ),
    );
  }

  Widget _buildDepartmentDetailView(DepartmentModel department) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => setState(() => _selectedDepartment = null),
          ),
          title: Text(department.name),
          bottom: TabBar(
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            indicatorColor: Colors.white,
            tabs: const [
              Tab(text: 'Faculties'),
              Tab(text: 'Students'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildFacultyList(department.id),
            _buildStudentList(department.id),
          ],
        ),
      ),
    );
  }

  Widget _buildFacultyList(String departmentId) {
    return _SearchableMemberList(
      future: _departmentService.getStaffByDepartment(departmentId),
      searchHint: 'Search faculty by name or role...',
      emptyMessage: 'No faculty found in this department',
      subtitleBuilder: (member) => '${member.roleDisplayName} • ${member.email}',
      iconColor: AppConstants.secondaryColor,
    );
  }

  Widget _buildStudentList(String departmentId) {
    return _SearchableMemberList(
      future: _departmentService.getStudentsByDepartment(departmentId),
      searchHint: 'Search students by name or email...',
      emptyMessage: 'No students found in this department',
      subtitleBuilder: (member) => member.email,
      iconColor: AppConstants.primaryColor,
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.business, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            'No departments found',
            style: TextStyle(fontSize: 18, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildDepartmentCard(DepartmentModel department, int studentCount) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () {
          setState(() {
            _selectedDepartment = department;
          });
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: AppConstants.primaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.business_center, size: 30, color: AppConstants.primaryColor),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      department.name,
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$studentCount ${studentCount == 1 ? 'student' : 'students'}',
                      style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios, size: 20, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }
}

/// A reusable searchable member list widget.
class _SearchableMemberList extends StatefulWidget {
  final Future<List<UserModel>> future;
  final String searchHint;
  final String emptyMessage;
  final String Function(UserModel) subtitleBuilder;
  final Color iconColor;

  const _SearchableMemberList({
    Key? key,
    required this.future,
    required this.searchHint,
    required this.emptyMessage,
    required this.subtitleBuilder,
    required this.iconColor,
  }) : super(key: key);

  @override
  State<_SearchableMemberList> createState() => _SearchableMemberListState();
}

class _SearchableMemberListState extends State<_SearchableMemberList> {
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<UserModel>>(
      future: widget.future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final members = snapshot.data ?? [];

        final filtered = members.where((m) {
          if (_searchQuery.isEmpty) return true;
          final q = _searchQuery.toLowerCase();
          return m.fullName.toLowerCase().contains(q) ||
              m.email.toLowerCase().contains(q) ||
              m.role.toLowerCase().contains(q);
        }).toList();

        return Column(
          children: [
            // Search Bar
            Padding(
              padding: const EdgeInsets.all(16),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: widget.searchHint,
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _searchQuery = '');
                          },
                        )
                      : null,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: AppConstants.primaryColor),
                  ),
                  filled: true,
                  fillColor: Colors.grey[100],
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
                onChanged: (value) => setState(() => _searchQuery = value),
              ),
            ),
            // Count info
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Text(
                    '${filtered.length} of ${members.length} shown',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            // List
            Expanded(
              child: filtered.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.search_off, size: 60, color: Colors.grey[300]),
                          const SizedBox(height: 12),
                          Text(
                            _searchQuery.isNotEmpty
                                ? 'No results for "$_searchQuery"'
                                : widget.emptyMessage,
                            style: TextStyle(color: Colors.grey[600]),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: filtered.length,
                      itemBuilder: (context, index) {
                        final member = filtered[index];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 10),
                          elevation: 1,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: widget.iconColor,
                              child: Text(
                                member.fullName.isNotEmpty
                                    ? member.fullName[0].toUpperCase()
                                    : '?',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            title: Text(
                              member.fullName,
                              style: const TextStyle(fontWeight: FontWeight.w600),
                            ),
                            subtitle: Text(
                              widget.subtitleBuilder(member),
                              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        );
      },
    );
  }
}
