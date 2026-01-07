import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/gate_pass_model.dart';
import '../utils/constants.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/gate_pass_provider.dart';
import '../screens/student/edit_request_screen.dart';

class RequestCard extends StatefulWidget {
  final GatePassModel request;
  final bool isAdvisor;
  final bool isHod;
  final VoidCallback? onActionComplete;

  const RequestCard({
    Key? key,
    required this.request,
    this.isAdvisor = false,
    this.isHod = false,
    this.onActionComplete,
  }) : super(key: key);

  @override
  State<RequestCard> createState() => _RequestCardState();
}

class _RequestCardState extends State<RequestCard> {
  bool _isProcessing = false;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _showRequestDetails(context),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.request.studentName ?? 'Student',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          widget.request.reason,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  _buildStatusBadge(widget.request.status),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: _buildInfoRow(Icons.class_, widget.request.className ?? widget.request.classId),
                  ),
                  Expanded(
                    child: _buildInfoRow(Icons.domain, widget.request.departmentName ?? widget.request.departmentId),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              _buildInfoRow(Icons.location_on, widget.request.destination),
              const SizedBox(height: 4),
              _buildInfoRow(
                Icons.calendar_today,
                '${DateFormat('MMM dd').format(widget.request.fromDate)} - ${DateFormat('MMM dd').format(widget.request.toDate)}',
              ),
              const SizedBox(height: 12),
              _buildApprovalProgress(widget.request),
              const SizedBox(height: 12),
              _buildActionButtons(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    // Show action buttons for advisors and HOD based on request status
    if (widget.isAdvisor && widget.request.advisorStatus == 'pending') {
      return Padding(
        padding: const EdgeInsets.only(top: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            ElevatedButton.icon(
              onPressed: _isProcessing ? null : _approveRequest,
              icon: const Icon(Icons.check, size: 18),
              label: const Text('Approve'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppConstants.successColor,
                disabledBackgroundColor: Colors.grey,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              ),
            ),
            const SizedBox(width: 8),
            ElevatedButton.icon(
              onPressed: _isProcessing ? null : _rejectRequest,
              icon: const Icon(Icons.close, size: 18),
              label: const Text('Reject'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppConstants.rejectedColor,
                disabledBackgroundColor: Colors.grey,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              ),
            ),
          ],
        ),
      );
    } else if (widget.isHod && widget.request.hodStatus == 'pending') {
      return Padding(
        padding: const EdgeInsets.only(top: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            ElevatedButton.icon(
              onPressed: _isProcessing ? null : _approveRequest,
              icon: const Icon(Icons.check, size: 18),
              label: const Text('Approve'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppConstants.successColor,
                disabledBackgroundColor: Colors.grey,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              ),
            ),
            const SizedBox(width: 8),
            ElevatedButton.icon(
              onPressed: _isProcessing ? null : _rejectRequest,
              icon: const Icon(Icons.close, size: 18),
              label: const Text('Reject'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppConstants.rejectedColor,
                disabledBackgroundColor: Colors.grey,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              ),
            ),
          ],
        ),
      );
    } else if (widget.request.status == 'pending' &&
        !widget.isAdvisor &&
        !widget.isHod) {
      // Show edit and delete for student
      return Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          TextButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => EditRequestScreen(request: widget.request),
                ),
              );
            },
            icon: const Icon(Icons.edit, size: 18),
            label: const Text('Edit'),
          ),
          TextButton.icon(
            onPressed: () => _confirmDelete(context),
            icon: const Icon(Icons.delete, size: 18, color: Colors.red),
            label: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      );
    }
    return const SizedBox.shrink();
  }

  Future<void> _approveRequest() async {
    setState(() => _isProcessing = true);

    try {
      final gatePassProvider =
          Provider.of<GatePassProvider>(context, listen: false);
      final authProvider = Provider.of<AuthProvider>(context, listen: false);

      if (widget.isAdvisor) {
        await gatePassProvider.advisorAction(
          requestId: widget.request.id,
          advisorId: authProvider.userProfile!.id,
          approved: true,
        );
      } else if (widget.isHod) {
        await gatePassProvider.hodAction(
          requestId: widget.request.id,
          hodId: authProvider.userProfile!.id,
          approved: true,
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Request approved successfully')),
        );
        widget.onActionComplete?.call();
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

  Future<void> _rejectRequest() async {
    final remarksController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reject Request'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Are you sure you want to reject this request?'),
            const SizedBox(height: 16),
            TextField(
              controller: remarksController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'Enter remarks (optional)',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await _performRejectAction(remarksController.text);
            },
            child: const Text('Reject', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Future<void> _performRejectAction(String remarks) async {
    setState(() => _isProcessing = true);

    try {
      final gatePassProvider =
          Provider.of<GatePassProvider>(context, listen: false);
      final authProvider = Provider.of<AuthProvider>(context, listen: false);

      if (widget.isAdvisor) {
        await gatePassProvider.advisorAction(
          requestId: widget.request.id,
          advisorId: authProvider.userProfile!.id,
          approved: false,
          remarks: remarks.isNotEmpty ? remarks : null,
        );
      } else if (widget.isHod) {
        await gatePassProvider.hodAction(
          requestId: widget.request.id,
          hodId: authProvider.userProfile!.id,
          approved: false,
          remarks: remarks.isNotEmpty ? remarks : null,
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Request rejected')),
        );
        widget.onActionComplete?.call();
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

  Widget _buildStatusBadge(String status) {
    Color color;
    String text;

    switch (status) {
      case 'pending':
        color = AppConstants.pendingColor;
        text = 'Pending';
        break;
      case 'advisor_approved':
        color = Colors.blue;
        text = 'Advisor Approved';
        break;
      case 'approved':
        color = AppConstants.approvedColor;
        text = 'Approved';
        break;
      case 'rejected':
        color = AppConstants.rejectedColor;
        text = 'Rejected';
        break;
      default:
        color = Colors.grey;
        text = 'Unknown';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
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

  Widget _buildInfoRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(color: Colors.grey, fontSize: 14),
          ),
        ),
      ],
    );
  }

  Widget _buildApprovalProgress(GatePassModel request) {
    return Row(
      children: [
        _buildProgressStep('Advisor', request.advisorStatus),
        Expanded(
          child: Container(
            height: 2,
            color: request.advisorStatus == 'approved'
                ? AppConstants.approvedColor
                : Colors.grey[300],
          ),
        ),
        _buildProgressStep('HOD', request.hodStatus),
      ],
    );
  }

  Widget _buildProgressStep(String label, String status) {
    Color color;
    IconData icon;

    if (status == 'approved') {
      color = AppConstants.approvedColor;
      icon = Icons.check_circle;
    } else if (status == 'rejected') {
      color = AppConstants.rejectedColor;
      icon = Icons.cancel;
    } else {
      color = Colors.grey[300]!;
      icon = Icons.radio_button_unchecked;
    }

    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(fontSize: 12, color: color),
        ),
      ],
    );
  }

  void _showRequestDetails(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) => SingleChildScrollView(
          controller: scrollController,
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Request Details',
                style:
                    const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 24),
              _buildDetailRow('Student Name', widget.request.studentName ?? 'N/A'),
              _buildDetailRow('Class', widget.request.className ?? widget.request.classId),
              _buildDetailRow('Department', widget.request.departmentName ?? widget.request.departmentId),
              const SizedBox(height: 12),
              _buildDetailRow('Reason', widget.request.reason),
              _buildDetailRow('Destination', widget.request.destination),
              _buildDetailRow(
                'From',
                DateFormat('MMM dd, yyyy - HH:mm')
                    .format(widget.request.fromDate),
              ),
              _buildDetailRow(
                'To',
                DateFormat('MMM dd, yyyy - HH:mm')
                    .format(widget.request.toDate),
              ),
              _buildDetailRow('Status', widget.request.getStatusText()),
              if (widget.request.advisorRemarks != null)
                _buildDetailRow(
                    'Advisor Remarks', widget.request.advisorRemarks!),
              if (widget.request.hodRemarks != null)
                _buildDetailRow('HOD Remarks', widget.request.hodRemarks!),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.grey,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(fontSize: 16),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Request'),
        content: const Text('Are you sure you want to delete this request?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await Provider.of<GatePassProvider>(context, listen: false)
                  .deleteRequest(widget.request.id);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Request deleted')),
              );
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
