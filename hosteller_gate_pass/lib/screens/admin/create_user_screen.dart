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
  final _fullNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _homeAddressController = TextEditingController();
  final _roomNoController = TextEditingController();

  // New hostel / department inline-add controllers
  final _newHostelController = TextEditingController();
  final _newDepartmentController = TextEditingController();
  final _newDepartmentCodeController = TextEditingController();

  late String _selectedRole;
  String? _selectedDepartmentId;
  String? _selectedHostelName;
  int? _selectedSemester;
  String _selectedSection = 'A';
  bool _isLoading = false;
  bool _isAddingNewHostel = false;
  bool _isAddingNewDepartment = false;
  bool _isSavingHostel = false;
  bool _isSavingDepartment = false;

  List<DepartmentModel> _departments = [];
  List<String> _hostels = [];

  @override
  void initState() {
    super.initState();
    _selectedRole = widget.initialRole;
    _loadDepartments();
    _loadHostels();
  }

  Future<void> _loadDepartments() async {
    try {
      final departments = await _departmentService.getAllDepartments();
      if (mounted) setState(() => _departments = departments);
    } catch (e) {
      debugPrint('Error loading departments: $e');
    }
  }

  /// Pull unique hostel names from existing user records.
  Future<void> _loadHostels() async {
    try {
      final users = await _adminService.getAllUsers();
      final hostelSet = users
          .map((u) => u.hostelName)
          .where((h) => h != null && h.isNotEmpty)
          .cast<String>()
          .toSet()
          .toList();
      hostelSet.sort();
      if (mounted) setState(() => _hostels = hostelSet);
    } catch (e) {
      debugPrint('Error loading hostels: $e');
    }
  }

  // ── Role accent colour ────────────────────────────────────────────────────
  Color get _roleColor {
    switch (_selectedRole) {
      case 'student':
        return const Color(0xFF3B82F6);
      case 'advisor':
        return const Color(0xFF8B5CF6);
      case 'hod':
        return const Color(0xFFF59E0B);
      case 'warden':
        return const Color(0xFF10B981);
      case 'admin':
        return const Color(0xFFEF4444);
      case 'parent':
        return const Color(0xFF6366F1);
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
    return SafeArea(
      child: Scaffold(
        backgroundColor: const Color(0xFFF1F5F9),
        appBar: AppBar(
          backgroundColor: _roleColor,
          foregroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          title: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.25),
                  shape: BoxShape.circle,
                ),
                child: Icon(_roleIcon, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 12),
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Add New User',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'Fill in the details below',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                child: Padding(
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
                                    validator: (v) =>
                                        (v == null || v.isEmpty)
                                            ? 'Required'
                                            : null,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 14),
                            _buildField(
                              controller: _phoneController,
                              label: 'Phone',
                              icon: Icons.phone_outlined,
                              accentColor: const Color(0xFF3B82F6),
                              keyboardType: TextInputType.phone,
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
                                    value: 'student',
                                    child: Text('Student')),
                                DropdownMenuItem(
                                    value: 'advisor',
                                    child: Text('Advisor')),
                                DropdownMenuItem(
                                    value: 'hod', child: Text('HOD')),
                                DropdownMenuItem(
                                    value: 'warden',
                                    child: Text('Warden')),
                                DropdownMenuItem(
                                    value: 'parent',
                                    child: Text('Parent')),
                              ],
                              onChanged: (value) {
                                setState(() {
                                  _selectedRole = value!;
                                  _selectedDepartmentId = null;
                                  _selectedSemester = null;
                                  _selectedHostelName = null;
                                  _isAddingNewHostel = false;
                                  _isAddingNewDepartment = false;
                                });
                              },
                            ),
                          ],
                        ),

                        const SizedBox(height: 14),

                        // ─ Role-specific fields ─
                        if (_selectedRole == 'student')
                          ..._buildStudentCard(),
                        if (_selectedRole == 'advisor')
                          ..._buildAdvisorCard(),
                        if (_selectedRole == 'hod')
                          ..._buildHodCard(),
                        if (_selectedRole == 'warden')
                          ..._buildWardenCard(),

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
                                icon: const Icon(
                                    Icons.person_add_rounded,
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
              ),
      ),
    );
  }

  // ── Section builders ──────────────────────────────────────────────────────

  List<Widget> _buildStudentCard() {
    const color = Color(0xFF3B82F6);
    return [
      _buildCard(
        sectionColor: color,
        icon: Icons.school_rounded,
        title: 'Student Information',
        children: [
          // Department — NO add-new option for students
          _buildDepartmentDropdown(
              accentColor: color, required: true, showAddNew: false),
          const SizedBox(height: 14),
          // Semester + Section
          Row(
            children: [
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
              const SizedBox(width: 12),
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _selectedSection,
                  decoration: _inputDecoration(
                      label: 'Section *',
                      icon: Icons.class_outlined,
                      accentColor: color),
                  items: ['A', 'B', 'C', 'D', 'E']
                      .map((s) => DropdownMenuItem(
                          value: s, child: Text('Sec $s')))
                      .toList(),
                  onChanged: (v) => setState(() => _selectedSection = v!),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          // Hostel (dropdown with Add New)
          _buildHostelDropdown(accentColor: color, showAddNew: false),
          const SizedBox(height: 14),
          // Room + Address
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

  /// HOD card — has the "+ Add New Department" option.
  List<Widget> _buildHodCard() {
    return [
      _buildCard(
        sectionColor: _roleColor,
        icon: Icons.work_outline_rounded,
        title: 'HOD Information',
        children: [
          _buildDepartmentDropdown(
              accentColor: _roleColor, required: false, showAddNew: true),
        ],
      ),
      const SizedBox(height: 14),
    ];
  }

  /// Advisor card — plain department list, no add-new.
  List<Widget> _buildAdvisorCard() {
    return [
      _buildCard(
        sectionColor: _roleColor,
        icon: Icons.work_outline_rounded,
        title: 'Advisor Information',
        children: [
          _buildDepartmentDropdown(
              accentColor: _roleColor, required: false, showAddNew: false),
        ],
      ),
      const SizedBox(height: 14),
    ];
  }

  /// Warden card: hostel dropdown only (no department).
  List<Widget> _buildWardenCard() {
    return [
      _buildCard(
        sectionColor: _roleColor,
        icon: Icons.work_outline_rounded,
        title: 'Warden Information',
        children: [
          _buildHostelDropdown(accentColor: _roleColor, showAddNew: true),
        ],
      ),
      const SizedBox(height: 14),
    ];
  }

  // ── Dynamic dropdown widgets ──────────────────────────────────────────────

  /// Hostel name dropdown.
  /// [showAddNew] — only true for Warden form.
  Widget _buildHostelDropdown(
      {required Color accentColor, bool showAddNew = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DropdownButtonFormField<String>(
          value: _isAddingNewHostel ? '__new__' : _selectedHostelName,
          isExpanded: true,
          decoration: _inputDecoration(
              label: 'Hostel Name',
              icon: Icons.domain_outlined,
              accentColor: accentColor),
          items: [
            ..._hostels.map((h) =>
                DropdownMenuItem(value: h, child: Text(h, overflow: TextOverflow.ellipsis))),
            if (showAddNew)
              const DropdownMenuItem(
                value: '__new__',
                child: Text(
                  '+ Add New Hostel',
                  style: TextStyle(
                      color: Colors.green, fontWeight: FontWeight.w600),
                ),
              ),
          ],
          onChanged: (v) {
            setState(() {
              if (v == '__new__') {
                _isAddingNewHostel = true;
                _selectedHostelName = null;
              } else {
                _isAddingNewHostel = false;
                _selectedHostelName = v;
              }
            });
          },
        ),
        if (_isAddingNewHostel && showAddNew) ...[
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _newHostelController,
                  decoration: _inputDecoration(
                    label: 'New Hostel Name *',
                    icon: Icons.add_home_outlined,
                    accentColor: Colors.green,
                  ),
                  validator: (v) => (_isAddingNewHostel && (v == null || v.isEmpty))
                      ? 'Enter hostel name'
                      : null,
                ),
              ),
              const SizedBox(width: 8),
              _isSavingHostel
                  ? const SizedBox(
                      width: 36,
                      height: 36,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : ElevatedButton(
                      onPressed: _saveNewHostel,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                      child: const Text('Save'),
                    ),
            ],
          ),
        ],
      ],
    );
  }

  /// Department dropdown.
  /// [showAddNew] — only true for HOD form.
  Widget _buildDepartmentDropdown(
      {required Color accentColor,
      required bool required,
      bool showAddNew = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DropdownButtonFormField<String>(
          value: _isAddingNewDepartment ? '__new__' : _selectedDepartmentId,
          isExpanded: true,
          decoration: _inputDecoration(
              label: required ? 'Department *' : 'Department',
              icon: Icons.business_outlined,
              accentColor: accentColor),
          items: [
            ..._departments.map((d) => DropdownMenuItem(
                value: d.id,
                child: Text(d.name, overflow: TextOverflow.ellipsis))),
            if (showAddNew)
              const DropdownMenuItem(
                value: '__new__',
                child: Text(
                  '+ Add New Department',
                  style: TextStyle(
                      color: Colors.deepPurple, fontWeight: FontWeight.w600),
                ),
              ),
          ],
          onChanged: (v) {
            setState(() {
              if (v == '__new__') {
                _isAddingNewDepartment = true;
                _selectedDepartmentId = null;
              } else {
                _isAddingNewDepartment = false;
                _selectedDepartmentId = v;
              }
            });
          },
          validator: required
              ? (v) => (!_isAddingNewDepartment && v == null)
                  ? 'Required'
                  : null
              : null,
        ),
        if (_isAddingNewDepartment && showAddNew) ...[
          const SizedBox(height: 10),
          _buildField(
            controller: _newDepartmentController,
            label: 'New Department Name *',
            icon: Icons.add_business_outlined,
            accentColor: Colors.deepPurple,
            validator: (v) =>
                (_isAddingNewDepartment && (v == null || v.isEmpty))
                    ? 'Enter department name'
                    : null,
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _newDepartmentCodeController,
                  textCapitalization: TextCapitalization.characters,
                  decoration: _inputDecoration(
                    label: 'Department Code *',
                    icon: Icons.code_rounded,
                    accentColor: Colors.deepPurple,
                  ),
                  validator: (v) =>
                      (_isAddingNewDepartment && (v == null || v.isEmpty))
                          ? 'Enter code (e.g. CS)'
                          : null,
                  onChanged: (v) {
                    // Force uppercase as they type if needed, 
                    // though textCapitalization handle it mostly.
                    final upper = v.toUpperCase();
                    if (v != upper) {
                      _newDepartmentCodeController.value = 
                        _newDepartmentCodeController.value.copyWith(
                          text: upper,
                          selection: TextSelection.collapsed(offset: upper.length),
                        );
                    }
                  },
                ),
              ),
              const SizedBox(width: 8),
              _isSavingDepartment
                  ? const SizedBox(
                      width: 36,
                      height: 36,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : ElevatedButton(
                      onPressed: _saveNewDepartment,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.deepPurple,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                      child: const Text('Save'),
                    ),
            ],
          ),
        ],
      ],
    );
  }

  // ── Save helpers ──────────────────────────────────────────────────────────

  Future<void> _saveNewHostel() async {
    final name = _newHostelController.text.trim();
    if (name.isEmpty) return;
    setState(() => _isSavingHostel = true);
    // Add to local list immediately (no separate DB table for hostels —
    // the name is stored directly on user records).
    setState(() {
      if (!_hostels.contains(name)) _hostels.add(name);
      _selectedHostelName = name;
      _isAddingNewHostel = false;
      _isSavingHostel = false;
      _newHostelController.clear();
    });
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Hostel "$name" added'),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _saveNewDepartment() async {
    final name = _newDepartmentController.text.trim();
    final code = _newDepartmentCodeController.text.trim().toUpperCase();
    if (name.isEmpty || code.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Name and Code are required')),
      );
      return;
    }
    setState(() => _isSavingDepartment = true);
    try {
      final newDept = await _departmentService.createDepartment(
        name: name,
        departmentCode: code,
      );
      setState(() {
        _departments.add(newDept);
        _departments.sort((a, b) => a.name.compareTo(b.name));
        _selectedDepartmentId = newDept.id;
        _isAddingNewDepartment = false;
        _isSavingDepartment = false;
        _newDepartmentController.clear();
        _newDepartmentCodeController.clear();
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Department "$name" created'),
            backgroundColor: AppConstants.successColor,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      setState(() => _isSavingDepartment = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error creating department: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

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
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      isDense: true,
    );
  }

  // ── Create user (backend call unchanged) ─────────────────────────────────

  Future<void> _createUser() async {
    if (!_formKey.currentState!.validate()) return;
    // If user chose to add a new hostel/department but did not press Save yet,
    // prompt them first.
    if (_isAddingNewHostel && _newHostelController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Please save the new hostel name first'),
            backgroundColor: Colors.orange),
      );
      return;
    }
    if (_isAddingNewDepartment &&
        _newDepartmentController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Please save the new department first'),
            backgroundColor: Colors.orange),
      );
      return;
    }

    setState(() => _isLoading = true);

    // Resolve the effective hostel name (newly typed one if pending save)
    final effectiveHostel = _isAddingNewHostel
        ? _newHostelController.text.trim()
        : _selectedHostelName;

    try {
      await _adminService.createUser(
        email: _emailController.text.trim(),
        // Default password — admin resets it after creation if needed.
        password: 'SmartPass@123',
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
        hostelName:
            (effectiveHostel == null || effectiveHostel.isEmpty)
                ? null
                : effectiveHostel,
        roomNo: _selectedRole == 'student' &&
                _roomNoController.text.trim().isNotEmpty
            ? _roomNoController.text.trim()
            : null,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'User ${_fullNameController.text} created successfully!\nDefault password: SmartPass@123'),
            backgroundColor: AppConstants.successColor,
            duration: const Duration(seconds: 4),
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
    _fullNameController.dispose();
    _phoneController.dispose();
    _homeAddressController.dispose();
    _roomNoController.dispose();
    _newHostelController.dispose();
    _newDepartmentController.dispose();
    _newDepartmentCodeController.dispose();
    super.dispose();
  }
}
