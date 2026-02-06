import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../models/gate_pass_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/warden_provider.dart';
import '../../utils/constants.dart';

class WardenRequestDetailScreen extends StatefulWidget {
  final GatePassModel request;
  final String requestType; // 'pending', 'active', 'completed'

  const WardenRequestDetailScreen({
    Key? key,
    required this.request,
    required this.requestType,
  }) : super(key: key);

  @override
  State<WardenRequestDetailScreen> createState() =>
      _WardenRequestDetailScreenState();
}

class _WardenRequestDetailScreenState extends State<WardenRequestDetailScreen> {
  late DateTime _selectedExitTime;
  final _remarksController = TextEditingController();
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _selectedExitTime = DateTime.now();
  }

  @override
  void dispose() {
    _remarksController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gate Pass Details'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildHeader(),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildStudentInfo(),
                  const SizedBox(height: 24),
                  _buildRequestDetails(),
                  const SizedBox(height: 24),
                  _buildApprovalTrail(),
                  const SizedBox(height: 24),
                  _buildActionSection(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
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
          Text(
            widget.request.reason,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          _buildStatusChip(widget.request.status),
        ],
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    Color color;
    String text;

    if (status == 'pending') {
      color = AppConstants.pendingColor;
      text = 'Pending Approval';
    } else if (status == 'warden_approved') {
      color = AppConstants.approvedColor;
      text = 'Approved';
    } else if (status == 'rejected') {
      color = AppConstants.rejectedColor;
      text = 'Rejected';
    } else {
      color = Colors.grey;
      text = 'Unknown';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildStudentInfo() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Student Information',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            _buildInfoRow('Name', widget.request.studentName ?? 'N/A'),
            _buildInfoRow(
                'Class', widget.request.className ?? widget.request.classId),
            _buildInfoRow('Department',
                widget.request.departmentName ?? widget.request.departmentId),
          ],
        ),
      ),
    );
  }

  Widget _buildRequestDetails() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Request Details',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            _buildInfoRow('Destination', widget.request.destination),
            _buildInfoRow('Reason', widget.request.reason),
            _buildInfoRow(
              'From',
              DateFormat('MMM dd, yyyy HH:mm').format(widget.request.fromDate),
            ),
            _buildInfoRow(
              'To',
              DateFormat('MMM dd, yyyy HH:mm').format(widget.request.toDate),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildApprovalTrail() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Approval Trail',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildApprovalStep(
              'Advisor',
              widget.request.advisorStatus,
              widget.request.advisorApprovedAt,
              widget.request.advisorRemarks,
            ),
            const SizedBox(height: 12),
            _buildApprovalStep(
              'HOD',
              widget.request.hodStatus,
              widget.request.hodApprovedAt,
              widget.request.hodRemarks,
            ),
            const SizedBox(height: 12),
            _buildApprovalStep(
              'Warden',
              widget.request.wardenStatus,
              widget.request.wardenApprovedAt,
              widget.request.wardenRemarks,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildApprovalStep(
    String title,
    String status,
    DateTime? approvedAt,
    String? remarks,
  ) {
    Color color;
    IconData icon;
    String statusText;

    if (status == 'approved') {
      color = AppConstants.approvedColor;
      icon = Icons.check_circle;
      statusText = 'Approved';
    } else if (status == 'rejected') {
      color = AppConstants.rejectedColor;
      icon = Icons.cancel;
      statusText = 'Rejected';
    } else {
      color = Colors.grey[300]!;
      icon = Icons.radio_button_unchecked;
      statusText = 'Pending';
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(width: 12),
            Expanded(
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
                  Text(
                    statusText,
                    style: TextStyle(color: color, fontWeight: FontWeight.w500),
                  ),
                  if (approvedAt != null)
                    Text(
                      DateFormat('MMM dd, yyyy HH:mm').format(approvedAt),
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                ],
              ),
            ),
          ],
        ),
        if (remarks != null) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              'Remarks: $remarks',
              style: const TextStyle(fontSize: 12),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildActionSection() {
    // Only show action buttons for pending approvals
    if (widget.requestType != 'pending') {
      if (widget.requestType == 'active') {
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Record Entry Time',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                if (widget.request.exitTime != null)
                  Text(
                    'Exit Time: ${DateFormat('MMM dd, yyyy HH:mm').format(widget.request.exitTime!)}',
                    style: const TextStyle(fontSize: 14),
                  ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _isProcessing ? null : _recordEntryTime,
                        icon: const Icon(Icons.login),
                        label: const Text('Record Entry'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppConstants.successColor,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      }
      return const SizedBox.shrink();
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Warden Action',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ListTile(
              title: const Text('Select Exit Time'),
              subtitle: Text(
                DateFormat('MMM dd, yyyy HH:mm').format(_selectedExitTime),
              ),
              onTap: _selectExitTime,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _remarksController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'Enter remarks (optional)',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isProcessing ? null : _approvePass,
                    icon: const Icon(Icons.check),
                    label: const Text('Approve'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppConstants.successColor,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isProcessing ? null : _rejectPass,
                    icon: const Icon(Icons.close),
                    label: const Text('Reject'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppConstants.rejectedColor,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _selectExitTime() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedExitTime,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (date != null) {
      final time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(_selectedExitTime),
      );

      if (time != null) {
        setState(() {
          _selectedExitTime =
              DateTime(date.year, date.month, date.day, time.hour, time.minute);
        });
      }
    }
  }

  Future<void> _approvePass() async {
    setState(() => _isProcessing = true);

    try {
      final wardenProvider =
          Provider.of<WardenProvider>(context, listen: false);
      final authProvider = Provider.of<AuthProvider>(context, listen: false);

      await wardenProvider.wardenApprove(
        requestId: widget.request.id,
        wardenId: authProvider.userProfile!.id,
        exitTime: _selectedExitTime,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Gate pass approved successfully')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  Future<void> _rejectPass() async {
    setState(() => _isProcessing = true);

    try {
      final wardenProvider =
          Provider.of<WardenProvider>(context, listen: false);
      final authProvider = Provider.of<AuthProvider>(context, listen: false);

      await wardenProvider.wardenReject(
        requestId: widget.request.id,
        wardenId: authProvider.userProfile!.id,
        remarks:
            _remarksController.text.isNotEmpty ? _remarksController.text : null,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Gate pass rejected')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  Future<void> _recordEntryTime() async {
    setState(() => _isProcessing = true);

    try {
      final wardenProvider =
          Provider.of<WardenProvider>(context, listen: false);

      await wardenProvider.recordEntryTime(
        requestId: widget.request.id,
        entryTime: DateTime.now(),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Entry time recorded successfully')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
