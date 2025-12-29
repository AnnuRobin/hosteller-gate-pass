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
        title: Text('${widget.isAdvisor ? "Review" : "Approve"} Request'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Request Details',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Divider(height: 24),
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
                    _buildDetailRow(
                      'Duration',
                      '${widget.request.toDate.difference(widget.request.fromDate).inDays} days',
                    ),
                    _buildDetailRow(
                      'Submitted',
                      DateFormat('MMM dd, yyyy - HH:mm')
                          .format(widget.request.createdAt),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Your Remarks (Optional)',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _remarksController,
                      decoration: InputDecoration(
                        hintText: 'Add remarks or comments...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      maxLines: 4,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isProcessing
                        ? null
                        : () => _handleAction(approved: false),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppConstants.rejectedColor,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: _isProcessing
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Text(
                            'Reject',
                            style: TextStyle(fontSize: 16),
                          ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isProcessing
                        ? null
                        : () => _handleAction(approved: true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppConstants.approvedColor,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: _isProcessing
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Text(
                            'Approve',
                            style: TextStyle(fontSize: 16),
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

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleAction({required bool approved}) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(approved ? 'Approve Request' : 'Reject Request'),
        content: Text(
          approved
              ? 'Are you sure you want to approve this request?'
              : 'Are you sure you want to reject this request?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              approved ? 'Approve' : 'Reject',
              style: TextStyle(
                color: approved
                    ? AppConstants.approvedColor
                    : AppConstants.rejectedColor,
              ),
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
      final gatePassProvider = Provider.of<GatePassProvider>(context, listen: false);

      if (widget.isAdvisor) {
        await gatePassProvider.advisorAction(
          requestId: widget.request.id,
          advisorId: authProvider.currentUser!.id,
          approved: approved,
          remarks: _remarksController.text.isEmpty
              ? null
              : _remarksController.text,
        );
      } else {
        await gatePassProvider.hodAction(
          requestId: widget.request.id,
          hodId: authProvider.currentUser!.id,
          approved: approved,
          remarks: _remarksController.text.isEmpty
              ? null
              : _remarksController.text,
        );
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            approved
                ? 'Request approved successfully!'
                : 'Request rejected successfully!',
          ),
        ),
      );

      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      setState(() {
        _isProcessing = false;
      });
    }
  }

  @override
  void dispose() {
    _remarksController.dispose();
    super.dispose();
  }
}