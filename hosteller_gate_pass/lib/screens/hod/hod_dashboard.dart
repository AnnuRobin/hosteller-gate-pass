import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/gate_pass_provider.dart';
import '../../utils/constants.dart';
import '../../widgets/request_card.dart';
import '../shared/student_gate_pass_history_screen.dart';

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
    _tabController = TabController(length: 3, vsync: this);
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

    // Filter for requests waiting for HOD approval
    final pendingHodRequests = gatePassProvider.requests
        .where((r) => r.hodStatus == 'pending')
        .toList();

    // All requests in the department
    final allRequests = gatePassProvider.requests;

    final departmentId = authProvider.userProfile?.departmentId;
    // Derive the human-readable department name from any loaded request
    final departmentName = allRequests.isNotEmpty
        ? (allRequests.first.departmentName ?? 'Department')
        : 'Department';

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E293B),
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'HOD Dashboard',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: () async {
              await authProvider.signOut();
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: const Color(0xFF059669),
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          tabs: const [
            Tab(text: 'Pending'),
            Tab(text: 'All Requests'),
            Tab(text: 'Students'),
          ],
        ),
      ),
      body: Column(
        children: [
          // Stats header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF064E3B), Color(0xFF059669)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Welcome, ${authProvider.userProfile?.fullName ?? "HOD"}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Pending Approvals: ${pendingHodRequests.length}',
                        style: const TextStyle(
                            color: Colors.white70, fontSize: 14),
                      ),
                    ],
                  ),
                ),
                // Stat chips
                _headerStatChip(
                  '${allRequests.length}',
                  'Total',
                  Colors.white.withOpacity(0.25),
                ),
                const SizedBox(width: 8),
                _headerStatChip(
                  '${allRequests.where((r) => r.isFinallyApproved).length}',
                  'Granted',
                  const Color(0xFF10B981).withOpacity(0.4),
                ),
              ],
            ),
          ),

          Expanded(
            child: gatePassProvider.isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                        color: Color(0xFF059669)))
                : TabBarView(
                    controller: _tabController,
                    children: [
                      _buildRequestList(pendingHodRequests, true),
                      _buildRequestList(allRequests, false),
                      // Student history tab
                      departmentId != null
                          ? StudentGatePassHistoryScreen(
                              scopeType: 'department',
                              scopeId: departmentId,
                              scopeName: departmentName,
                            )
                          : const Center(
                              child: Text(
                                'Department not assigned',
                                style: TextStyle(color: Colors.white70),
                              ),
                            ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _headerStatChip(String value, String label, Color bg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          Text(
            label,
            style: const TextStyle(color: Colors.white70, fontSize: 11),
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
            Icon(Icons.inbox, size: 80, color: Colors.grey[700]),
            const SizedBox(height: 16),
            Text(
              isPending ? 'No pending approvals' : 'No requests found',
              style: TextStyle(fontSize: 18, color: Colors.grey[500]),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      color: const Color(0xFF059669),
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
