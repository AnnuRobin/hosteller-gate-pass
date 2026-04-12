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
  static const String _kAddNewHod = '__add_new_hod__';
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
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: AppConstants.primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Bulk Create Class',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _loadInitialData,
          ),
        ],
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _errorMessage != null
                ? _buildErrorState()
                : Stepper(
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

  // ── Shared input decoration ───────────────────────────────────────────────
  InputDecoration _fieldDecoration({
    required String label,
    required IconData icon,
  }) {
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(fontSize: 13, color: Colors.grey[600]),
      prefixIcon: Icon(icon, size: 18, color: AppConstants.primaryColor),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: Colors.grey[300]!),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: AppConstants.primaryColor, width: 1.8),
      ),
      filled: true,
      fillColor: Colors.grey[50],
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      isDense: true,
    );
  }

  // ── Section card builder ──────────────────────────────────────────────────
  Widget _buildSectionCard({
    required IconData icon,
    required String title,
    required Color color,
    required List<Widget> children,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.08),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(14)),
              border: Border(left: BorderSide(color: color, width: 3)),
            ),
            child: Row(
              children: [
                Icon(icon, size: 15, color: color),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: color,
                    letterSpacing: 0.3,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: children,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildClassSetupStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ── Class Setup card ──────────────────────────────────────────
        _buildSectionCard(
          icon: Icons.class_outlined,
          title: 'CLASS SETUP',
          color: AppConstants.primaryColor,
          children: [
            // Department
            DropdownButtonFormField<String>(
              value: _selectedDepartmentId,
              isExpanded: true,
              decoration: _fieldDecoration(
                  label: 'Department *', icon: Icons.business_outlined),
              items: [
                ..._departments.map((dept) => DropdownMenuItem(
                      value: dept.id,
                      child:
                          Text(dept.name, overflow: TextOverflow.ellipsis),
                    )),
                const DropdownMenuItem(
                  value: _kAddNewDept,
                  child: Text(
                    '+ Add New Department',
                    style: TextStyle(
                        color: Colors.green, fontWeight: FontWeight.w600),
                  ),
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

            // Semester + Section in a row
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<int>(
                    value: _selectedSemester,
                    decoration: _fieldDecoration(
                        label: 'Semester *', icon: Icons.layers_outlined),
                    items: List.generate(
                        8,
                        (i) => DropdownMenuItem(
                            value: i + 1,
                            child: Text('Sem ${i + 1}'))),
                    onChanged: (v) =>
                        setState(() => _selectedSemester = v),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _selectedSection,
                    decoration: _fieldDecoration(
                        label: 'Section *', icon: Icons.class_outlined),
                    items: ['A', 'B', 'C', 'D', 'E']
                        .map((s) => DropdownMenuItem(
                            value: s, child: Text('Section $s')))
                        .toList(),
                    onChanged: (v) =>
                        setState(() => _selectedSection = v!),
                  ),
                ),
              ],
            ),
          ],
        ),

        const SizedBox(height: 16),

        // ── Assign Roles card ─────────────────────────────────────────
        _buildSectionCard(
          icon: Icons.people_outline_rounded,
          title: 'ASSIGN ROLES',
          color: const Color(0xFF8B5CF6),
          children: [
            // Advisor
            DropdownButtonFormField<String>(
              value: _selectedAdvisorId,
              isExpanded: true,
              decoration: _fieldDecoration(
                  label: 'Advisor', icon: Icons.person_pin_outlined),
              items: [
                ..._advisors.map((a) {
                  final dept = _departments.firstWhere(
                    (d) => d.id == a.departmentId,
                    orElse: () => DepartmentModel(id: '', name: '', createdAt: DateTime.now()),
                  );
                  final deptCode = dept.departmentCode ?? 'NA';
                  return DropdownMenuItem(
                    value: a.id,
                    child: Text('${a.fullName} ($deptCode)',
                        overflow: TextOverflow.ellipsis),
                  );
                }),
                const DropdownMenuItem(
                  value: _kAddNewAdvisor,
                  child: Text(
                    '+ Create New Advisor',
                    style: TextStyle(
                        color: Colors.blue, fontWeight: FontWeight.w600),
                  ),
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

            // HOD
            DropdownButtonFormField<String>(
              value: _selectedHodId,
              isExpanded: true,
              decoration: _fieldDecoration(
                  label: 'HOD', icon: Icons.account_balance_outlined),
              items: [
                ..._hods.map((h) {
                  final dept = _departments.firstWhere(
                    (d) => d.id == h.departmentId,
                    orElse: () => DepartmentModel(id: '', name: '', createdAt: DateTime.now()),
                  );
                  final deptCode = dept.departmentCode ?? 'NA';
                  return DropdownMenuItem(
                    value: h.id,
                    child: Text('${h.fullName} ($deptCode)',
                        overflow: TextOverflow.ellipsis),
                  );
                }),
                const DropdownMenuItem(
                  value: _kAddNewHod,
                  child: Text(
                    '+ Create New HOD',
                    style: TextStyle(
                        color: Colors.amber,
                        fontWeight: FontWeight.w600),
                  ),
                ),
              ],
              onChanged: (value) async {
                if (value == _kAddNewHod) {
                  await _showCreateHodDialog();
                } else {
                  setState(() => _selectedHodId = value);
                }
              },
            ),
            const SizedBox(height: 14),

            // Warden
            DropdownButtonFormField<String>(
              value: _selectedWardenId,
              isExpanded: true,
              decoration: _fieldDecoration(
                  label: 'Warden', icon: Icons.security_outlined),
              items: _wardens
                  .map((w) => DropdownMenuItem(
                        value: w.id,
                        child: Text(w.fullName,
                            overflow: TextOverflow.ellipsis),
                      ))
                  .toList(),
              onChanged: (v) =>
                  setState(() => _selectedWardenId = v),
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextFormField(
          controller: _manualEmailController,
          decoration: const InputDecoration(
            labelText: 'Email *',
            prefixIcon: Icon(Icons.email),
            border: OutlineInputBorder(),
          ),
          keyboardType: TextInputType.emailAddress,
        ),
        const SizedBox(height: 16),

        TextFormField(
          controller: _manualNameController,
          decoration: const InputDecoration(
            labelText: 'Full Name *',
            prefixIcon: Icon(Icons.person),
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 16),

        TextFormField(
          controller: _manualPhoneController,
          decoration: const InputDecoration(
            labelText: 'Phone',
            prefixIcon: Icon(Icons.phone),
            border: OutlineInputBorder(),
          ),
          keyboardType: TextInputType.phone,
        ),
        const SizedBox(height: 16),

        TextFormField(
          controller: _manualAddressController,
          decoration: const InputDecoration(
            labelText: 'Home Address',
            prefixIcon: Icon(Icons.home),
            border: OutlineInputBorder(),
          ),
          maxLines: 2,
        ),
        const SizedBox(height: 16),

        ElevatedButton.icon(
          onPressed: _addManualStudent,
          icon: const Icon(Icons.add),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppConstants.successColor,
            padding: const EdgeInsets.symmetric(vertical: 16),
          ),
          label: const Text('Add Student'),
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
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildReviewCard(
          'Class Information',
          [
            _buildReviewRow('Department', _getDepartmentName()),
            _buildReviewRow('Semester', _selectedSemester?.toString() ?? 'N/A'),
            _buildReviewRow('Section', _selectedSection),
          ],
        ),
        const SizedBox(height: 16),

        _buildReviewCard(
          'Role Assignments',
          [
            _buildReviewRow('Advisor', _getAdvisorName()),
            _buildReviewRow('HOD', _getHodName()),
            _buildReviewRow('Warden', _getWardenName()),
          ],
        ),
        const SizedBox(height: 16),

        _buildReviewCard(
          'Students',
          [
            _buildReviewRow('Total Students', _students.length.toString()),
          ],
        ),
        const SizedBox(height: 24),

        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.orange[50],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.orange[200]!),
          ),
          child: Row(
            children: [
              Icon(Icons.info_outline, color: Colors.orange[700]),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'All students will receive default password: student123\nThey can change it after first login.',
                  style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildReviewCard(String title, List<Widget> children) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildReviewRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey[600])),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
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
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                    horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text('Back'),
            ),
          if (_currentStep > 0) const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton(
              onPressed: details.onStepContinue,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppConstants.primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 13),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
                elevation: 2,
              ),
              child: Text(
                _currentStep == 2 ? 'Create Class' : 'Continue',
                style: const TextStyle(
                    fontWeight: FontWeight.bold, fontSize: 15),
              ),
            ),
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
    final codeController = TextEditingController();
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
              controller: codeController,
              textCapitalization: TextCapitalization.characters,
              decoration: const InputDecoration(
                labelText: 'Department Code *',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.code),
              ),
              onChanged: (v) {
                final upper = v.toUpperCase();
                if (v != upper) {
                  codeController.value = codeController.value.copyWith(
                    text: upper,
                    selection: TextSelection.collapsed(offset: upper.length),
                  );
                }
              },
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            onPressed: () async {
              if (nameController.text.trim().isEmpty || codeController.text.trim().isEmpty) {
                ScaffoldMessenger.of(ctx).showSnackBar(
                  const SnackBar(content: Text('Name and Code are required'), backgroundColor: Colors.red),
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
          departmentCode: codeController.text.trim().toUpperCase(),
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
    codeController.dispose();
  }

  /// Shows a dialog to create a new HOD user inline.
  Future<void> _showCreateHodDialog() async {
    final nameController = TextEditingController();
    final emailController = TextEditingController();
    final phoneController = TextEditingController();
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.account_balance, color: Colors.amber),
            SizedBox(width: 8),
            Text('Create New HOD'),
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
                color: Colors.amber[50],
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline, size: 16, color: Colors.amber),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Default password: SmartPass@123',
                      style: TextStyle(fontSize: 12, color: Colors.amber),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          ElevatedButton(
            style:
                ElevatedButton.styleFrom(backgroundColor: Colors.amber),
            onPressed: () {
              if (nameController.text.trim().isEmpty ||
                  emailController.text.trim().isEmpty) {
                ScaffoldMessenger.of(ctx).showSnackBar(
                  const SnackBar(
                      content: Text('Name and email are required'),
                      backgroundColor: Colors.red),
                );
                return;
              }
              Navigator.pop(ctx, true);
            },
            child: const Text('Create',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (result == true) {
      try {
        setState(() => _isLoading = true);
        await _adminService.createUser(
          email: emailController.text.trim(),
          password: 'SmartPass@123',
          fullName: nameController.text.trim(),
          role: 'hod',
          phone: phoneController.text.trim().isEmpty
              ? null
              : phoneController.text.trim(),
          departmentId: _selectedDepartmentId,
        );
        final allUsers = await _adminService.getAllUsers();
        final newHod = allUsers.firstWhere(
          (u) => u.email == emailController.text.trim(),
          orElse: () =>
              allUsers.where((u) => u.role == 'hod').last,
        );
        setState(() {
          _hods = allUsers.where((u) => u.role == 'hod').toList();
          _selectedHodId = newHod.id;
          _isLoading = false;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                  'HOD "${nameController.text.trim()}" created and selected!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        setState(() => _isLoading = false);
        _showError('Failed to create HOD: $e');
      }
    }
    nameController.dispose();
    emailController.dispose();
    phoneController.dispose();
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

  @override
  void dispose() {
    _manualEmailController.dispose();
    _manualNameController.dispose();
    _manualPhoneController.dispose();
    _manualAddressController.dispose();
    super.dispose();
  }
}
