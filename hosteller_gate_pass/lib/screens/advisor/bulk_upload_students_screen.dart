import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:provider/provider.dart';
import 'package:csv/csv.dart';
import 'dart:convert';
import '../../providers/auth_provider.dart';
import '../../services/student_management_service.dart';
import '../../utils/constants.dart';

class BulkUploadStudentsScreen extends StatefulWidget {
  const BulkUploadStudentsScreen({Key? key}) : super(key: key);

  @override
  State<BulkUploadStudentsScreen> createState() => _BulkUploadStudentsScreenState();
}

class _BulkUploadStudentsScreenState extends State<BulkUploadStudentsScreen> {
  final _service = StudentManagementService();
  List<List<dynamic>>? _csvData;
  bool _isUploading = false;
  String? _fileName;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bulk Upload Students'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
                    const Text('3. Phone Number (required)'),
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
                        'John Doe,john@student.edu,9876543210\n'
                        'Jane Smith,jane@student.edu,9876543211',
                        style: TextStyle(fontFamily: 'monospace', fontSize: 12),
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      '⚠️ Default password will be "student123" for all students',
                      style: TextStyle(color: Colors.orange),
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
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
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
                  subtitle: Text('${_csvData?.length ?? 0} students found'),
                ),
              ),
            ],

            if (_csvData != null && _csvData!.isNotEmpty) ...[
              const SizedBox(height: 24),
              const Text(
                'Preview:',
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
                  ],
                  rows: _csvData!.take(5).map((row) {
                    return DataRow(
                      cells: [
                        DataCell(Text(row[0].toString())),
                        DataCell(Text(row[1].toString())),
                        DataCell(Text(row[2].toString())),
                      ],
                    );
                  }).toList(),
                ),
              ),

              if (_csvData!.length > 5)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    '...and ${_csvData!.length - 5} more students',
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
                          'Upload ${_csvData!.length} Students',
                          style: const TextStyle(fontSize: 16),
                        ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _pickFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv'],
      );

      if (result != null) {
        final bytes = result.files.first.bytes;
        if (bytes != null) {
          final csvString = utf8.decode(bytes);
          final List<List<dynamic>> csvData = const CsvToListConverter().convert(csvString);
          
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

      for (var row in _csvData!) {
        try {
          if (row.length >= 3) {
            await _service.addStudent(
              fullName: row[0].toString(),
              email: row[1].toString(),
              phone: row[2].toString(),
              password: 'student123',
              departmentId: authProvider.userProfile!.departmentId!,
              classId: authProvider.userProfile!.classId!,
            );
            successCount++;
          }
        } catch (e) {
          failCount++;
          print('Failed to add student: ${row[0]} - $e');
        }
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Upload complete!\n✅ Success: $successCount\n❌ Failed: $failCount',
          ),
          duration: const Duration(seconds: 5),
        ),
      );

      if (successCount > 0) {
        Navigator.pop(context);
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

