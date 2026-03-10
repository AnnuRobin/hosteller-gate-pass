import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:convert';
import '../../services/admin_service.dart';
import '../../services/department_service.dart';
import '../../models/department_model.dart';
import '../../models/user_model.dart';
import '../../utils/constants.dart';
import '../../utils/csv_helper.dart';

class BulkCreateClassScreen extends StatefulWidget {
  const BulkCreateClassScreen({Key? key}) : super(key: key);

  @override
  State<BulkCreateClassScreen> createState() => _BulkCreateClassScreenState();
}

class _BulkCreateClassScreenState extends State<BulkCreateClassScreen> {
  final AdminService _adminService = AdminService();
  final DepartmentService _departmentService = DepartmentService();
  
  // Step tracking
  int _currentStep = 0;
  
  // Class metadata
  String? _selectedDepartmentId;
  int? _selectedSemester;
  String _selectedSection = 'A';
  // Special sentinel value for 'Add New' options
  static const String _kAddNewDept = '__add_new_dept__';
  static const String _kAddNewAdvisor = '__add_new_advisor__';
  String? _selectedAdvisorId;
  String? _selectedHodId;
  String? _selectedWardenId;
  
  // Data
  List<DepartmentModel> _departments = [];
  List<UserModel> _advisors = [];
  List<UserModel> _hods = [];
  List<UserModel> _wardens = [];
  List<Map<String, dynamic>> _students = [];
  
  // UI state
  bool _isLoading = false;
  String? _errorMessage;
  String _searchQuery = '';
  int _selectedTab = 0; // 0 = CSV, 1 = Manual
  
  // Manual entry controllers
  final _manualEmailController = TextEditingController();
  final _manualNameController = TextEditingController();
  final _manualPhoneController = TextEditingController();
  final _manualAddressController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    setState(() => _isLoading = true);
    try {
      final departments = await _departmentService.getAllDepartments();
      final allUsers = await _adminService.getAllUsers();
      
      setState(() {
        _departments = departments;
        _advisors = allUsers.where((u) => u.role == 'advisor').toList();
        _hods = allUsers.where((u) => u.role == 'hod').toList();
        _wardens = allUsers.where((u) => u.role == 'warden').toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Error loading data: $e';
        _isLoading = false;
      });
    }
  }

@override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: AppBar(
        title: const Text('Bulk Create Class'),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadInitialData,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? _buildErrorState()
              : Column(
                  children: [
                    // Gradient hero header
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [AppConstants.primaryColor, AppConstants.primaryColor.withOpacity(0.7)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 56,
                            height: 56,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.25),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.group_add_rounded, color: Colors.white, size: 28),
                          ),
                          const SizedBox(width: 16),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Bulk Create Class',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Create a class and add multiple students',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.85),
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Theme(
                        data: Theme.of(context).copyWith(
                          colorScheme: ColorScheme.light(primary: AppConstants.primaryColor),
                        ),
                        child: Stepper(
                          currentStep: _currentStep,
                          onStepContinue: _onStepContinue,
                          onStepCancel: _onStepCancel,
                          controlsBuilder: _buildStepControls,
                          steps: [
                            Step(
                              title: const Text('Class Setup'),
                              content: _buildClassSetupStep(),
                              isActive: _currentStep >= 0,
                              state: _currentStep > 0 ? StepState.complete : StepState.indexed,
                            ),
                            Step(
                              title: const Text('Add Students'),
                              content: _buildAddStudentsStep(),
                              isActive: _currentStep >= 1,
                              state: _currentStep > 1 ? StepState.complete : StepState.indexed,
                            ),
                            Step(
                              title: const Text('Review & Create'),
                              content: _buildReviewStep(),
                              isActive: _currentStep >= 2,
                              state: _currentStep > 2 ? StepState.complete : StepState.indexed,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 64, color: Colors.red),
          const SizedBox(height: 16),
          Text(_errorMessage!, style: const TextStyle(color: Colors.red)),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _loadInitialData,
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

Widget _buildClassSetupStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildCard(
          sectionColor: const Color(0xFF3B82F6),
          icon: Icons.apartment_rounded,
          title: 'Class Settings',
          children: [
            DropdownButtonFormField<String>(
              value: _selectedDepartmentId,
              isExpanded: true,
              decoration: _inputDecoration(
                label: 'Department *',
                icon: Icons.business_outlined,
                accentColor: const Color(0xFF3B82F6),
              ),
              items: [
                ..._departments.map((dept) => DropdownMenuItem(value: dept.id, child: Text(dept.name))),
                const DropdownMenuItem(
                  value: _kAddNewDept,
                  child: Text('+ Add New Department', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                ),
              ],
              onChanged: (value) async {
                if (value == _kAddNewDept) {
                  await _showAddDepartmentDialog();
                } else {
                  setState(() => _selectedDepartmentId = value);
                }
              },
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<int>(
                    value: _selectedSemester,
                    decoration: _inputDecoration(
                      label: 'Semester *',
                      icon: Icons.layers_outlined,
                      accentColor: const Color(0xFF3B82F6),
                    ),
                    items: List.generate(8, (i) => DropdownMenuItem(value: i + 1, child: Text('Sem '))),
                    onChanged: (value) => setState(() => _selectedSemester = value),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _selectedSection,
                    decoration: _inputDecoration(
                      label: 'Section *',
                      icon: Icons.class_outlined,
                      accentColor: const Color(0xFF3B82F6),
                    ),
                    items: ['A', 'B', 'C', 'D', 'E'].map((s) => DropdownMenuItem(value: s, child: Text('Sec '))).toList(),
                    onChanged: (value) => setState(() => _selectedSection = value!),
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 16),
        _buildCard(
          sectionColor: const Color(0xFF8B5CF6),
          icon: Icons.manage_accounts_rounded,
          title: 'Assign Roles',
          children: [
            DropdownButtonFormField<String>(
              value: _selectedAdvisorId,
              isExpanded: true,
              decoration: _inputDecoration(
                label: 'Advisor',
                icon: Icons.person_pin_rounded,
                accentColor: const Color(0xFF8B5CF6),
              ),
              items: [
                ..._advisors.map((advisor) => DropdownMenuItem(value: advisor.id, child: Text(advisor.fullName))),
                const DropdownMenuItem(
                  value: _kAddNewAdvisor,
                  child: Text('+ Create New Advisor', style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold)),
                ),
              ],
              onChanged: (value) async {
                if (value == _kAddNewAdvisor) {
                  await _showCreateAdvisorDialog();
                } else {
                  setState(() => _selectedAdvisorId = value);
                }
              },
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _selectedHodId,
                    isExpanded: true,
                    decoration: _inputDecoration(
                      label: 'HOD',
                      icon: Icons.account_balance_rounded,
                      accentColor: const Color(0xFF8B5CF6),
                    ),
                    items: _hods.map((hod) => DropdownMenuItem(value: hod.id, child: Text(hod.fullName, overflow: TextOverflow.ellipsis))).toList(),
                    onChanged: (value) => setState(() => _selectedHodId = value),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _selectedWardenId,
                    isExpanded: true,
                    decoration: _inputDecoration(
                      label: 'Warden',
                      icon: Icons.security_rounded,
                      accentColor: const Color(0xFF8B5CF6),
                    ),
                    items: _wardens.map((w) => DropdownMenuItem(value: w.id, child: Text(w.fullName, overflow: TextOverflow.ellipsis))).toList(),
                    onChanged: (value) => setState(() => _selectedWardenId = value),
                  ),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildAddStudentsStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Tab selector
        Container(
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Expanded(
                child: _buildTabButton('CSV Import', 0, Icons.upload_file),
              ),
              Expanded(
                child: _buildTabButton('Manual Entry', 1, Icons.edit),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // Tab content
        if (_selectedTab == 0) _buildCsvImportTab() else _buildManualEntryTab(),

        const SizedBox(height: 24),

        // Search bar and student list
        if (_students.isNotEmpty) ...[
          const Divider(),
          const SizedBox(height: 16),
          _buildSearchBar(),
          const SizedBox(height: 16),
          _buildStudentsList(),
        ],
      ],
    );
  }

  Widget _buildTabButton(String label, int index, IconData icon) {
    final isSelected = _selectedTab == index;
    return InkWell(
      onTap: () => setState(() => _selectedTab = index),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? AppConstants.primaryColor : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isSelected ? Colors.white : Colors.grey[700],
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.grey[700],
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCsvImportTab() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Download template button
        OutlinedButton.icon(
          onPressed: _downloadTemplate,
          icon: const Icon(Icons.download),
          label: const Text('Download CSV Template'),
        ),
        const SizedBox(height: 16),

        // Upload CSV button
        ElevatedButton.icon(
          onPressed: _pickCsvFile,
          icon: const Icon(Icons.upload_file),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppConstants.primaryColor,
            padding: const EdgeInsets.symmetric(vertical: 16),
          ),
          label: const Text('Upload CSV File'),
        ),
        const SizedBox(height: 16),

        // CSV format info
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.blue[50],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.blue[200]!),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.blue[700], size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'CSV Format',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.blue[700],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Required columns: email, full_name\nOptional columns: phone, home_address',
                style: TextStyle(fontSize: 12, color: Colors.grey[700]),
              ),
            ],
          ),
        ),
      ],
    );
  }

Widget _buildManualEntryTab() {
    return _buildCard(
      sectionColor: AppConstants.primaryColor,
      icon: Icons.edit_note_rounded,
      title: 'Manual Student Entry',
      children: [
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _manualEmailController,
                decoration: _inputDecoration(
                  label: 'Email *',
                  icon: Icons.email_outlined,
                  accentColor: AppConstants.primaryColor,
                ),
                keyboardType: TextInputType.emailAddress,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextFormField(
                controller: _manualNameController,
                decoration: _inputDecoration(
                  label: 'Full Name *',
                  icon: Icons.badge_outlined,
                  accentColor: AppConstants.primaryColor,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _manualPhoneController,
                decoration: _inputDecoration(
                  label: 'Phone',
                  icon: Icons.phone_outlined,
                  accentColor: AppConstants.primaryColor,
                ),
                keyboardType: TextInputType.phone,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextFormField(
                controller: _manualAddressController,
                decoration: _inputDecoration(
                  label: 'Home Address',
                  icon: Icons.home_outlined,
                  accentColor: AppConstants.primaryColor,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        ElevatedButton.icon(
          onPressed: _addManualStudent,
          icon: const Icon(Icons.add),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppConstants.successColor,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
          label: const Text('Add Student to List'),
        ),
      ],
    );
  }

  Widget _buildSearchBar() {
    return TextField(
      decoration: InputDecoration(
        hintText: 'Search students...',
        prefixIcon: const Icon(Icons.search),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        filled: true,
        fillColor: Colors.grey[100],
      ),
      onChanged: (value) => setState(() => _searchQuery = value),
    );
  }

  Widget _buildStudentsList() {
    final filteredStudents = _students.where((student) {
      if (_searchQuery.isEmpty) return true;
      final query = _searchQuery.toLowerCase();
      final email = student['email']?.toString().toLowerCase() ?? '';
      final name = student['full_name']?.toString().toLowerCase() ?? '';
      return email.contains(query) || name.contains(query);
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${filteredStudents.length} student(s) added',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Container(
          constraints: const BoxConstraints(maxHeight: 300),
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: filteredStudents.length,
            itemBuilder: (context, index) {
              final student = filteredStudents[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: AppConstants.primaryColor,
                    child: Text(
                      student['full_name']?[0]?.toUpperCase() ?? '?',
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                  title: Text(student['full_name'] ?? 'Unknown'),
                  subtitle: Text(student['email'] ?? ''),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () => _removeStudent(student),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

Widget _buildReviewStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _buildCard(
                sectionColor: const Color(0xFF3B82F6),
                icon: Icons.apartment_rounded,
                title: 'Class Info',
                children: [
                  _buildReviewRow('Department', _getDepartmentName()),
                  _buildReviewRow('Semester', _selectedSemester?.toString() ?? 'N/A'),
                  _buildReviewRow('Section', _selectedSection),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildCard(
                sectionColor: const Color(0xFF8B5CF6),
                icon: Icons.manage_accounts_rounded,
                title: 'Roles',
                children: [
                  _buildReviewRow('Advisor', _getAdvisorName()),
                  _buildReviewRow('HOD', _getHodName()),
                  _buildReviewRow('Warden', _getWardenName()),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _buildCard(
          sectionColor: AppConstants.successColor,
          icon: Icons.groups_rounded,
          title: 'Students Overview',
          children: [
            _buildReviewRow('Total Students', _students.length.toString()),
          ],
        ),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.orange.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.orange.withOpacity(0.3)),
          ),
          child: Row(
            children: [
              Icon(Icons.lock_reset_rounded, color: Colors.orange[700]),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'All students will receive the default password: student123.\\nThey can change it after their first login.',
                  style: TextStyle(fontSize: 13, color: Colors.orange[800], fontWeight: FontWeight.w500),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildReviewRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 13)),
          Flexible(child: Text(value, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13), textAlign: TextAlign.right, overflow: TextOverflow.ellipsis)),
        ],
      ),
    );
  }

  Widget _buildStepControls(BuildContext context, ControlsDetails details) {
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Row(
        children: [
          if (_currentStep > 0)
            OutlinedButton(
              onPressed: details.onStepCancel,
              child: const Text('Back'),
            ),
          const SizedBox(width: 12),
          ElevatedButton(
            onPressed: details.onStepContinue,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppConstants.primaryColor,
            ),
            child: Text(_currentStep == 2 ? 'Create Class' : 'Continue'),
          ),
        ],
      ),
    );
  }

  void _onStepContinue() {
    if (_currentStep == 0) {
      if (!_validateClassSetup()) return;
      setState(() => _currentStep = 1);
    } else if (_currentStep == 1) {
      if (_students.isEmpty) {
        _showError('Please add at least one student');
        return;
      }
      setState(() => _currentStep = 2);
    } else if (_currentStep == 2) {
      _createClass();
    }
  }

  void _onStepCancel() {
    if (_currentStep > 0) {
      setState(() => _currentStep -= 1);
    }
  }

  bool _validateClassSetup() {
    if (_selectedDepartmentId == null) {
      _showError('Please select a department');
      return false;
    }
    if (_selectedSemester == null) {
      _showError('Please select a semester');
      return false;
    }
    return true;
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  /// Shows a dialog to add a new department inline.
  Future<void> _showAddDepartmentDialog() async {
    final nameController = TextEditingController();
    final descController = TextEditingController();
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.business, color: Colors.green),
            SizedBox(width: 8),
            Text('Add New Department'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Department Name *',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.label),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: descController,
              decoration: const InputDecoration(
                labelText: 'Description (optional)',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.description),
              ),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            onPressed: () async {
              if (nameController.text.trim().isEmpty) {
                ScaffoldMessenger.of(ctx).showSnackBar(
                  const SnackBar(content: Text('Department name is required'), backgroundColor: Colors.red),
                );
                return;
              }
              Navigator.pop(ctx, true);
            },
            child: const Text('Create', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (result == true) {
      try {
        setState(() => _isLoading = true);
        await _departmentService.createDepartment(
          name: nameController.text.trim(),
          description: descController.text.trim().isEmpty ? null : descController.text.trim(),
        );
        // Reload departments
        final departments = await _departmentService.getAllDepartments();
        setState(() {
          _departments = departments;
          _selectedDepartmentId = departments.isNotEmpty ? departments.last.id : null;
          _isLoading = false;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Department "${nameController.text.trim()}" created!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        setState(() => _isLoading = false);
        _showError('Failed to create department: $e');
      }
    }
    nameController.dispose();
    descController.dispose();
  }

  /// Shows a dialog to create a new Advisor user inline.
  Future<void> _showCreateAdvisorDialog() async {
    final nameController = TextEditingController();
    final emailController = TextEditingController();
    final phoneController = TextEditingController();
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.person_add_alt_1, color: Colors.blue),
            SizedBox(width: 8),
            Text('Create New Advisor'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Full Name *',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.person),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: emailController,
              decoration: const InputDecoration(
                labelText: 'Email *',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.email),
              ),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: phoneController,
              decoration: const InputDecoration(
                labelText: 'Phone (optional)',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.phone),
              ),
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline, size: 16, color: Colors.blue),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Default password: advisor123',
                      style: TextStyle(fontSize: 12, color: Colors.blue),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
            onPressed: () async {
              if (nameController.text.trim().isEmpty || emailController.text.trim().isEmpty) {
                ScaffoldMessenger.of(ctx).showSnackBar(
                  const SnackBar(content: Text('Name and email are required'), backgroundColor: Colors.red),
                );
                return;
              }
              Navigator.pop(ctx, true);
            },
            child: const Text('Create', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (result == true) {
      try {
        setState(() => _isLoading = true);
        await _adminService.createUser(
          email: emailController.text.trim(),
          password: 'advisor123',
          fullName: nameController.text.trim(),
          role: 'advisor',
          phone: phoneController.text.trim().isEmpty ? null : phoneController.text.trim(),
          departmentId: _selectedDepartmentId,
        );
        // Reload users list and select the new advisor
        final allUsers = await _adminService.getAllUsers();
        final newAdvisor = allUsers.firstWhere(
          (u) => u.email == emailController.text.trim(),
          orElse: () => allUsers.where((u) => u.role == 'advisor').last,
        );
        setState(() {
          _advisors = allUsers.where((u) => u.role == 'advisor').toList();
          _selectedAdvisorId = newAdvisor.id;
          _isLoading = false;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Advisor "${nameController.text.trim()}" created and selected!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        setState(() => _isLoading = false);
        _showError('Failed to create advisor: $e');
      }
    }
    nameController.dispose();
    emailController.dispose();
    phoneController.dispose();
  }

  void _downloadTemplate() {
    final template = CsvHelper.generateTemplate();
    // In a real app, you'd save this to a file
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Template format:\nemail,full_name,phone,home_address'),
        duration: const Duration(seconds: 5),
        backgroundColor: AppConstants.successColor,
      ),
    );
  }

  Future<void> _pickCsvFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv'],
      );

      if (result != null && result.files.single.bytes != null) {
        final csvString = utf8.decode(result.files.single.bytes!);
        final students = CsvHelper.parseStudentsCsv(csvString);
        
        // Validate students
        final errors = CsvHelper.validateAllStudents(students);
        if (errors.isNotEmpty) {
          _showError('CSV validation errors:\n${errors.take(3).join('\n')}');
          return;
        }

        setState(() => _students.addAll(students));
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${students.length} students imported successfully'),
            backgroundColor: AppConstants.successColor,
          ),
        );
      }
    } catch (e) {
      _showError('Error importing CSV: $e');
    }
  }

  void _addManualStudent() {
    if (_manualEmailController.text.isEmpty || _manualNameController.text.isEmpty) {
      _showError('Email and Full Name are required');
      return;
    }

    final student = {
      'email': _manualEmailController.text.trim(),
      'full_name': _manualNameController.text.trim(),
      if (_manualPhoneController.text.isNotEmpty)
        'phone': _manualPhoneController.text.trim(),
      if (_manualAddressController.text.isNotEmpty)
        'home_address': _manualAddressController.text.trim(),
    };

    // Validate
    final errors = CsvHelper.validateStudent(student, _students.length);
    if (errors.isNotEmpty) {
      _showError(errors.first);
      return;
    }

    setState(() => _students.add(student));
    
    // Clear form
    _manualEmailController.clear();
    _manualNameController.clear();
    _manualPhoneController.clear();
    _manualAddressController.clear();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${student['full_name']} added'),
        backgroundColor: AppConstants.successColor,
      ),
    );
  }

  void _removeStudent(Map<String, dynamic> student) {
    setState(() => _students.remove(student));
  }

  Future<void> _createClass() async {
    setState(() => _isLoading = true);

    try {
      final result = await _adminService.bulkCreateStudents(
        students: _students,
        departmentId: _selectedDepartmentId!,
        semester: _selectedSemester!,
        section: _selectedSection,
      );

      final successCount = result['success_count'] ?? 0;
      final failureCount = result['failure_count'] ?? 0;

      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Class Created'),
            content: Text(
              'Successfully created: $successCount students\n'
              'Failed: $failureCount students',
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.pop(context, true);
                },
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      _showError('Error creating class: $e');
    }
  }

  String _getDepartmentName() {
    return _departments
        .firstWhere((d) => d.id == _selectedDepartmentId, orElse: () => DepartmentModel(id: '', name: 'N/A', createdAt: DateTime.now()))
        .name;
  }

  String _getAdvisorName() {
    if (_selectedAdvisorId == null) return 'Not assigned';
    return _advisors
        .firstWhere((a) => a.id == _selectedAdvisorId, orElse: () => UserModel(id: '', email: '', fullName: 'N/A', role: '', createdAt: DateTime.now()))
        .fullName;
  }

  String _getHodName() {
    if (_selectedHodId == null) return 'Not assigned';
    return _hods
        .firstWhere((h) => h.id == _selectedHodId, orElse: () => UserModel(id: '', email: '', fullName: 'N/A', role: '', createdAt: DateTime.now()))
        .fullName;
  }

  String _getWardenName() {
    if (_selectedWardenId == null) return 'Not assigned';
    return _wardens
        .firstWhere((w) => w.id == _selectedWardenId, orElse: () => UserModel(id: '', email: '', fullName: 'N/A', role: '', createdAt: DateTime.now()))
        .fullName;
  }

//  Helpers 

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
            color: Colors.black.withOpacity(0.05),
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
              color: sectionColor.withOpacity(0.08),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
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

  @override
  void dispose() {
    _manualEmailController.dispose();
    _manualNameController.dispose();
    _manualPhoneController.dispose();
    _manualAddressController.dispose();
    super.dispose();
  }
}
