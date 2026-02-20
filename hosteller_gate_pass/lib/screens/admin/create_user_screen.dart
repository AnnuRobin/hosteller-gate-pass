import 'package:flutter/material.dart';
import '../../services/admin_service.dart';
import '../../services/department_service.dart';
import '../../models/department_model.dart';
import '../../utils/constants.dart';

class CreateUserScreen extends StatefulWidget {
  final String initialRole;

  const CreateUserScreen({
    Key? key,
    this.initialRole = 'student',
  }) : super(key: key);

  @override
  State<CreateUserScreen> createState() => _CreateUserScreenState();
}

class _CreateUserScreenState extends State<CreateUserScreen> {
  final _formKey = GlobalKey<FormState>();
  final AdminService _adminService = AdminService();
  final DepartmentService _departmentService = DepartmentService();

  // Form controllers
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _fullNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _homeAddressController = TextEditingController();

  // Form state
  late String _selectedRole;
  String? _selectedDepartmentId;
  int? _selectedSemester;
  String _selectedSection = 'A';
  bool _isLoading = false;
  List<DepartmentModel> _departments = [];

  @override
  void initState() {
    super.initState();
    _selectedRole = widget.initialRole;
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
        title: const Text('Create New User'),
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
                            Icon(
                              Icons.person_add,
                              color: AppConstants.primaryColor,
                              size: 32,
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Add New User',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Fill in the details below',
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

                    // Basic Information Section
                    _buildSectionHeader('Basic Information'),
                    const SizedBox(height: 16),

                    // Email
                    TextFormField(
                      controller: _emailController,
                      decoration: const InputDecoration(
                        labelText: 'Email *',
                        hintText: 'user@example.com',
                        prefixIcon: Icon(Icons.email),
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.emailAddress,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Email is required';
                        }
                        if (!value.contains('@')) {
                          return 'Enter a valid email';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Password
                    TextFormField(
                      controller: _passwordController,
                      decoration: const InputDecoration(
                        labelText: 'Password *',
                        hintText: 'Minimum 8 characters',
                        prefixIcon: Icon(Icons.lock),
                        border: OutlineInputBorder(),
                      ),
                      obscureText: true,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Password is required';
                        }
                        if (value.length < 8) {
                          return 'Password must be at least 8 characters';
                        }
                        return null;
                      },
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
                        hintText: '+91-9876543210',
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
                        setState(() {
                          _selectedRole = value!;
                          // Reset role-specific fields
                          _selectedDepartmentId = null;
                          _selectedSemester = null;
                        });
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
                            onPressed: _createUser,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppConstants.primaryColor,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                            child: const Text(
                              'Create User',
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
        validator: (value) {
          if (_selectedRole == 'student' && value == null) {
            return 'Department is required for students';
          }
          return null;
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
        validator: (value) {
          if (_selectedRole == 'student' && value == null) {
            return 'Semester is required for students';
          }
          return null;
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
          setState(() => _selectedSection = value!);
        },
      ),
      const SizedBox(height: 16),

      // Home Address
      TextFormField(
        controller: _homeAddressController,
        decoration: const InputDecoration(
          labelText: 'Home Address',
          hintText: 'Enter full address',
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

  Future<void> _createUser() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      await _adminService.createUser(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        fullName: _fullNameController.text.trim(),
        role: _selectedRole,
        phone: _phoneController.text.trim().isEmpty
            ? null
            : _phoneController.text.trim(),
        departmentId: _selectedDepartmentId,
        semester: _selectedSemester,
        section: _selectedRole == 'student' ? _selectedSection : null,
        homeAddress: _homeAddressController.text.trim().isEmpty
            ? null
            : _homeAddressController.text.trim(),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('User ${_fullNameController.text} created successfully!'),
            backgroundColor: AppConstants.successColor,
          ),
        );
        Navigator.pop(context, true); // Return true to indicate success
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error creating user: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _fullNameController.dispose();
    _phoneController.dispose();
    _homeAddressController.dispose();
    super.dispose();
  }
}
