import 'package:flutter/material.dart';
import '../../models/user_model.dart';
import '../../services/admin_service.dart';
import '../../services/department_service.dart';
import '../../models/department_model.dart';
import '../../utils/constants.dart';
import 'edit_user_screen.dart';

class UserDetailsPage extends StatefulWidget {
  final UserModel user;

  const UserDetailsPage({Key? key, required this.user}) : super(key: key);

  @override
  State<UserDetailsPage> createState() => _UserDetailsPageState();
}

class _UserDetailsPageState extends State<UserDetailsPage> {
  final AdminService _adminService = AdminService();
  final DepartmentService _departmentService = DepartmentService();
  DepartmentModel? _department;
  bool _isLoadingDept = false;

  @override
  void initState() {
    super.initState();
    if (widget.user.departmentId != null) {
      _loadDepartment();
    }
  }

  Future<void> _loadDepartment() async {
    setState(() => _isLoadingDept = true);
    try {
      final dept = await _departmentService.getDepartmentById(widget.user.departmentId!);
      if (mounted) setState(() => _department = dept);
    } catch (e) {
      debugPrint('Error loading department: $e');
    } finally {
      if (mounted) setState(() => _isLoadingDept = false);
    }
  }

  Future<void> _confirmDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Delete User',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87),
        ),
        content: const Text(
          'Are you sure you want to delete this user?',
          style: TextStyle(color: Colors.black54, fontSize: 15),
        ),
        actionsPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              'Cancel',
              style: TextStyle(color: Colors.grey[600], fontWeight: FontWeight.w600),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Delete', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _adminService.deleteUser(widget.user.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${widget.user.fullName} deleted successfully'),
              backgroundColor: AppConstants.successColor,
            ),
          );
          Navigator.pop(context, true); // Pop back to list
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('User Details', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: AppConstants.primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            onPressed: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => EditUserScreen(user: widget.user),
                ),
              );
              if (result == true) {
                // If updated, pop back to trigger list refresh
                if (mounted) Navigator.pop(context, true);
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.white),
            onPressed: _confirmDelete,
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Header Section
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: AppConstants.primaryColor,
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(30)),
              ),
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 40),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundColor: Colors.white.withValues(alpha: 0.2),
                    child: Text(
                      widget.user.fullName[0].toUpperCase(),
                      style: const TextStyle(color: Colors.white, fontSize: 40, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    widget.user.fullName,
                    style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      widget.user.roleDisplayName,
                      style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildInfoCard(
                    title: 'Contact Information',
                    icon: Icons.contact_mail_outlined,
                    children: [
                      _buildInfoRow(Icons.email_outlined, 'Email', widget.user.email),
                      _buildInfoRow(Icons.phone_outlined, 'Phone', widget.user.phone ?? 'Not provided'),
                    ],
                  ),
                  const SizedBox(height: 20),
                  if (widget.user.role != 'warden') ...[
                    _buildInfoCard(
                      title: 'Professional Details',
                      icon: Icons.business_outlined,
                      children: [
                        _buildInfoRow(
                          Icons.apartment_outlined, 
                          'Department', 
                          _isLoadingDept ? 'Loading...' : (_department?.name ?? 'Not assigned')
                        ),
                        if (_department?.departmentCode != null)
                          _buildInfoRow(Icons.code_rounded, 'Department Code', _department!.departmentCode!),
                        if (widget.user.role == 'student') ...[
                          _buildInfoRow(Icons.layers_outlined, 'Semester', widget.user.semester?.toString() ?? 'N/A'),
                          _buildInfoRow(Icons.class_outlined, 'Section', widget.user.section ?? 'N/A'),
                        ],
                      ],
                    ),
                    const SizedBox(height: 20),
                  ],
                  if (widget.user.role == 'student' || widget.user.role == 'warden')
                    _buildInfoCard(
                      title: 'Residence Details',
                      icon: Icons.home_work_outlined,
                      children: [
                        _buildInfoRow(Icons.location_city_outlined, 'Hostel', widget.user.hostelName ?? 'Not assigned'),
                        if (widget.user.role == 'student')
                          _buildInfoRow(Icons.meeting_room_outlined, 'Room No', widget.user.roomNo ?? 'Not assigned'),
                        if (widget.user.homeAddress != null)
                          _buildInfoRow(Icons.home_outlined, 'Home Address', widget.user.homeAddress!),
                      ],
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard({required String title, required IconData icon, required List<Widget> children}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppConstants.primaryColor, size: 20),
              const SizedBox(width: 10),
              Text(
                title,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
              ),
            ],
          ),
          const SizedBox(height: 20),
          ...children,
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: Colors.grey[600], size: 16),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(color: Colors.grey[500], fontSize: 12, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(color: Colors.black87, fontSize: 15, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
