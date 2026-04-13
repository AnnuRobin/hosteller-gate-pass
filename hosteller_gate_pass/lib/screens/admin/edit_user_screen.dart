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
  late final TextEditingController _hostelNameController;
  late final TextEditingController _roomNoController;

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
    _hostelNameController = TextEditingController(text: widget.user.hostelName ?? '');
    _roomNoController = TextEditingController(text: widget.user.roomNo ?? '');
    
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
        backgroundColor: AppConstants.primaryColor,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // --- Professional Header Card ---
                      Container(
                        padding: const EdgeInsets.all(20),
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
                            CircleAvatar(
                              backgroundColor: AppConstants.primaryColor,
                              radius: 28,
                              child: Text(
                                widget.user.fullName[0].toUpperCase(),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(width: 20),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    widget.user.fullName,
                                    style: const TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black87,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    widget.user.email,
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey[600],
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // --- Form Fields Card ---
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.04),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            // Email (disabled)
                            _buildTextField(
                              initialValue: widget.user.email,
                              label: 'Email Address',
                              icon: Icons.email_outlined,
                              enabled: false,
                            ),
                            const SizedBox(height: 16),

                            // Full Name
                            _buildTextField(
                              controller: _fullNameController,
                              label: 'Full Name',
                              icon: Icons.person_outline,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Full name is required';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),

                            // Phone
                            _buildTextField(
                              controller: _phoneController,
                              label: 'Phone Number',
                              icon: Icons.phone_outlined,
                              keyboardType: TextInputType.phone,
                            ),
                            const SizedBox(height: 16),

                            // Role Selection
                            _buildDropdown<String>(
                              value: _selectedRole,
                              label: 'Role',
                              icon: Icons.badge_outlined,
                              items: const [
                                DropdownMenuItem(value: 'student', child: Text('Student')),
                                DropdownMenuItem(value: 'advisor', child: Text('Advisor')),
                                DropdownMenuItem(value: 'hod', child: Text('HOD')),
                                DropdownMenuItem(value: 'warden', child: Text('Warden')),
                                DropdownMenuItem(value: 'admin', child: Text('Admin')),
                                DropdownMenuItem(value: 'parent', child: Text('Parent')),
                              ],
                              onChanged: (value) => setState(() => _selectedRole = value!),
                            ),
                            
                            // Role-specific fields
                            if (_selectedRole == 'student') ..._buildStudentFields(),
                            if (_selectedRole == 'advisor' ||
                                _selectedRole == 'hod' ||
                                _selectedRole == 'warden')
                              ..._buildStaffFields(),
                          ],
                        ),
                      ),

                      const SizedBox(height: 32),

                      // --- Action Buttons ---
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => Navigator.pop(context),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                side: BorderSide(color: Colors.grey.shade300),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              child: Text('Cancel', style: TextStyle(color: Colors.grey[700])),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            flex: 2,
                            child: ElevatedButton(
                              onPressed: _updateUser,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppConstants.primaryColor,
                                foregroundColor: Colors.white,
                                elevation: 2,
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              child: const Text(
                                'Update User',
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
    );
  }

  Widget _buildTextField({
    TextEditingController? controller,
    String? initialValue,
    required String label,
    required IconData icon,
    bool enabled = true,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
    int maxLines = 1,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: TextFormField(
        controller: controller,
        initialValue: initialValue,
        enabled: enabled,
        keyboardType: keyboardType,
        validator: validator,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, size: 22),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade200)),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: AppConstants.primaryColor, width: 1.5)),
          filled: !enabled,
          fillColor: enabled ? null : Colors.grey[50],
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
      ),
    );
  }

  Widget _buildDropdown<T>({
    required T value,
    required String label,
    required IconData icon,
    required List<DropdownMenuItem<T>> items,
    required void Function(T?) onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: DropdownButtonFormField<T>(
        value: value,
        items: items,
        onChanged: onChanged,
        isExpanded: true, // Fix for overflow issues with long text
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, size: 22),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade200)),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: AppConstants.primaryColor, width: 1.5)),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
      ),
    );
  }

  List<Widget> _buildStudentFields() {
    return [
      const SizedBox(height: 16),
      // Department
      _buildDropdown<String>(
        value: _selectedDepartmentId!,
        label: 'Department',
        icon: Icons.business_outlined,
        items: _departments
            .map((dept) => DropdownMenuItem(
                  value: dept.id,
                  child: Text(dept.name),
                ))
            .toList(),
        onChanged: (value) => setState(() => _selectedDepartmentId = value),
      ),

      // Semester
      _buildDropdown<int>(
        value: _selectedSemester!,
        label: 'Semester',
        icon: Icons.calendar_today_outlined,
        items: List.generate(
          8,
          (index) => DropdownMenuItem(
            value: index + 1,
            child: Text('Semester ${index + 1}'),
          ),
        ),
        onChanged: (value) => setState(() => _selectedSemester = value),
      ),

      // Section
      _buildDropdown<String>(
        value: _selectedSection!,
        label: 'Section',
        icon: Icons.class_outlined,
        items: ['A', 'B', 'C', 'D', 'E']
            .map((section) => DropdownMenuItem(
                  value: section,
                  child: Text('Section $section'),
                ))
            .toList(),
        onChanged: (value) => setState(() => _selectedSection = value),
      ),

      // Home Address
      _buildTextField(
        controller: _homeAddressController,
        label: 'Home Address',
        icon: Icons.home_outlined,
        maxLines: 2,
      ),

      // Hostel Name
      _buildTextField(
        controller: _hostelNameController,
        label: 'Hostel Name',
        icon: Icons.domain_outlined,
      ),

      // Room No
      _buildTextField(
        controller: _roomNoController,
        label: 'Room Number',
        icon: Icons.meeting_room_outlined,
      ),
    ];
  }

  List<Widget> _buildStaffFields() {
    return [
      const SizedBox(height: 16),
      // Department - Hidden for Wardens
      if (_selectedRole != 'warden')
        _buildDropdown<String?>(
          value: _selectedDepartmentId,
          label: 'Department',
          icon: Icons.business_outlined,
          items: _departments
              .map((dept) => DropdownMenuItem(
                    value: dept.id,
                    child: Text(dept.name),
                  ))
              .toList(),
          onChanged: (value) => setState(() => _selectedDepartmentId = value),
        ),

      // Hostel Name (for wardens)
      if (_selectedRole == 'warden')
        _buildTextField(
          controller: _hostelNameController,
          label: 'Hostel Name',
          icon: Icons.domain_outlined,
        ),
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
        hostelName: _hostelNameController.text.trim().isEmpty
            ? null
            : _hostelNameController.text.trim(),
        roomNo: _selectedRole == 'student' && _roomNoController.text.trim().isNotEmpty
            ? _roomNoController.text.trim()
            : null,
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


  @override
  void dispose() {
    _fullNameController.dispose();
    _phoneController.dispose();
    _homeAddressController.dispose();
    _hostelNameController.dispose();
    _roomNoController.dispose();
    super.dispose();
  }
}
