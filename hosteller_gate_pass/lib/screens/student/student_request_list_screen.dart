import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/gate_pass_provider.dart';
import '../../widgets/request_card.dart';
import '../../models/gate_pass_model.dart';
import '../../utils/constants.dart';

enum StudentRequestListType { approved, pending, rejected, history, active }

class StudentRequestListScreen extends StatelessWidget {
  final StudentRequestListType type;
  final String title;

  const StudentRequestListScreen({
    Key? key,
    required this.type,
    required this.title,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        backgroundColor: AppConstants.primaryColor,
      ),
      body: Consumer<GatePassProvider>(
        builder: (context, gatePassProvider, child) {
          List<GatePassModel> requests;
          switch (type) {
            case StudentRequestListType.approved:
              requests = gatePassProvider.approvedRequests;
              break;
            case StudentRequestListType.pending:
              requests = gatePassProvider.pendingRequests;
              break;
            case StudentRequestListType.rejected:
              requests = gatePassProvider.rejectedRequests;
              break;
            case StudentRequestListType.history:
              requests = gatePassProvider.requests;
              break;
            case StudentRequestListType.active:
              final now = DateTime.now();
              requests = gatePassProvider.requests
                  .where((r) => r.isFinallyApproved && !r.toDate.isBefore(now))
                  .toList();
              break;
          }

          if (requests.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.inbox, size: 80, color: Colors.grey[300]),
                  const SizedBox(height: 16),
                  Text(
                    'No passes found',
                    style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: requests.length,
            itemBuilder: (context, index) {
              return RequestCard(request: requests[index]);
            },
          );
        },
      ),
    );
  }
}
