import 'package:flutter/material.dart';
import '../../services/admin_service.dart';
import '../../services/department_service.dart';
import '../../models/user_model.dart';
import '../../models/department_model.dart';
import '../../utils/constants.dart';

class EditUserScreen extends StatefulWidget {
  final UserModel user;

  const EditUserScreen({
    Key? key,
    required this.user,
  }) : super(key: key);

  @override
  State<EditUserScreen> createState() => _EditUserScreenState();
}

class _EditUserScreenState extends State<EditUserScreen> {
  final _formKey = GlobalKey<FormState>();
  final AdminService _adminService = AdminService();
  final DepartmentService _departmentService = DepartmentService();

  // Form controllers
  late final TextEditingController _fullNameController;
  late final TextEditingController _phoneController;
  late final TextEditingController _homeAddressController;

  // Form state
  late String _selectedRole;
  String? _selectedDepartmentId;
  int? _selectedSemester;
  String? _selectedSection;
  bool _isLoading = false;
  List<DepartmentModel> _departments = [];

  @override
  void initState() {
    super.initState();
    _fullNameController = TextEditingController(text: widget.user.fullName);
    _phoneController = TextEditingController(text: widget.user.phone ?? '');
    _homeAddressController = TextEditingController(text: widget.user.homeAddress ?? '');
    
    _selectedRole = widget.user.role;
    _selectedDepartmentId = widget.user.departmentId;
    _selectedSemester = widget.user.semester;
    _selectedSection = widget.user.section;
    
    _loadDepartments();
  }

  Future<void> _loadDepartments() async {
    try {
      final departments = await _departmentService.getAllDepartments();
      setState(() => _departments = departments);
    } catch (e) {
      print('Error loading departments: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit User'),
        actions: [
          IconButton(
            icon: const Icon(Icons.lock_reset),
            tooltip: 'Reset Password',
            onPressed: _showResetPasswordDialog,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Header
                    Card(
                      color: AppConstants.primaryColor.withOpacity(0.1),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            CircleAvatar(
                              backgroundColor: AppConstants.primaryColor,
                              radius: 24,
                              child: Text(
                                widget.user.fullName[0].toUpperCase(),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    widget.user.fullName,
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    widget.user.email,
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Basic Information
                    _buildSectionHeader('Basic Information'),
                    const SizedBox(height: 16),

                    // Email (disabled)
                    TextFormField(
                      initialValue: widget.user.email,
                      decoration: const InputDecoration(
                        labelText: 'Email',
                        prefixIcon: Icon(Icons.email),
                        border: OutlineInputBorder(),
                        enabled: false,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Full Name
                    TextFormField(
                      controller: _fullNameController,
                      decoration: const InputDecoration(
                        labelText: 'Full Name *',
                        prefixIcon: Icon(Icons.person),
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Full name is required';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Phone
                    TextFormField(
                      controller: _phoneController,
                      decoration: const InputDecoration(
                        labelText: 'Phone',
                        prefixIcon: Icon(Icons.phone),
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.phone,
                    ),
                    const SizedBox(height: 24),

                    // Role Selection
                    _buildSectionHeader('Role & Permissions'),
                    const SizedBox(height: 16),

                    DropdownButtonFormField<String>(
                      value: _selectedRole,
                      decoration: const InputDecoration(
                        labelText: 'Role *',
                        prefixIcon: Icon(Icons.badge),
                        border: OutlineInputBorder(),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'student', child: Text('Student')),
                        DropdownMenuItem(value: 'advisor', child: Text('Advisor')),
                        DropdownMenuItem(value: 'hod', child: Text('HOD')),
                        DropdownMenuItem(value: 'warden', child: Text('Warden')),
                        DropdownMenuItem(value: 'admin', child: Text('Admin')),
                        DropdownMenuItem(value: 'parent', child: Text('Parent')),
                      ],
                      onChanged: (value) {
                        setState(() => _selectedRole = value!);
                      },
                    ),
                    const SizedBox(height: 24),

                    // Role-specific fields
                    if (_selectedRole == 'student') ..._buildStudentFields(),
                    if (_selectedRole == 'advisor' ||
                        _selectedRole == 'hod' ||
                        _selectedRole == 'warden')
                      ..._buildStaffFields(),

                    const SizedBox(height: 32),

                    // Action Buttons
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.pop(context),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                            child: const Text('Cancel'),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          flex: 2,
                          child: ElevatedButton(
                            onPressed: _updateUser,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppConstants.primaryColor,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                            child: const Text(
                              'Update User',
                              style: TextStyle(fontSize: 16),
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
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: Colors.black87,
      ),
    );
  }

  List<Widget> _buildStudentFields() {
    return [
      _buildSectionHeader('Student Information'),
      const SizedBox(height: 16),

      // Department
      DropdownButtonFormField<String>(
        value: _selectedDepartmentId,
        decoration: const InputDecoration(
          labelText: 'Department *',
          prefixIcon: Icon(Icons.business),
          border: OutlineInputBorder(),
        ),
        items: _departments
            .map((dept) => DropdownMenuItem(
                  value: dept.id,
                  child: Text(dept.name),
                ))
            .toList(),
        onChanged: (value) {
          setState(() => _selectedDepartmentId = value);
        },
      ),
      const SizedBox(height: 16),

      // Semester
      DropdownButtonFormField<int>(
        value: _selectedSemester,
        decoration: const InputDecoration(
          labelText: 'Semester *',
          prefixIcon: Icon(Icons.calendar_today),
          border: OutlineInputBorder(),
        ),
        items: List.generate(
          8,
          (index) => DropdownMenuItem(
            value: index + 1,
            child: Text('Semester ${index + 1}'),
          ),
        ),
        onChanged: (value) {
          setState(() => _selectedSemester = value);
        },
      ),
      const SizedBox(height: 16),

      // Section
      DropdownButtonFormField<String>(
        value: _selectedSection,
        decoration: const InputDecoration(
          labelText: 'Section *',
          prefixIcon: Icon(Icons.class_),
          border: OutlineInputBorder(),
        ),
        items: ['A', 'B', 'C', 'D', 'E']
            .map((section) => DropdownMenuItem(
                  value: section,
                  child: Text('Section $section'),
                ))
            .toList(),
        onChanged: (value) {
          setState(() => _selectedSection = value);
        },
      ),
      const SizedBox(height: 16),

      // Home Address
      TextFormField(
        controller: _homeAddressController,
        decoration: const InputDecoration(
          labelText: 'Home Address',
          prefixIcon: Icon(Icons.home),
          border: OutlineInputBorder(),
        ),
        maxLines: 3,
      ),
      const SizedBox(height: 24),
    ];
  }

  List<Widget> _buildStaffFields() {
    return [
      _buildSectionHeader('Staff Information'),
      const SizedBox(height: 16),

      // Department
      DropdownButtonFormField<String>(
        value: _selectedDepartmentId,
        decoration: const InputDecoration(
          labelText: 'Department',
          prefixIcon: Icon(Icons.business),
          border: OutlineInputBorder(),
        ),
        items: _departments
            .map((dept) => DropdownMenuItem(
                  value: dept.id,
                  child: Text(dept.name),
                ))
            .toList(),
        onChanged: (value) {
          setState(() => _selectedDepartmentId = value);
        },
      ),
      const SizedBox(height: 24),
    ];
  }

  Future<void> _updateUser() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      await _adminService.updateUser(
        userId: widget.user.id,
        fullName: _fullNameController.text.trim(),
        phone: _phoneController.text.trim().isEmpty
            ? null
            : _phoneController.text.trim(),
        role: _selectedRole,
        departmentId: _selectedDepartmentId,
        semester: _selectedSemester,
        section: _selectedSection,
        homeAddress: _homeAddressController.text.trim().isEmpty
            ? null
            : _homeAddressController.text.trim(),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('User ${_fullNameController.text} updated successfully!'),
            backgroundColor: AppConstants.successColor,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating user: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _showResetPasswordDialog() async {
    final passwordController = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset Password'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Reset password for ${widget.user.fullName}?'),
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
              backgroundColor: AppConstants.warningColor,
            ),
            child: const Text('Reset'),
          ),
        ],
      ),
    );

    if (confirmed == true && passwordController.text.isNotEmpty) {
      try {
        await _adminService.resetUserPassword(
          widget.user.id,
          passwordController.text,
        );
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
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _phoneController.dispose();
    _homeAddressController.dispose();
    super.dispose();
  }
}
