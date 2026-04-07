import 'package:flutter/material.dart';
import '../../services/department_service.dart';
import '../../models/department_model.dart';
import '../../utils/constants.dart';
import 'batches_screen.dart';

class DepartmentsScreen extends StatefulWidget {
  const DepartmentsScreen({Key? key}) : super(key: key);

  @override
  State<DepartmentsScreen> createState() => _DepartmentsScreenState();
}

class _DepartmentsScreenState extends State<DepartmentsScreen> {
  final DepartmentService _departmentService = DepartmentService();
  List<Map<String, dynamic>> _departmentsWithCounts = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadDepartments();
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Departments'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadDepartments,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  const SizedBox(height: 16),
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Departments',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'View and manage your academic departments.',
                      style: TextStyle(color: Colors.black54),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: _departmentsWithCounts.isEmpty
                        ? _buildEmptyState()
                        : RefreshIndicator(
                            onRefresh: _loadDepartments,
                            child: ListView.builder(
                              padding: const EdgeInsets.only(bottom: 16),
                              itemCount: _departmentsWithCounts.length,
                              itemBuilder: (context, index) {
                                final data = _departmentsWithCounts[index];
                                final department =
                                    data['department'] as DepartmentModel;
                                final studentCount =
                                    data['student_count'] as int;

                                return _buildDepartmentCard(
                                  department,
                                  studentCount,
                                );
                              },
                            ),
                          ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.business,
            size: 80,
            color: Colors.grey[300],
          ),
          const SizedBox(height: 16),
          Text(
            'No departments found',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Create your first department to get started.',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDepartmentCard(DepartmentModel department, int studentCount) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => BatchesScreen(
                department: department,
              ),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: ListTile(
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          leading: Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: AppConstants.primaryColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              Icons.business_center,
              size: 28,
              color: AppConstants.primaryColor,
            ),
          ),
          title: Text(
            department.name,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          subtitle: Text(
            '$studentCount ${studentCount == 1 ? 'student' : 'students'}',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '$studentCount',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppConstants.primaryColor,
                ),
              ),
              const SizedBox(width: 8),
              const Icon(
                Icons.arrow_forward_ios,
                size: 18,
                color: Colors.grey,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
