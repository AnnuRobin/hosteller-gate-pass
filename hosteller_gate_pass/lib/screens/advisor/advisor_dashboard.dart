import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/gate_pass_provider.dart';
import '../../utils/constants.dart';
import '../../widgets/request_card.dart';
import 'manage_students_screen.dart';
import 'add_student_screen.dart';
import 'bulk_upload_students_screen.dart';
import '../shared/student_gate_pass_history_screen.dart';

class AdvisorDashboard extends StatefulWidget {
  const AdvisorDashboard({Key? key}) : super(key: key);

  @override
  State<AdvisorDashboard> createState() => _AdvisorDashboardState();
}

class _AdvisorDashboardState extends State<AdvisorDashboard>
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

    if (authProvider.userProfile?.classId != null) {
      await gatePassProvider.loadAdvisorRequests(
        classId: authProvider.userProfile!.classId!,
        departmentId: authProvider.userProfile!.departmentId!,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final gatePassProvider = Provider.of<GatePassProvider>(context);

    final pendingRequests = gatePassProvider.requests
        .where((r) => r.advisorStatus == 'pending')
        .toList();

    final allRequests = gatePassProvider.requests;

    final classId = authProvider.userProfile?.classId;
    // Derive the human-readable class name from any loaded request
    final className = allRequests.isNotEmpty
        ? (allRequests.first.className ?? 'Class')
        : 'Class';

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E293B),
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Advisor Dashboard',
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
                colors: [Color(0xFF1E3A5F), Color(0xFF2563EB)],
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
                        'Welcome, ${authProvider.userProfile?.fullName ?? "Advisor"}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Pending Requests: ${pendingRequests.length}',
                        style: const TextStyle(
                            color: Colors.white70, fontSize: 14),
                      ),
                    ],
                  ),
                ),
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

          // Quick Actions
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Row(
              children: [
                Expanded(
                  child: _actionButton(
                    icon: Icons.people,
                    label: 'Manage Students',
                    color: AppConstants.primaryColor,
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const ManageStudentsScreen()),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _actionButton(
                    icon: Icons.person_add,
                    label: 'Add Student',
                    color: AppConstants.secondaryColor,
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const AddStudentScreen()),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),

          Expanded(
            child: gatePassProvider.isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: Color(0xFF2563EB)))
                : TabBarView(
                    controller: _tabController,
                    children: [
                      _buildRequestList(pendingRequests, true),
                      _buildRequestList(allRequests, false),
                      // Student history tab
                      classId != null
                          ? StudentGatePassHistoryScreen(
                              scopeType: 'class',
                              scopeId: classId,
                              scopeName: className,
                            )
                          : const Center(
                              child: Text(
                                'Class not assigned',
                                style: TextStyle(color: Colors.white70),
                              ),
                            ),
                    ],
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const BulkUploadStudentsScreen()),
          );
        },
        icon: const Icon(Icons.upload_file),
        label: const Text('Bulk Upload'),
        backgroundColor: AppConstants.successColor,
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

  Widget _actionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 18),
      label: Text(label, style: const TextStyle(fontSize: 13)),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 12),
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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
              isPending ? 'No pending requests' : 'No requests found',
              style: TextStyle(fontSize: 18, color: Colors.grey[500]),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      color: const Color(0xFF2563EB),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: requests.length,
        itemBuilder: (context, index) {
          final request = requests[index];
          return RequestCard(
            request: request,
            isAdvisor: true,
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
