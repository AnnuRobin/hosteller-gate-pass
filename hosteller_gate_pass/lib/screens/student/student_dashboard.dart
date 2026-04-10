// TODO Implement this library.
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/auth_provider.dart';
import '../../providers/gate_pass_provider.dart';
import '../../providers/notification_provider.dart';
import '../../utils/constants.dart';
import '../../widgets/request_card.dart';
import '../../models/gate_pass_model.dart';
import 'create_request_screen.dart';
import 'gate_pass_token_screen.dart';
import 'student_request_list_screen.dart';

class StudentDashboard extends StatefulWidget {
  const StudentDashboard({Key? key}) : super(key: key);

  @override
  State<StudentDashboard> createState() => _StudentDashboardState();
}

class _StudentDashboardState extends State<StudentDashboard> {
  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final gatePassProvider =
        Provider.of<GatePassProvider>(context, listen: false);
    final notificationProvider =
        Provider.of<NotificationProvider>(context, listen: false);

    if (authProvider.currentUser != null) {
      await gatePassProvider.loadStudentRequests(authProvider.currentUser!.id);
      await notificationProvider
          .loadNotifications(authProvider.currentUser!.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final gatePassProvider = Provider.of<GatePassProvider>(context);
    final notificationProvider = Provider.of<NotificationProvider>(context);

    final activeRequests =
        gatePassProvider.requests.where((r) => r.isFinallyApproved).toList();

    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: Column(
        children: [
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: AppConstants.primaryColor,
                borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(30),
                ),
              ),
              padding: EdgeInsets.fromLTRB(20, MediaQuery.of(context).padding.top + 20, 10, 40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(top: 12.0),
                        child: Text(
                          DateFormat('EEEE, dd MMM yyyy').format(DateTime.now()),
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.8),
                            fontSize: 14,
                          ),
                        ),
                      ),
                      Row(
                        children: [
                          Stack(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.notifications_none, color: Colors.white),
                                onPressed: () => _showNotifications(context, notificationProvider),
                              ),
                              if (notificationProvider.unreadCount > 0)
                                Positioned(
                                  right: 10,
                                  top: 10,
                                  child: Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: const BoxDecoration(
                                      color: Color(0xFF8DE8C4),
                                      shape: BoxShape.circle,
                                    ),
                                    constraints: const BoxConstraints(minWidth: 12, minHeight: 12),
                                  ),
                                ),
                            ],
                          ),
                          IconButton(
                            icon: const Icon(Icons.logout, color: Colors.white),
                            onPressed: () async {
                              await authProvider.signOut();
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                  const Spacer(),
                  Text(
                    '${_getGreeting()},',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 36,
                      fontWeight: FontWeight.w400,
                      letterSpacing: 1.0,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    authProvider.userProfile?.fullName ?? 'Student',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const Spacer(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildStatItem(
                        'Pending\nPasses',
                        gatePassProvider.pendingRequests.length.toString(),
                        () => _navigateToList(context, StudentRequestListType.pending, 'Pending Passes'),
                      ),
                      Container(height: 40, width: 1, color: Colors.white.withOpacity(0.2)),
                      _buildStatItem(
                        'Approved\nPasses',
                        gatePassProvider.approvedRequests.length.toString(),
                        () => _navigateToList(context, StudentRequestListType.approved, 'Approved Passes'),
                      ),
                      Container(height: 40, width: 1, color: Colors.white.withOpacity(0.2)),
                      _buildStatItem(
                        'Rejected\nPasses',
                        gatePassProvider.rejectedRequests.length.toString(),
                        () => _navigateToList(context, StudentRequestListType.rejected, 'Rejected Passes'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          Container(
            color: Colors.transparent,
            padding: const EdgeInsets.fromLTRB(20, 30, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _buildSelectionCard(
                        title: 'Passes History',
                        subtitle: 'View all requests',
                        icon: Icons.history,
                        iconBgColor: Colors.purple.withOpacity(0.1),
                        iconColor: Colors.purple,
                        onTap: () => _navigateToList(context, StudentRequestListType.history, 'Passes History'),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildSelectionCard(
                        title: 'Active Passes',
                        subtitle: 'Currently active',
                        icon: Icons.lock_open,
                        iconBgColor: Colors.teal.withOpacity(0.1),
                        iconColor: Colors.teal,
                        onTap: () => _navigateToList(context, StudentRequestListType.active, 'Active Passes'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const CreateRequestScreen(),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF8DE8C4),
                      foregroundColor: Colors.black87,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 0,
                    ),
                    child: const Text(
                      'NEW REQUEST',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning';
    if (hour < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  void _navigateToList(BuildContext context, StudentRequestListType type, String title) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => StudentRequestListScreen(type: type, title: title),
      ),
    );
  }

  Widget _buildSelectionCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color iconBgColor,
    required Color iconColor,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: iconBgColor,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: iconColor, size: 24),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: const TextStyle(
                color: Colors.black87,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Column(
          children: [
            Text(
              value.padLeft(2, '0'),
              style: const TextStyle(
                fontSize: 34,
                fontWeight: FontWeight.bold,
                color: Color(0xFF8DE8C4), // Match reference's minty green numbers
              ),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: Colors.white.withOpacity(0.9),
                height: 1.2,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showNotifications(BuildContext context, NotificationProvider provider) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) {
          return Column(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Notifications',
                      style:
                          TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    if (provider.unreadCount > 0)
                      TextButton(
                        onPressed: () {
                          provider.markAllAsRead(
                            Provider.of<AuthProvider>(context, listen: false)
                                .currentUser!
                                .id,
                          );
                        },
                        child: const Text('Mark all as read'),
                      ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: provider.notifications.isEmpty
                    ? const Center(child: Text('No notifications'))
                    : ListView.builder(
                        controller: scrollController,
                        itemCount: provider.notifications.length,
                        itemBuilder: (context, index) {
                          final notification = provider.notifications[index];
                          return ListTile(
                            leading: Icon(
                              notification.read
                                  ? Icons.mail_outline
                                  : Icons.mail,
                              color: notification.read
                                  ? Colors.grey
                                  : AppConstants.primaryColor,
                            ),
                            title: Text(
                              notification.title,
                              style: TextStyle(
                                fontWeight: notification.read
                                    ? FontWeight.normal
                                    : FontWeight.bold,
                              ),
                            ),
                            subtitle: Text(notification.message),
                            trailing: Text(
                              DateFormat('MMM dd, HH:mm')
                                  .format(notification.createdAt),
                              style: const TextStyle(fontSize: 12),
                            ),
                            onTap: () {
                              if (!notification.read) {
                                provider.markAsRead(notification.id);
                              }
                            },
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    super.dispose();
  }
}
