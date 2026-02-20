import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/admin_service.dart';
import '../../utils/constants.dart';
import 'dart:convert';

class AuditLogsScreen extends StatefulWidget {
  const AuditLogsScreen({Key? key}) : super(key: key);

  @override
  State<AuditLogsScreen> createState() => _AuditLogsScreenState();
}

class _AuditLogsScreenState extends State<AuditLogsScreen> {
  final AdminService _adminService = AdminService();
  List<Map<String, dynamic>> _auditLogs = [];
  bool _isLoading = false;
  String? _filterAction;

  final List<String> _actionTypes = [
    'All Actions',
    'create_user',
    'update_user',
    'delete_user',
    'reset_password',
  ];

  @override
  void initState() {
    super.initState();
    _loadAuditLogs();
  }

  Future<void> _loadAuditLogs() async {
    setState(() => _isLoading = true);
    try {
      final logs = await _adminService.getAuditLogs(limit: 100);
      setState(() {
        _auditLogs = logs;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading audit logs: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  List<Map<String, dynamic>> get _filteredLogs {
    if (_filterAction == null || _filterAction == 'All Actions') {
      return _auditLogs;
    }
    return _auditLogs.where((log) => log['action'] == _filterAction).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Audit Logs'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadAuditLogs,
          ),
        ],
      ),
      body: Column(
        children: [
          // Header with stats
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppConstants.primaryColor,
                  AppConstants.secondaryColor,
                ],
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Admin Activity Log',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '${_filteredLogs.length} ${_filteredLogs.length == 1 ? 'entry' : 'entries'}',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),

          // Filter
          Container(
            padding: const EdgeInsets.all(16),
            child: DropdownButtonFormField<String>(
              value: _filterAction ?? 'All Actions',
              decoration: const InputDecoration(
                labelText: 'Filter by Action',
                prefixIcon: Icon(Icons.filter_list),
                border: OutlineInputBorder(),
              ),
              items: _actionTypes
                  .map((action) => DropdownMenuItem(
                        value: action,
                        child: Text(_formatActionName(action)),
                      ))
                  .toList(),
              onChanged: (value) {
                setState(() {
                  _filterAction = value == 'All Actions' ? null : value;
                });
              },
            ),
          ),

          // Logs list
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredLogs.isEmpty
                    ? _buildEmptyState()
                    : RefreshIndicator(
                        onRefresh: _loadAuditLogs,
                        child: ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _filteredLogs.length,
                          itemBuilder: (context, index) {
                            final log = _filteredLogs[index];
                            return _buildAuditLogCard(log);
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.history,
            size: 80,
            color: Colors.grey[300],
          ),
          const SizedBox(height: 16),
          Text(
            'No audit logs found',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAuditLogCard(Map<String, dynamic> log) {
    final adminName = log['admin']?['full_name'] ?? 'Unknown Admin';
    final adminEmail = log['admin']?['email'] ?? '';
    final targetName = log['target']?['full_name'] ?? 'N/A';
    final action = log['action'] as String;
    final createdAt = DateTime.parse(log['created_at'] as String);
    final details = log['details'] as Map<String, dynamic>?;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: _getActionColor(action),
          child: Icon(
            _getActionIcon(action),
            color: Colors.white,
            size: 20,
          ),
        ),
        title: Text(
          _formatActionName(action),
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text('By: $adminName'),
            if (targetName != 'N/A') Text('Target: $targetName'),
            const SizedBox(height: 4),
            Text(
              _formatDateTime(createdAt),
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
        children: [
          if (details != null && details.isNotEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(12),
                  bottomRight: Radius.circular(12),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Details:',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...details.entries.map((entry) => Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(
                              width: 100,
                              child: Text(
                                '${entry.key}:',
                                style: TextStyle(
                                  fontWeight: FontWeight.w500,
                                  color: Colors.grey[700],
                                ),
                              ),
                            ),
                            Expanded(
                              child: Text(
                                entry.value?.toString() ?? 'null',
                                style: const TextStyle(fontSize: 14),
                              ),
                            ),
                          ],
                        ),
                      )),
                ],
              ),
            ),
        ],
      ),
    );
  }

  String _formatActionName(String action) {
    switch (action) {
      case 'create_user':
        return 'User Created';
      case 'update_user':
        return 'User Updated';
      case 'delete_user':
        return 'User Deleted';
      case 'reset_password':
        return 'Password Reset';
      case 'All Actions':
        return 'All Actions';
      default:
        return action.replaceAll('_', ' ').toUpperCase();
    }
  }

  IconData _getActionIcon(String action) {
    switch (action) {
      case 'create_user':
        return Icons.person_add;
      case 'update_user':
        return Icons.edit;
      case 'delete_user':
        return Icons.delete;
      case 'reset_password':
        return Icons.lock_reset;
      default:
        return Icons.info;
    }
  }

  Color _getActionColor(String action) {
    switch (action) {
      case 'create_user':
        return AppConstants.successColor;
      case 'update_user':
        return AppConstants.primaryColor;
      case 'delete_user':
        return AppConstants.errorColor;
      case 'reset_password':
        return AppConstants.warningColor;
      default:
        return Colors.grey;
    }
  }

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes} minutes ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours} hours ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return DateFormat('MMM dd, yyyy HH:mm').format(dateTime);
    }
  }
}
