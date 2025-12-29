import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/gate_pass_model.dart';
import '../utils/constants.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/gate_pass_provider.dart';
import '../screens/student/edit_request_screen.dart';

class RequestCard extends StatelessWidget {
  final GatePassModel request;

  const RequestCard({Key? key, required this.request}) : super(key: key);

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
                    child: Text(
                      request.reason,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  _buildStatusBadge(request.status),
                ],
              ),
              const SizedBox(height: 8),
              _buildInfoRow(Icons.location_on, request.destination),
              const SizedBox(height: 4),
              _buildInfoRow(
                Icons.calendar_today,
                '${DateFormat('MMM dd').format(request.fromDate)} - ${DateFormat('MMM dd').format(request.toDate)}',
              ),
              const SizedBox(height: 12),
              _buildApprovalProgress(request),
              if (request.status == 'pending')
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => EditRequestScreen(request: request),
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
                ),
            ],
          ),
        ),
      ),
    );
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
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 24),
              _buildDetailRow('Reason', request.reason),
              _buildDetailRow('Destination', request.destination),
              _buildDetailRow(
                'From',
                DateFormat('MMM dd, yyyy - HH:mm').format(request.fromDate),
              ),
              _buildDetailRow(
                'To',
                DateFormat('MMM dd, yyyy - HH:mm').format(request.toDate),
              ),
              _buildDetailRow('Status', request.getStatusText()),
              if (request.advisorRemarks != null)
                _buildDetailRow('Advisor Remarks', request.advisorRemarks!),
              if (request.hodRemarks != null)
                _buildDetailRow('HOD Remarks', request.hodRemarks!),
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
                  .deleteRequest(request.id);
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