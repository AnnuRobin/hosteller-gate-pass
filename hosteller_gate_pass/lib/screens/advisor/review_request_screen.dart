import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../models/gate_pass_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/gate_pass_provider.dart';
import '../../utils/constants.dart';

class ReviewRequestScreen extends StatefulWidget {
  final GatePassModel request;
  final bool isAdvisor;

  const ReviewRequestScreen({
    Key? key,
    required this.request,
    required this.isAdvisor,
  }) : super(key: key);

  @override
  State<ReviewRequestScreen> createState() => _ReviewRequestScreenState();
}

class _ReviewRequestScreenState extends State<ReviewRequestScreen> {
  final _remarksController = TextEditingController();
  bool _isProcessing = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title:
            Text('${widget.isAdvisor ? "Review" : "Final Approval"} Request'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Request Details Card
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.description,
                          color: AppConstants.primaryColor,
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'Request Details',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 24),
                    _buildDetailRow('Reason', widget.request.reason),
                    _buildDetailRow('Destination', widget.request.destination),
                    _buildDetailRow(
                      'From Date',
                      DateFormat('MMM dd, yyyy - HH:mm')
                          .format(widget.request.fromDate),
                    ),
                    _buildDetailRow(
                      'To Date',
                      DateFormat('MMM dd, yyyy - HH:mm')
                          .format(widget.request.toDate),
                    ),
                    _buildDetailRow(
                      'Duration',
                      '${widget.request.toDate.difference(widget.request.fromDate).inDays} days',
                    ),
                    _buildDetailRow(
                      'Submitted On',
                      DateFormat('MMM dd, yyyy - HH:mm')
                          .format(widget.request.createdAt),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Remarks Card
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.comment,
                          color: AppConstants.secondaryColor,
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'Comments (Optional)',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Add comments when approving or rejecting this request',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _remarksController,
                      decoration: InputDecoration(
                        hintText:
                            'Enter your approval/rejection comments here...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        filled: true,
                        fillColor: Colors.grey[50],
                      ),
                      maxLines: 4,
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isProcessing
                        ? null
                        : () => _handleAction(approved: false),
                    icon: const Icon(Icons.close, size: 20),
                    label: const Text(
                      'Reject',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppConstants.rejectedColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isProcessing
                        ? null
                        : () => _handleAction(approved: true),
                    icon: const Icon(Icons.check, size: 20),
                    label: const Text(
                      'Approve',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppConstants.approvedColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
              ],
            ),

            if (_isProcessing)
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: Center(
                  child: Column(
                    children: [
                      CircularProgressIndicator(
                        color: AppConstants.primaryColor,
                      ),
                      const SizedBox(height: 8),
                      const Text('Processing...'),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey[700],
                fontSize: 14,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleAction({required bool approved}) async {
    // Show confirmation dialog
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(approved ? 'Approve Request' : 'Reject Request'),
        content: Text(
          approved
              ? 'Are you sure you want to approve this gate pass request?'
              : 'Are you sure you want to reject this gate pass request?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(
              foregroundColor: approved
                  ? AppConstants.approvedColor
                  : AppConstants.rejectedColor,
            ),
            child: Text(
              approved ? 'Approve' : 'Reject',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() {
      _isProcessing = true;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final gatePassProvider =
          Provider.of<GatePassProvider>(context, listen: false);

      if (widget.isAdvisor) {
        // Advisor approval/rejection
        await gatePassProvider.advisorAction(
          requestId: widget.request.id,
          advisorId: authProvider.currentUser!.id,
          approved: approved,
          remarks:
              _remarksController.text.isEmpty ? null : _remarksController.text,
        );
      } else {
        // HOD approval/rejection
        await gatePassProvider.hodAction(
          requestId: widget.request.id,
          hodId: authProvider.currentUser!.id,
          approved: approved,
          remarks:
              _remarksController.text.isEmpty ? null : _remarksController.text,
        );
      }

      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(
                  approved ? Icons.check_circle : Icons.cancel,
                  color: Colors.white,
                ),
                const SizedBox(width: 8),
                Text(
                  approved
                      ? 'Request approved successfully!'
                      : 'Request rejected successfully!',
                ),
              ],
            ),
            backgroundColor: approved
                ? AppConstants.approvedColor
                : AppConstants.rejectedColor,
          ),
        );

        // Go back to dashboard
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _remarksController.dispose();
    super.dispose();
  }
}
