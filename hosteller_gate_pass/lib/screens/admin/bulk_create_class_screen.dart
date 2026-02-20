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
      appBar: AppBar(
        title: const Text('Bulk Create Class'),
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
        // Department
        DropdownButtonFormField<String>(
          value: _selectedDepartmentId,
          decoration: const InputDecoration(
            labelText: 'Department *',
            prefixIcon: Icon(Icons.business),
            border: OutlineInputBorder(),
          ),
          items: _departments.map((dept) {
            return DropdownMenuItem(
              value: dept.id,
              child: Text(dept.name),
            );
          }).toList(),
          onChanged: (value) => setState(() => _selectedDepartmentId = value),
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
          items: List.generate(8, (index) {
            return DropdownMenuItem(
              value: index + 1,
              child: Text('Semester ${index + 1}'),
            );
          }),
          onChanged: (value) => setState(() => _selectedSemester = value),
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
          items: ['A', 'B', 'C', 'D', 'E'].map((section) {
            return DropdownMenuItem(
              value: section,
              child: Text('Section $section'),
            );
          }).toList(),
          onChanged: (value) => setState(() => _selectedSection = value!),
        ),
        const SizedBox(height: 24),

        const Divider(),
        const SizedBox(height: 16),
        const Text(
          'Assign Roles',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),

        // Advisor
        DropdownButtonFormField<String>(
          value: _selectedAdvisorId,
          decoration: const InputDecoration(
            labelText: 'Advisor',
            prefixIcon: Icon(Icons.person),
            border: OutlineInputBorder(),
          ),
          items: _advisors.map((advisor) {
            return DropdownMenuItem(
              value: advisor.id,
              child: Text(advisor.fullName),
            );
          }).toList(),
          onChanged: (value) => setState(() => _selectedAdvisorId = value),
        ),
        const SizedBox(height: 16),

        // HOD
        DropdownButtonFormField<String>(
          value: _selectedHodId,
          decoration: const InputDecoration(
            labelText: 'HOD',
            prefixIcon: Icon(Icons.person_outline),
            border: OutlineInputBorder(),
          ),
          items: _hods.map((hod) {
            return DropdownMenuItem(
              value: hod.id,
              child: Text(hod.fullName),
            );
          }).toList(),
          onChanged: (value) => setState(() => _selectedHodId = value),
        ),
        const SizedBox(height: 16),

        // Warden
        DropdownButtonFormField<String>(
          value: _selectedWardenId,
          decoration: const InputDecoration(
            labelText: 'Warden',
            prefixIcon: Icon(Icons.security),
            border: OutlineInputBorder(),
          ),
          items: _wardens.map((warden) {
            return DropdownMenuItem(
              value: warden.id,
              child: Text(warden.fullName),
            );
          }).toList(),
          onChanged: (value) => setState(() => _selectedWardenId = value),
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
