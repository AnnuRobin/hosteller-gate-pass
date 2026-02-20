import 'package:csv/csv.dart';

class CsvHelper {
  /// Parse CSV string and return list of student maps
  static List<Map<String, dynamic>> parseStudentsCsv(String csvString) {
    try {
      // Parse CSV
      final List<List<dynamic>> rows = const CsvToListConverter().convert(
        csvString,
        eol: '\n',
        fieldDelimiter: ',',
      );

      if (rows.isEmpty) {
        throw Exception('CSV file is empty');
      }

      // Get headers (first row)
      final headers = rows[0].map((h) => h.toString().trim().toLowerCase()).toList();

      // Validate required headers
      final requiredHeaders = ['email', 'full_name'];
      for (final required in requiredHeaders) {
        if (!headers.contains(required)) {
          throw Exception('Missing required column: $required');
        }
      }

      // Parse data rows
      final List<Map<String, dynamic>> students = [];
      for (int i = 1; i < rows.length; i++) {
        final row = rows[i];
        if (row.isEmpty || row.every((cell) => cell.toString().trim().isEmpty)) {
          continue; // Skip empty rows
        }

        final student = <String, dynamic>{};
        for (int j = 0; j < headers.length && j < row.length; j++) {
          final header = headers[j];
          final value = row[j]?.toString().trim();
          
          if (value != null && value.isNotEmpty) {
            student[header] = value;
          }
        }

        // Validate student has required fields
        if (student['email'] == null || student['full_name'] == null) {
          throw Exception('Row ${i + 1}: Missing email or full_name');
        }

        students.add(student);
      }

      if (students.isEmpty) {
        throw Exception('No valid student data found in CSV');
      }

      return students;
    } catch (e) {
      throw Exception('CSV parsing error: $e');
    }
  }

  /// Generate CSV template string
  static String generateTemplate() {
    return 'email,full_name,phone,home_address\n'
        'student1@college.edu,John Doe,+91-9876543210,123 Main St\n'
        'student2@college.edu,Jane Smith,+91-9876543211,456 Oak Ave\n';
  }

  /// Validate email format
  static bool isValidEmail(String email) {
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );
    return emailRegex.hasMatch(email);
  }

  /// Validate student data
  static List<String> validateStudent(Map<String, dynamic> student, int index) {
    final errors = <String>[];

    // Validate email
    if (student['email'] == null || student['email'].toString().isEmpty) {
      errors.add('Row ${index + 1}: Email is required');
    } else if (!isValidEmail(student['email'])) {
      errors.add('Row ${index + 1}: Invalid email format');
    }

    // Validate full name
    if (student['full_name'] == null || student['full_name'].toString().isEmpty) {
      errors.add('Row ${index + 1}: Full name is required');
    }

    // Validate phone (optional but if present, should be valid)
    if (student['phone'] != null && student['phone'].toString().isNotEmpty) {
      final phone = student['phone'].toString();
      if (phone.length < 10) {
        errors.add('Row ${index + 1}: Phone number too short');
      }
    }

    return errors;
  }

  /// Validate all students and return list of errors
  static List<String> validateAllStudents(List<Map<String, dynamic>> students) {
    final allErrors = <String>[];
    final emails = <String>{};

    for (int i = 0; i < students.length; i++) {
      final student = students[i];
      
      // Validate individual student
      allErrors.addAll(validateStudent(student, i));

      // Check for duplicate emails
      final email = student['email']?.toString().toLowerCase();
      if (email != null) {
        if (emails.contains(email)) {
          allErrors.add('Row ${i + 1}: Duplicate email: $email');
        } else {
          emails.add(email);
        }
      }
    }

    return allErrors;
  }
}
