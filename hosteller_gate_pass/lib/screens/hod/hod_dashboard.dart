import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
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

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning';
    if (hour < 17) return 'Good Afternoon';
    return 'Good Evening';
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

    final fullName = authProvider.userProfile?.fullName ?? 'HOD';

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: AppConstants.primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              DateFormat('EEEE, dd MMM yyyy').format(DateTime.now()),
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.75),
                fontSize: 11,
              ),
            ),
            const Text(
              'HOD Dashboard',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ],
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
          indicatorColor: const Color(0xFF8DE8C4),
          indicatorWeight: 3,
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
          // Stats header â€” styled to match Student Dashboard theme
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
            decoration: BoxDecoration(
              color: AppConstants.primaryColor,
              borderRadius: const BorderRadius.vertical(
                bottom: Radius.circular(30),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${_getGreeting()},',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.8),
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        fullName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Pending Approvals: ${pendingHodRequests.length}',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.7),
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                // Stat chips â€” content unchanged
                _headerStatChip(
                  '${allRequests.length}',
                  'Total',
                  Colors.white.withValues(alpha: 0.15),
                ),
                const SizedBox(width: 8),
                _headerStatChip(
                  '${allRequests.where((r) => r.isFinallyApproved).length}',
                  'Granted',
                  const Color(0xFF8DE8C4).withValues(alpha: 0.3),
                ),
              ],
            ),
          ),

          Expanded(
            child: gatePassProvider.isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                        color: AppConstants.primaryColor))
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
                                style: TextStyle(color: Colors.grey),
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
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 20,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.8),
              fontSize: 11,
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
              style: TextStyle(fontSize: 18, color: Colors.grey[500]),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      color: AppConstants.primaryColor,
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

