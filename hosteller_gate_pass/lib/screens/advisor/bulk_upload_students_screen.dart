import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:provider/provider.dart';
import 'package:csv/csv.dart';
import 'dart:convert';
import '../../providers/auth_provider.dart';
import '../../services/student_management_service.dart';
import '../../utils/constants.dart';

class BulkUploadStudentsScreen extends StatefulWidget {
  final VoidCallback? onBack;
  const BulkUploadStudentsScreen({Key? key, this.onBack}) : super(key: key);

  @override
  State<BulkUploadStudentsScreen> createState() =>
      _BulkUploadStudentsScreenState();
}

class _BulkUploadStudentsScreenState extends State<BulkUploadStudentsScreen> {
  final _service = StudentManagementService();
  List<List<dynamic>>? _csvData;
  bool _isUploading = false;
  String? _fileName;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Bulk Upload'),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: AppConstants.primaryColor,
        leading: widget.onBack != null
            ? IconButton(
                icon: const Icon(Icons.arrow_back_ios_new, size: 20),
                onPressed: widget.onBack,
              )
            : null,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.fromLTRB(0, 4, 0, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Student Bulk Upload',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1E3A8A),
                      ),
                    ),
                    Text(
                      'Upload multiple students from CSV file',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),

            // Instructions Card
            Card(
              color: Colors.blue.shade50,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.info, color: Colors.blue),
                        SizedBox(width: 8),
                        Text(
                          'CSV Format Instructions',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Text('Your CSV file should have these columns:'),
                    const SizedBox(height: 8),
                    const Text('1. Full Name (required)'),
                    const Text('2. Email (required)'),
                    const Text('3. Initial Password (optional)'),
                    const Text('4. Phone Number (required)'),
                    const Text('5. Hostel Name'),
                    const Text('6. Room Number'),
                    const Text('7. Semester (e.g. S1)'),
                    const Text('8. Section'),
                    const Text('9. Home Address'),
                    const Text('10. Parent Phone Number'),
                    const SizedBox(height: 12),
                    const Text(
                      'Example:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Container(
                      padding: const EdgeInsets.all(8),
                      margin: const EdgeInsets.only(top: 8),
                      color: Colors.white,
                      child: const Text(
                        'John Doe,john@student.edu,pass123,9876543210,St Thomas,101,S1,A,Address,9605...',
                        style: TextStyle(fontFamily: 'monospace', fontSize: 10),
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      '⚠️ Default password: "student123" if column 3 is empty',
                      style: TextStyle(color: Colors.orange, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Upload Button
            Center(
              child: ElevatedButton.icon(
                onPressed: _pickFile,
                icon: const Icon(Icons.upload_file),
                label: const Text('Select CSV File'),
                style: ElevatedButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  backgroundColor: AppConstants.primaryColor,
                ),
              ),
            ),

            if (_fileName != null) ...[
              const SizedBox(height: 16),
              Card(
                child: ListTile(
                  leading: const Icon(Icons.description, color: Colors.green),
                  title: Text(_fileName!),
                  subtitle: Text(_getRowCountMessage()),
                ),
              ),
            ],

            if (_csvData != null && _csvData!.isNotEmpty && _hasDataRows()) ...[
              const SizedBox(height: 24),
              const Text(
                'Preview (Data Rows):',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),

              // Preview Table
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  columns: const [
                    DataColumn(label: Text('Name')),
                    DataColumn(label: Text('Email')),
                    DataColumn(label: Text('Phone')),
                    DataColumn(label: Text('Hostel')),
                    DataColumn(label: Text('Room')),
                    DataColumn(label: Text('Sem')),
                    DataColumn(label: Text('Sec')),
                  ],
                  rows: _csvData!
                      .skip(_getHeaderRowsCount())
                      .take(5)
                      .map((row) {
                    return DataRow(
                      cells: [
                        DataCell(Text(_getCol(row, 0))),
                        DataCell(Text(_getCol(row, 1))),
                        DataCell(Text(_getCol(row, 3))),
                        DataCell(Text(_getCol(row, 4))),
                        DataCell(Text(_getCol(row, 5))),
                        DataCell(Text(_getCol(row, 6))),
                        DataCell(Text(_getCol(row, 7))),
                      ],
                    );
                  }).toList(),
                ),
              ),

              if (_getDataRowsCount() > 5)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    '...and ${_getDataRowsCount() - 5} more students',
                    style: const TextStyle(color: Colors.grey),
                  ),
                ),

              const SizedBox(height: 24),

              // Upload Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isUploading ? null : _uploadStudents,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: AppConstants.successColor,
                  ),
                  child: _isUploading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text(
                          'Upload ${_getDataRowsCount()} Students',
                          style: const TextStyle(fontSize: 16),
                        ),
                ),
              ),
            ] else if (_csvData != null && _csvData!.isNotEmpty && !_hasDataRows()) ...[
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Center(
                  child: Text(
                    'No students found in CSV (only header or empty)',
                    style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    ));
  }

  String _getCol(List<dynamic> row, int index) {
    if (index >= row.length) return '';
    return row[index]?.toString() ?? '';
  }

  int _getHeaderRowsCount() {
    if (_csvData == null || _csvData!.isEmpty) return 0;
    // Common header labels check
    final firstCol = _csvData!.first[0].toString().toLowerCase();
    final secondCol = _csvData![0].length > 1 ? _csvData![0][1].toString().toLowerCase() : '';
    if (firstCol.contains('name') || secondCol.contains('email')) {
      return 1;
    }
    return 0;
  }

  int _getDataRowsCount() {
    if (_csvData == null) return 0;
    int count = _csvData!.length - _getHeaderRowsCount();
    return count > 0 ? count : 0;
  }

  bool _hasDataRows() {
    return _getDataRowsCount() > 0;
  }

  String _getRowCountMessage() {
    final count = _getDataRowsCount();
    if (count == 0 && _csvData != null && _csvData!.isNotEmpty) {
      return 'No data rows found';
    }
    return '$count rows found';
  }

  Future<void> _pickFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv'],
        withData: true, // Crucial for mobile: loads file bytes into memory
      );

      if (result != null) {
        final bytes = result.files.first.bytes;
        if (bytes != null) {
          var csvString = utf8.decode(bytes);
          // Normalize line endings to avoid single-row parsing issues
          csvString = csvString.replaceAll('\r\n', '\n').replaceAll('\r', '\n');
          final List<List<dynamic>> csvData =
              const CsvToListConverter(eol: '\n').convert(csvString);

          if (csvData.isNotEmpty && csvData.first.length < 4) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Invalid CSV: Need at least Name, Email, Password, and Phone columns.'),
                backgroundColor: Colors.red,
              ),
            );
            return;
          }

          setState(() {
            _csvData = csvData;
            _fileName = result.files.first.name;
          });
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error reading file: $e')),
      );
    }
  }

  Future<void> _uploadStudents() async {
    if (_csvData == null || _csvData!.isEmpty) return;

    setState(() {
      _isUploading = true;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      int successCount = 0;
      int failCount = 0;

      // Skip header row if matches common header names
      int startIndex = 0;
      if (_csvData!.isNotEmpty && 
          (_csvData!.first[0].toString().toLowerCase().contains('name') ||
           _csvData!.first[1].toString().toLowerCase().contains('email'))) {
        startIndex = 1;
      }

      String firstError = '';
      for (int i = startIndex; i < _csvData!.length; i++) {
        final row = _csvData![i];
        try {
          if (row.length >= 4) {
            final fullName = row[0].toString().trim();
            final email = row[1].toString().trim();
            final password = row[2].toString().trim().isEmpty ? 'student123' : row[2].toString().trim();
            final phone = row[3].toString().trim();
            
            // Optional fields
            final hostelName = row.length > 4 ? row[4].toString().trim() : null;
            final roomNo = row.length > 5 ? row[5].toString().trim() : null;
            final semester = row.length > 6 ? row[6].toString().trim() : null;
            final section = row.length > 7 ? row[7].toString().trim() : null;
            final homeAddress = row.length > 8 ? row[8].toString().trim() : null;
            final parentPhone = row.length > 9 ? row[9].toString().trim() : null;

            if (fullName.isEmpty || email.isEmpty) continue;

            await _service.addStudent(
              fullName: fullName,
              email: email,
              phone: phone,
              password: password,
              departmentId: authProvider.userProfile!.departmentId!,
              classId: authProvider.userProfile!.classId!,
              hostelName: hostelName,
              roomNo: roomNo,
              semester: semester,
              section: section,
              homeAddress: homeAddress,
              parentPhone: parentPhone,
            );
            successCount++;
          }
        } catch (e) {
          failCount++;
          if (firstError.isEmpty) firstError = e.toString().replaceFirst('Exception: ', '');
          print('Row $i ERROR [${row.length > 0 ? row[0] : "Unknown"}]: $e');
        }
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Upload complete!\n✅ Success: $successCount\n❌ Failed: $failCount\n${failCount > 0 ? 'Error: $firstError' : ''}',
          ),
          duration: const Duration(seconds: 8),
          backgroundColor: failCount > 0 ? Colors.red : Colors.green,
        ),
      );

      if (successCount > 0) {
        setState(() {
          _csvData = null;
          _fileName = null;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      setState(() {
        _isUploading = false;
      });
    }
  }
}
