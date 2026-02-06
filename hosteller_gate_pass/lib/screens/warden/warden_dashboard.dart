import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/warden_provider.dart';
import '../../utils/constants.dart';
import '../../widgets/request_card.dart';
import 'warden_request_detail_screen.dart';

class WardenDashboard extends StatefulWidget {
  const WardenDashboard({Key? key}) : super(key: key);

  @override
  State<WardenDashboard> createState() => _WardenDashboardState();
}

class _WardenDashboardState extends State<WardenDashboard>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadData();
  }

  Future<void> _loadData() async {
    final wardenProvider = Provider.of<WardenProvider>(context, listen: false);
    await wardenProvider.loadWardenRequests();
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final wardenProvider = Provider.of<WardenProvider>(context);

    final pendingRequests = wardenProvider.pendingWardenRequests;
    final activePassess = wardenProvider.activePassess;
    final completedRequests = wardenProvider.completedRequests;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Warden Dashboard'),
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
          tabs: const [
            Tab(text: 'Pending Approval'),
            Tab(text: 'Active Passes'),
            Tab(text: 'Completed'),
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
                  'Welcome, ${authProvider.userProfile?.fullName ?? "Warden"}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Pending Approvals: ${pendingRequests.length}',
                  style: const TextStyle(color: Colors.white70, fontSize: 16),
                ),
              ],
            ),
          ),
          Expanded(
            child: wardenProvider.isLoading
                ? const Center(child: CircularProgressIndicator())
                : TabBarView(
                    controller: _tabController,
                    children: [
                      _buildRequestList(pendingRequests, 'pending'),
                      _buildRequestList(activePassess, 'active'),
                      _buildRequestList(completedRequests, 'completed'),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildRequestList(List requests, String type) {
    if (requests.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inbox, size: 80, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text(
              _getEmptyMessage(type),
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
          return GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => WardenRequestDetailScreen(
                    request: request,
                    requestType: type,
                  ),
                ),
              );
            },
            child: RequestCard(
              request: request,
              isWarden: true,
              onActionComplete: _loadData,
            ),
          );
        },
      ),
    );
  }

  String _getEmptyMessage(String type) {
    switch (type) {
      case 'pending':
        return 'No pending approvals';
      case 'active':
        return 'No active passes';
      case 'completed':
        return 'No completed requests';
      default:
        return 'No requests found';
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
}
