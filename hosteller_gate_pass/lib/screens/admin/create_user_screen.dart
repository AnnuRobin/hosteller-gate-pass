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

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _fullNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _homeAddressController = TextEditingController();
  final _hostelNameController = TextEditingController();
  final _roomNoController = TextEditingController();

  late String _selectedRole;
  String? _selectedDepartmentId;
  int? _selectedSemester;
  String _selectedSection = 'A';
  bool _isLoading = false;
  bool _obscurePassword = true;
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
      debugPrint('Error loading departments: $e');
    }
  }

  // Each role has its own accent colour for visual identity
  Color get _roleColor {
    switch (_selectedRole) {
      case 'student':
        return const Color(0xFF3B82F6); // blue
      case 'advisor':
        return const Color(0xFF8B5CF6); // violet
      case 'hod':
        return const Color(0xFFF59E0B); // amber
      case 'warden':
        return const Color(0xFF10B981); // emerald
      case 'admin':
        return const Color(0xFFEF4444); // red
      case 'parent':
        return const Color(0xFF6366F1); // indigo
      default:
        return AppConstants.primaryColor;
    }
  }

  IconData get _roleIcon {
    switch (_selectedRole) {
      case 'student':
        return Icons.school_rounded;
      case 'advisor':
        return Icons.person_pin_rounded;
      case 'hod':
        return Icons.account_balance_rounded;
      case 'warden':
        return Icons.security_rounded;
      case 'admin':
        return Icons.admin_panel_settings_rounded;
      case 'parent':
        return Icons.family_restroom_rounded;
      default:
        return Icons.person_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: null,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Column(
                children: [
                  // ── Gradient hero header ────────────────────────────────────
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [_roleColor, _roleColor.withValues(alpha: 0.7)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: Row(
                      children: [
                        IconButton(
                          icon:
                              const Icon(Icons.arrow_back, color: Colors.white),
                          onPressed: () => Navigator.pop(context),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.25),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(_roleIcon, color: Colors.white, size: 28),
                        ),
                        const SizedBox(width: 16),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Add New User',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Fill in the details below',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.85),
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // ── Form body ───────────────────────────────────────────────
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          // ─ Basic Information ─
                          _buildCard(
                            sectionColor: const Color(0xFF3B82F6),
                            icon: Icons.person_outline_rounded,
                            title: 'Basic Information',
                            children: [
                              // Email + Full Name in a row
                              Row(
                                children: [
                                  Expanded(
                                    child: _buildField(
                                      controller: _emailController,
                                      label: 'Email *',
                                      icon: Icons.email_outlined,
                                      accentColor: const Color(0xFF3B82F6),
                                      keyboardType: TextInputType.emailAddress,
                                      validator: (v) {
                                        if (v == null || v.isEmpty)
                                          return 'Required';
                                        if (!v.contains('@'))
                                          return 'Invalid email';
                                        return null;
                                      },
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: _buildField(
                                      controller: _fullNameController,
                                      label: 'Full Name *',
                                      icon: Icons.badge_outlined,
                                      accentColor: const Color(0xFF3B82F6),
                                      validator: (v) => (v == null || v.isEmpty)
                                          ? 'Required'
                                          : null,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 14),
                              // Password + Phone in a row
                              Row(
                                children: [
                                  Expanded(
                                    child: TextFormField(
                                      controller: _passwordController,
                                      obscureText: _obscurePassword,
                                      decoration: _inputDecoration(
                                        label: 'Password *',
                                        icon: Icons.lock_outline_rounded,
                                        accentColor: const Color(0xFF3B82F6),
                                        suffix: IconButton(
                                          icon: Icon(
                                            _obscurePassword
                                                ? Icons.visibility_off_outlined
                                                : Icons.visibility_outlined,
                                            size: 18,
                                            color: Colors.grey,
                                          ),
                                          onPressed: () => setState(() =>
                                              _obscurePassword =
                                                  !_obscurePassword),
                                        ),
                                      ),
                                      validator: (v) {
                                        if (v == null || v.isEmpty)
                                          return 'Required';
                                        if (v.length < 8) return 'Min 8 chars';
                                        return null;
                                      },
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: _buildField(
                                      controller: _phoneController,
                                      label: 'Phone',
                                      icon: Icons.phone_outlined,
                                      accentColor: const Color(0xFF3B82F6),
                                      keyboardType: TextInputType.phone,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),

                          const SizedBox(height: 14),

                          // ─ Role ─
                          _buildCard(
                            sectionColor: _roleColor,
                            icon: Icons.shield_outlined,
                            title: 'Role & Permissions',
                            children: [
                              DropdownButtonFormField<String>(
                                value: _selectedRole,
                                decoration: _inputDecoration(
                                  label: 'Role *',
                                  icon: Icons.badge_outlined,
                                  accentColor: _roleColor,
                                ),
                                items: const [
                                  DropdownMenuItem(
                                      value: 'student', child: Text('Student')),
                                  DropdownMenuItem(
                                      value: 'advisor', child: Text('Advisor')),
                                  DropdownMenuItem(
                                      value: 'hod', child: Text('HOD')),
                                  DropdownMenuItem(
                                      value: 'warden', child: Text('Warden')),
                                  DropdownMenuItem(
                                      value: 'parent', child: Text('Parent')),
                                ],
                                onChanged: (value) {
                                  setState(() {
                                    _selectedRole = value!;
                                    _selectedDepartmentId = null;
                                    _selectedSemester = null;
                                  });
                                },
                              ),
                            ],
                          ),

                          const SizedBox(height: 14),

                          // ─ Role-specific fields ─
                          if (_selectedRole == 'student')
                            ..._buildStudentCard(),
                          if (_selectedRole == 'advisor' ||
                              _selectedRole == 'hod' ||
                              _selectedRole == 'warden')
                            ..._buildStaffCard(),

                          const SizedBox(height: 24),

                          // ─ Action buttons ─
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: () => Navigator.pop(context),
                                  style: OutlinedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 14),
                                    shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(12)),
                                  ),
                                  child: const Text('Cancel'),
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                flex: 2,
                                child: ElevatedButton.icon(
                                  icon: const Icon(Icons.person_add_rounded,
                                      size: 18),
                                  label: const Text('Create User',
                                      style: TextStyle(fontSize: 15)),
                                  onPressed: _createUser,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: _roleColor,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 14),
                                    shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(12)),
                                    elevation: 2,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  /// A coloured section card with a labelled header.
  Widget _buildCard({
    required Color sectionColor,
    required IconData icon,
    required String title,
    required List<Widget> children,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Coloured accent header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: sectionColor.withValues(alpha: 0.08),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(16)),
              border: Border(
                left: BorderSide(color: sectionColor, width: 3),
              ),
            ),
            child: Row(
              children: [
                Icon(icon, size: 16, color: sectionColor),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: sectionColor,
                    letterSpacing: 0.3,
                  ),
                ),
              ],
            ),
          ),
          // Form fields
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: children,
            ),
          ),
        ],
      ),
    );
  }

  /// A styled text form field.
  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required Color accentColor,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      decoration:
          _inputDecoration(label: label, icon: icon, accentColor: accentColor),
      validator: validator,
    );
  }

  InputDecoration _inputDecoration({
    required String label,
    required IconData icon,
    required Color accentColor,
    Widget? suffix,
  }) {
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(fontSize: 13, color: Colors.grey[600]),
      prefixIcon: Icon(icon, size: 18, color: accentColor),
      suffixIcon: suffix,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: Colors.grey[300]!),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: Colors.grey[300]!),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: accentColor, width: 1.8),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Colors.red),
      ),
      filled: true,
      fillColor: Colors.grey[50],
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      isDense: true,
    );
  }

  List<Widget> _buildStudentCard() {
    const color = Color(0xFF3B82F6);
    return [
      _buildCard(
        sectionColor: color,
        icon: Icons.school_rounded,
        title: 'Student Information',
        children: [
          // Department + Semester in a row
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _selectedDepartmentId,
                  isExpanded: true,
                  decoration: _inputDecoration(
                      label: 'Department *',
                      icon: Icons.business_outlined,
                      accentColor: color),
                  items: _departments
                      .map((d) => DropdownMenuItem(
                          value: d.id,
                          child: Text(d.name, overflow: TextOverflow.ellipsis)))
                      .toList(),
                  onChanged: (v) => setState(() => _selectedDepartmentId = v),
                  validator: (v) => v == null ? 'Required' : null,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: DropdownButtonFormField<int>(
                  value: _selectedSemester,
                  decoration: _inputDecoration(
                      label: 'Semester *',
                      icon: Icons.layers_outlined,
                      accentColor: color),
                  items: List.generate(
                      8,
                      (i) => DropdownMenuItem(
                          value: i + 1, child: Text('Sem ${i + 1}'))),
                  onChanged: (v) => setState(() => _selectedSemester = v),
                  validator: (v) => v == null ? 'Required' : null,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          // Section + Hostel in a row
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _selectedSection,
                  decoration: _inputDecoration(
                      label: 'Section *',
                      icon: Icons.class_outlined,
                      accentColor: color),
                  items: ['A', 'B', 'C', 'D', 'E']
                      .map((s) =>
                          DropdownMenuItem(value: s, child: Text('Sec $s')))
                      .toList(),
                  onChanged: (v) => setState(() => _selectedSection = v!),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildField(
                  controller: _hostelNameController,
                  label: 'Hostel Name',
                  icon: Icons.domain_outlined,
                  accentColor: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          // Room + Home address
          Row(
            children: [
              Expanded(
                child: _buildField(
                  controller: _roomNoController,
                  label: 'Room No.',
                  icon: Icons.meeting_room_outlined,
                  accentColor: color,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildField(
                  controller: _homeAddressController,
                  label: 'Home Address',
                  icon: Icons.home_outlined,
                  accentColor: color,
                ),
              ),
            ],
          ),
        ],
      ),
      const SizedBox(height: 14),
    ];
  }

  List<Widget> _buildStaffCard() {
    return [
      _buildCard(
        sectionColor: _roleColor,
        icon: Icons.work_outline_rounded,
        title: 'Staff Information',
        children: [
          DropdownButtonFormField<String>(
            value: _selectedDepartmentId,
            isExpanded: true,
            decoration: _inputDecoration(
                label: 'Department',
                icon: Icons.business_outlined,
                accentColor: _roleColor),
            items: _departments
                .map((d) => DropdownMenuItem(
                    value: d.id,
                    child: Text(d.name, overflow: TextOverflow.ellipsis)))
                .toList(),
            onChanged: (v) => setState(() => _selectedDepartmentId = v),
          ),
          if (_selectedRole == 'warden') ...[
            const SizedBox(height: 14),
            _buildField(
              controller: _hostelNameController,
              label: 'Hostel Name',
              icon: Icons.domain_outlined,
              accentColor: _roleColor,
            ),
          ],
        ],
      ),
      const SizedBox(height: 14),
    ];
  }

  Future<void> _createUser() async {
    if (!_formKey.currentState!.validate()) return;

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
        hostelName: _hostelNameController.text.trim().isEmpty
            ? null
            : _hostelNameController.text.trim(),
        roomNo: _selectedRole == 'student' &&
                _roomNoController.text.trim().isNotEmpty
            ? _roomNoController.text.trim()
            : null,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                Text('User ${_fullNameController.text} created successfully!'),
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
    _hostelNameController.dispose();
    _roomNoController.dispose();
    super.dispose();
  }
}
