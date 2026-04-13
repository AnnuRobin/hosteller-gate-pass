import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/student_management_service.dart';
import '../../utils/constants.dart';

class AddStudentScreen extends StatefulWidget {
  final VoidCallback? onStudentCreated;
  final VoidCallback? onBack;

  const AddStudentScreen({Key? key, this.onStudentCreated, this.onBack}) : super(key: key);

  @override
  State<AddStudentScreen> createState() => _AddStudentScreenState();
}

class _AddStudentScreenState extends State<AddStudentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _service = StudentManagementService();

  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _roomNoController = TextEditingController();
  final _homeAddressController = TextEditingController();
  final _parentPhoneController = TextEditingController();

  String? _selectedSemester;
  String? _selectedSection;
  String? _selectedHostel;
  bool _isSubmitting = false;
  bool _isLoadingHostels = true;

  List<String> _hostels = [];

  @override
  void initState() {
    super.initState();
    _loadHostels();
  }

  Future<void> _loadHostels() async {
    try {
      final hostels = await _service.getHostels();
      if (mounted) {
        setState(() {
          _hostels = hostels;
          _isLoadingHostels = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingHostels = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text('Add Student'),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: AppConstants.primaryColor,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: widget.onBack ?? () => Navigator.of(context).maybePop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.all(Radius.circular(18)),
                  boxShadow: [
                    BoxShadow(
                      color: Color(0x0D000000),
                      blurRadius: 12,
                      offset: Offset(0, 6),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      'Add Student',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1E3A8A),
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Fill out the student details below and submit to register a new student for your class.',
                      style: TextStyle(
                        fontSize: 14,
                        color: Color(0xFF64748B),
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Form(
                key: _formKey,
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.all(Radius.circular(18)),
                    boxShadow: [
                      BoxShadow(
                        color: Color(0x0D000000),
                        blurRadius: 12,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildInputField(
                        controller: _nameController,
                        label: 'Full Name',
                        hintText: 'John Doe',
                        icon: Icons.person,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter full name';
                          }
                          final trimmed = value.trim();
                          if (!RegExp(r'^[A-Z][a-zA-Z ]*$').hasMatch(trimmed)) {
                            return 'Name should start with a capital letter';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      _buildInputField(
                        controller: _emailController,
                        label: 'Email',
                        hintText: 'admin@example.com',
                        icon: Icons.email,
                        keyboardType: TextInputType.emailAddress,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter email';
                          }
                          final trimmed = value.trim();
                          if (!trimmed.contains('@') ||
                              !trimmed.contains('.')) {
                            return 'Please enter a valid email';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      _buildInputField(
                        controller: _passwordController,
                        label: 'Initial Password',
                        hintText: 'Enter student password',
                        icon: Icons.lock,
                        obscureText: true,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter a password';
                          }
                          if (value.length < 6) {
                            return 'Password must be at least 6 characters';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      _buildInputField(
                        controller: _phoneController,
                        label: 'Phone Number',
                        hintText: '0123456789',
                        icon: Icons.phone,
                        keyboardType: TextInputType.phone,
                        maxLength: 10,
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter phone number';
                          }
                          final trimmed = value.trim();
                          if (trimmed.length != 10) {
                            return 'Phone number must be 10 digits';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      _isLoadingHostels
                          ? const Center(
                              child: Padding(
                                padding: EdgeInsets.all(8.0),
                                child: CircularProgressIndicator(),
                              ),
                            )
                          : _buildDropdownField(
                              label: 'Hostel Name',
                              value: _selectedHostel,
                              items: _hostels,
                              icon: Icons.domain,
                              onChanged: (value) {
                                setState(() {
                                  _selectedHostel = value;
                                });
                              },
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please select a hostel';
                                }
                                return null;
                              },
                            ),
                      const SizedBox(height: 16),
                      _buildInputField(
                        controller: _roomNoController,
                        label: 'Room Number',
                        hintText: '101',
                        icon: Icons.meeting_room,
                      ),
                      const SizedBox(height: 16),
                      _buildDropdownField(
                        label: 'Semester',
                        value: _selectedSemester,
                        items: ['S1', 'S2', 'S3', 'S4', 'S5', 'S6', 'S7', 'S8'],
                        icon: Icons.school,
                        onChanged: (value) {
                          setState(() {
                            _selectedSemester = value;
                          });
                        },
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please select a semester';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      _buildDropdownField(
                        label: 'Section',
                        value: _selectedSection,
                        items: ['A', 'B', 'C'],
                        icon: Icons.groups,
                        onChanged: (value) {
                          setState(() {
                            _selectedSection = value;
                          });
                        },
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please select a section';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      _buildInputField(
                        controller: _homeAddressController,
                        label: 'Home Address',
                        hintText: '123 Main Street, City',
                        icon: Icons.location_on,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter home address';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      _buildInputField(
                        controller: _parentPhoneController,
                        label: 'Parent Phone Number',
                        hintText: '0123456789',
                        icon: Icons.phone_in_talk,
                        keyboardType: TextInputType.phone,
                        maxLength: 10,
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter parent phone number';
                          }
                          final trimmed = value.trim();
                          if (trimmed.length != 10) {
                            return 'Phone number must be 10 digits';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 28),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _isSubmitting ? null : _addStudent,
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: _isSubmitting
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.white),
                                  ),
                                )
                              : const Text(
                                  'Create Student',
                                  style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDropdownField({
    required String label,
    String? value,
    required List<String> items,
    required IconData icon,
    required Function(String?) onChanged,
    String? Function(String?)? validator,
  }) {
    return DropdownButtonFormField<String>(
      value: value,
      items: items
          .map((item) => DropdownMenuItem(value: item, child: Text(item)))
          .toList(),
      onChanged: onChanged,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: AppConstants.primaryColor),
        filled: true,
        fillColor: const Color(0xFFF8FAFF),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        enabledBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(14)),
          borderSide: BorderSide(color: Color(0x3394A3B8)),
        ),
        focusedBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(14)),
          borderSide: BorderSide(color: AppConstants.primaryColor),
        ),
      ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    String? hintText,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    bool obscureText = false,
    bool enabled = true,
    String? helperText,
    Widget? suffixIcon,
    int? maxLength,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscureText,
      enabled: enabled,
      validator: validator,
      maxLength: maxLength,
      inputFormatters: inputFormatters,
      decoration: InputDecoration(
        labelText: label,
        hintText: hintText,
        helperText: helperText,
        prefixIcon: Icon(icon, color: AppConstants.primaryColor),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: enabled ? const Color(0xFFF8FAFF) : Colors.grey[200],
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        enabledBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(14)),
          borderSide: BorderSide(color: Color(0x3394A3B8)),
        ),
        focusedBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(14)),
          borderSide: BorderSide(color: AppConstants.primaryColor),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
      ),
    );
  }

  Future<void> _addStudent() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final scaffoldMessenger = ScaffoldMessenger.of(context);
    setState(() {
      _isSubmitting = true;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final password = _passwordController.text.trim();

      await _service.addStudent(
        fullName: _nameController.text,
        email: _emailController.text,
        phone: _phoneController.text,
        password: password,
        departmentId: authProvider.userProfile!.departmentId!,
        classId: authProvider.userProfile!.classId!,
        hostelName: _selectedHostel,
        roomNo: _roomNoController.text.trim().isEmpty
            ? null
            : _roomNoController.text.trim(),
        semester: _selectedSemester,
        section: _selectedSection,
        homeAddress: _homeAddressController.text.trim().isEmpty
            ? null
            : _homeAddressController.text.trim(),
        parentPhone: _parentPhoneController.text.trim().isEmpty
            ? null
            : _parentPhoneController.text.trim(),
      );

      if (!mounted) return;
      scaffoldMessenger.showSnackBar(
        const SnackBar(content: Text('Student added successfully!')),
      );

      widget.onStudentCreated?.call();
    } catch (e) {
      if (!mounted) return;
      scaffoldMessenger.showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      setState(() {
        _isSubmitting = false;
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _roomNoController.dispose();
    _homeAddressController.dispose();
    _parentPhoneController.dispose();

    super.dispose();
  }
}
