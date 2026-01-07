import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/gate_pass_provider.dart';
import '../../utils/constants.dart';
import '../../widgets/request_card.dart';

class HodDashboard extends StatefulWidget {
  const HodDashboard({Key? key}) : super(key: key);

  @override
  State<HodDashboard> createState() => _HodDashboardState();
}

class _HodDashboardState extends State<HodDashboard>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  Future<void> _loadData() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final gatePassProvider =
        Provider.of<GatePassProvider>(context, listen: false);

    if (authProvider.userProfile?.departmentId != null) {
      await gatePassProvider
          .loadHodRequests(authProvider.userProfile!.departmentId!);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final gatePassProvider = Provider.of<GatePassProvider>(context);

    // Filter for requests waiting for HOD approval (show any request where HOD hasn't acted yet)
    final pendingHodRequests = gatePassProvider.requests
        .where((r) => r.hodStatus == 'pending')
        .toList();

    // All requests in the department
    final allRequests = gatePassProvider.requests;

    return Scaffold(
      appBar: AppBar(
        title: const Text('HOD Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await authProvider.signOut();
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: 'Pending Approval'),
            Tab(text: 'All Requests'),
          ],
        ),
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppConstants.primaryColor,
                  AppConstants.secondaryColor
                ],
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Welcome, ${authProvider.userProfile?.fullName ?? "HOD"}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Pending Approvals: ${pendingHodRequests.length}',
                  style: const TextStyle(color: Colors.white70, fontSize: 16),
                ),
              ],
            ),
          ),
          Expanded(
            child: gatePassProvider.isLoading
                ? const Center(child: CircularProgressIndicator())
                : TabBarView(
                    controller: _tabController,
                    children: [
                      _buildRequestList(pendingHodRequests, true),
                      _buildRequestList(allRequests, false),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildRequestList(List requests, bool isPending) {
    if (requests.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inbox, size: 80, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text(
              isPending ? 'No pending approvals' : 'No requests found',
              style: TextStyle(fontSize: 18, color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: requests.length,
        itemBuilder: (context, index) {
          final request = requests[index];
          return RequestCard(
            request: request,
            isHod: true,
            onActionComplete: _loadData,
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
}
