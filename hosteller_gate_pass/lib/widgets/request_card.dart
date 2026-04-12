import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/gate_pass_model.dart';
import '../utils/constants.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/gate_pass_provider.dart';
import '../providers/warden_provider.dart';
import '../screens/student/edit_request_screen.dart';
import '../screens/student/gate_pass_token_screen.dart';

class RequestCard extends StatefulWidget {
  final GatePassModel request;
  final bool isAdvisor;
  final bool isHod;
  final bool isWarden;
  final VoidCallback? onActionComplete;

  const RequestCard({
    Key? key,
    required this.request,
    this.isAdvisor = false,
    this.isHod = false,
    this.isWarden = false,
    this.onActionComplete,
  }) : super(key: key);

  @override
  State<RequestCard> createState() => _RequestCardState();
}

class _RequestCardState extends State<RequestCard> {
  bool _isProcessing = false;

  @override
  Widget build(BuildContext context) {
    final req = widget.request;
    final bool isExpired = req.fromDate.isBefore(DateTime.now()) && req.status != 'rejected';
    
    Color sc;
    String label;
    Color bg;
    Color border;

    if (isExpired) {
      sc = Colors.grey;
      label = 'Expired';
      bg = Colors.grey.withOpacity(0.07);
      border = Colors.grey.withOpacity(0.2);
    } else if (req.isFinallyApproved) {
      sc = AppConstants.successColor;
      label = 'Gate Pass Granted';
      bg = AppConstants.successColor.withOpacity(0.07);
      border = AppConstants.successColor.withOpacity(0.18);
    } else if (req.status == 'rejected') {
      sc = AppConstants.rejectedColor;
      label = 'Rejected';
      bg = AppConstants.rejectedColor.withOpacity(0.07);
      border = AppConstants.rejectedColor.withOpacity(0.2);
    } else {
      sc = const Color(0xFF3B82F6);
      label = 'Pending';
      bg = const Color(0xFF3B82F6).withOpacity(0.07);
      border = const Color(0xFF3B82F6).withOpacity(0.18);
    }

    return GestureDetector(
      onTap: () => _showRequestDetails(context),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(color: sc, shape: BoxShape.circle),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    req.studentName ?? 'Student',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: isExpired ? Colors.grey[600] : Colors.grey[900],
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: sc.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    label,
                    style: TextStyle(
                        fontSize: 11, fontWeight: FontWeight.bold, color: sc),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              req.reason,
              style: TextStyle(
                fontSize: 14,
                color: isExpired ? Colors.grey[500] : Colors.grey[700],
                fontWeight: FontWeight.w500,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.location_on_outlined,
                    size: 14, color: Colors.grey[500]),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    req.destination,
                    style: TextStyle(fontSize: 13, color: Colors.grey[500]),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildApprovalProgress(req),
            const SizedBox(height: 12),
            _buildActionButtons(),
          ],
        ),
      ),
    );
  }



  Widget _buildActionButtons() {
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
    } else if (widget.isWarden && widget.request.wardenStatus == 'pending') {
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
        !widget.isHod &&
        !widget.isWarden) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          TextButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      EditRequestScreen(request: widget.request),
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
    final remarksController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Approve Request'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Add approval comments (optional)'),
            const SizedBox(height: 16),
            TextField(
              controller: remarksController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'Enter approval comments...',
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
              await _performApproveAction(remarksController.text);
            },
            child: const Text('Approve',
                style: TextStyle(color: AppConstants.successColor)),
          ),
        ],
      ),
    );
  }

  Future<void> _performApproveAction(String remarks) async {
    setState(() => _isProcessing = true);

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);

      if (widget.isAdvisor) {
        final gatePassProvider =
            Provider.of<GatePassProvider>(context, listen: false);
        await gatePassProvider.advisorAction(
          requestId: widget.request.id,
          advisorId: authProvider.userProfile!.id,
          approved: true,
          remarks: remarks.isNotEmpty ? remarks : null,
        );
      } else if (widget.isHod) {
        final gatePassProvider =
            Provider.of<GatePassProvider>(context, listen: false);
        await gatePassProvider.hodAction(
          requestId: widget.request.id,
          hodId: authProvider.userProfile!.id,
          approved: true,
          remarks: remarks.isNotEmpty ? remarks : null,
        );
      } else if (widget.isWarden) {
        final wardenProvider =
            Provider.of<WardenProvider>(context, listen: false);
        await wardenProvider.wardenApprove(
          requestId: widget.request.id,
          wardenId: authProvider.userProfile!.id,
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
      final authProvider = Provider.of<AuthProvider>(context, listen: false);

      if (widget.isAdvisor) {
        final gatePassProvider =
            Provider.of<GatePassProvider>(context, listen: false);
        await gatePassProvider.advisorAction(
          requestId: widget.request.id,
          advisorId: authProvider.userProfile!.id,
          approved: false,
          remarks: remarks.isNotEmpty ? remarks : null,
        );
      } else if (widget.isHod) {
        final gatePassProvider =
            Provider.of<GatePassProvider>(context, listen: false);
        await gatePassProvider.hodAction(
          requestId: widget.request.id,
          hodId: authProvider.userProfile!.id,
          approved: false,
          remarks: remarks.isNotEmpty ? remarks : null,
        );
      } else if (widget.isWarden) {
        final wardenProvider =
            Provider.of<WardenProvider>(context, listen: false);
        await wardenProvider.wardenReject(
          requestId: widget.request.id,
          wardenId: authProvider.userProfile!.id,
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
        Expanded(
          child: Container(
            height: 2,
            color: request.hodStatus == 'approved'
                ? AppConstants.approvedColor
                : Colors.grey[300],
          ),
        ),
        _buildProgressStep('Warden', request.wardenStatus),
      ],
    );
  }

  Widget _buildProgressStep(String label, String status) {
    Color color;
    IconData icon;
    Color textColor;

    if (status == 'approved') {
      color = AppConstants.approvedColor;
      icon = Icons.check_circle;
      textColor = color;
    } else if (status == 'rejected') {
      color = AppConstants.rejectedColor;
      icon = Icons.cancel;
      textColor = color;
    } else {
      color = Colors.grey[400]!;
      icon = Icons.radio_button_unchecked;
      textColor = Colors.black;
    }

    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(fontSize: 12, color: textColor),
        ),
      ],
    );
  }

  void _showRequestDetails(BuildContext context) {
    final req = widget.request;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: req.isFinallyApproved ? 0.75 : 0.65,
        minChildSize: 0.4,
        maxChildSize: 0.95,
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
              // Token CTA inside detail sheet
              if (req.isFinallyApproved &&
                  !widget.isAdvisor &&
                  !widget.isHod &&
                  !widget.isWarden) ...[
                GestureDetector(
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => GatePassTokenScreen(request: req),
                      ),
                    );
                  },
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981).withOpacity(0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.verified_rounded,
                            color: Color(0xFF059669), size: 22),
                        SizedBox(width: 10),
                        Text(
                          'View Full Gate Pass Token',
                          style: TextStyle(
                            color: Color(0xFF059669),
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(width: 6),
                        Icon(Icons.arrow_forward_ios,
                            color: Color(0xFF059669), size: 14),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
              ],
              const Text(
                'Request Details',
                style:
                    TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 24),
              _buildDetailRow(
                  'Student Name', req.studentName ?? 'N/A'),
              _buildDetailRow(
                  'Class', req.className ?? req.classId),
              _buildDetailRow('Department',
                  req.departmentName ?? req.departmentId),
              const SizedBox(height: 12),
              _buildDetailRow('Reason', req.reason),
              _buildDetailRow('Destination', req.destination),
              _buildDetailRow(
                'From',
                DateFormat('MMM dd, yyyy - HH:mm')
                    .format(req.fromDate),
              ),
              _buildDetailRow(
                'To',
                DateFormat('MMM dd, yyyy - HH:mm')
                    .format(req.toDate),
              ),
              _buildDetailRow('Status', req.getStatusText()),
              const SizedBox(height: 8),
              // Approval timeline in detail sheet
              const Divider(),
              const SizedBox(height: 8),
              const Text(
                'Approval Timeline',
                style:
                    TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              _buildApprovalTimeline('Advisor',
                  req.advisorStatus, req.advisorApprovedAt,
                  remarks: req.advisorRemarks),
              _buildApprovalTimeline('HOD',
                  req.hodStatus, req.hodApprovedAt,
                  remarks: req.hodRemarks),
              _buildApprovalTimeline('Warden',
                  req.wardenStatus, req.wardenApprovedAt,
                  remarks: req.wardenRemarks),
              if (req.exitTime != null) ...[
                const SizedBox(height: 8),
                _buildDetailRow(
                  'Scheduled Exit Time',
                  DateFormat('MMM dd, yyyy - HH:mm')
                      .format(req.exitTime!),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildApprovalTimeline(
      String role, String status, DateTime? at,
      {String? remarks}) {
    final isApproved = status == 'approved';
    final isRejected = status == 'rejected';
    final color = isApproved
        ? AppConstants.approvedColor
        : isRejected
            ? AppConstants.rejectedColor
            : Colors.grey;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            isApproved
                ? Icons.check_circle
                : isRejected
                    ? Icons.cancel
                    : Icons.radio_button_unchecked,
            color: color,
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(role,
                        style: const TextStyle(fontWeight: FontWeight.w600)),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        isApproved
                            ? 'Approved'
                            : isRejected
                                ? 'Rejected'
                                : 'Pending',
                        style: TextStyle(
                          color: color,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    if (at != null) ...[
                      const SizedBox(width: 8),
                      Text(
                        DateFormat('MMM dd, HH:mm').format(at),
                        style: const TextStyle(
                            color: Colors.grey, fontSize: 11),
                      ),
                    ],
                  ],
                ),
                if (remarks != null && remarks.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    remarks,
                    style: const TextStyle(
                        color: Colors.grey, fontSize: 12),
                  ),
                ],
              ],
            ),
          ),
        ],
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
        content:
            const Text('Are you sure you want to delete this request?'),
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
            child:
                const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
