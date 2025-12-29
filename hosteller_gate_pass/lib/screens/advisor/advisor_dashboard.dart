import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/gate_pass_provider.dart';
import '../../utils/constants.dart';
import '../../widgets/request_card.dart';
import 'review_request_screen.dart';

class AdvisorDashboard extends StatefulWidget {
  const AdvisorDashboard({Key? key}) : super(key: key);

  @override
  State<AdvisorDashboard> createState() => _AdvisorDashboardState();
}

class _AdvisorDashboardState extends State<AdvisorDashboard> {
  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final gatePassProvider = Provider.of<GatePassProvider>(context, listen: false);
    
    if (authProvider.userProfile?.classId != null) {
      await gatePassProvider.loadAdvisorRequests(authProvider.userProfile!.classId!);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final gatePassProvider = Provider.of<GatePassProvider>(context);

    final pendingRequests = gatePassProvider.requests
        .where((r) => r.advisorStatus == 'pending')
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Advisor Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await authProvider.signOut();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppConstants.primaryColor, AppConstants.secondaryColor],
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Welcome, ${authProvider.userProfile?.fullName ?? "Advisor"}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Pending Requests: ${pendingRequests.length}',
                  style: const TextStyle(color: Colors.white70, fontSize: 16),
                ),
              ],
            ),
          ),
          Expanded(
            child: gatePassProvider.isLoading
                ? const Center(child: CircularProgressIndicator())
                : pendingRequests.isEmpty
                    ? const Center(child: Text('No pending requests'))
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: pendingRequests.length,
                        itemBuilder: (context, index) {
                          return GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => ReviewRequestScreen(
                                    request: pendingRequests[index],
                                    isAdvisor: true,
                                  ),
                                ),
                              );
                            },
                            child: RequestCard(request: pendingRequests[index]),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
