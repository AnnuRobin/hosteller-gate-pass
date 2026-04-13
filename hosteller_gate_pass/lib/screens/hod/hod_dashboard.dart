import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../models/gate_pass_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/gate_pass_provider.dart';
import '../../utils/constants.dart';
import '../../widgets/request_card.dart';
import '../shared/common_settings_screen.dart';
import '../shared/student_gate_pass_history_screen.dart';
import '../shared/dashboard_list_page.dart';
import 'hod_view_students_screen.dart';
import 'manage_faculty_screen.dart';

class HodDashboard extends StatefulWidget {
  const HodDashboard({Key? key}) : super(key: key);

  @override
  State<HodDashboard> createState() => _HodDashboardState();
}

class _HodDashboardState extends State<HodDashboard> {
  // 0=Home 1=Pending 2=Active 3=Rejected 4=Students(History) 5=Settings
  int _selectedIndex = 0;
  String _dashboardSearch = '';
  final TextEditingController _dashboardSearchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadData());
  }

  @override
  void dispose() {
    _dashboardSearchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final gp = Provider.of<GatePassProvider>(context, listen: false);
    if (auth.userProfile?.departmentId != null) {
      await gp.loadHodRequests(auth.userProfile!.departmentId!);
    }
  }

  String _getGreeting() {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good Morning';
    if (h < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  // ─────────────────── EXPIRED LOGIC ────────────────────────────────────────
  bool _isExpired(dynamic r) =>
      r.fromDate.isBefore(DateTime.now()) && r.hodStatus != 'rejected';

  // ─────────────────── STATUS HELPERS ───────────────────────────────────────
  Color _statusColor(dynamic r) {
    if (_isExpired(r)) return Colors.grey;
    switch (r.hodStatus as String) {
      case 'approved':
        return AppConstants.primaryColor;
      case 'rejected':
        return AppConstants.rejectedColor;
      default:
        return const Color(0xFF3B82F6); // blue-500
    }
  }

  String _statusLabel(dynamic r) {
    if (_isExpired(r)) return 'Expired';
    switch (r.hodStatus as String) {
      case 'approved':
        return 'Approved';
      case 'rejected':
        return 'Rejected';
      default:
        return 'Pending';
    }
  }

  Color _cardBg(dynamic r) {
    if (_isExpired(r)) return Colors.grey.withValues(alpha: 0.07);
    switch (r.hodStatus as String) {
      case 'rejected':
        return AppConstants.rejectedColor.withValues(alpha: 0.07);
      default:
        return AppConstants.primaryColor.withValues(alpha: 0.07);
    }
  }

  Color _cardBorder(dynamic r) {
    if (_isExpired(r)) return Colors.grey.withValues(alpha: 0.2);
    switch (r.hodStatus as String) {
      case 'rejected':
        return AppConstants.rejectedColor.withValues(alpha: 0.2);
      default:
        return AppConstants.primaryColor.withValues(alpha: 0.18);
    }
  }

  // ─────────────────── BUILD ─────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final gp = Provider.of<GatePassProvider>(context);

    final pendingRequests =
        gp.requests.where((r) => r.hodStatus == 'pending' && !_isExpired(r)).toList();
    final activeRequests =
        gp.requests.where((r) => r.isCurrentlyActive).toList();
    final approvedRequests =
        gp.requests.where((r) => r.hodStatus == 'approved').toList();
    final rejectedRequests =
        gp.requests.where((r) => r.hodStatus == 'rejected').toList();
    
    // Sort all for better UX
    approvedRequests.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    pendingRequests.sort((a, b) => b.createdAt.compareTo(a.createdAt));

    final fullName = auth.userProfile?.fullName ?? 'HOD';
    final initials = fullName.isNotEmpty ? fullName[0].toUpperCase() : 'H';
    
    final departmentId = auth.userProfile?.departmentId;
    final departmentName = gp.requests.isNotEmpty
        ? (gp.requests.first.departmentName ?? 'Department')
        : 'Department';

    Widget body;
    switch (_selectedIndex) {
      case 1:
        body = DashboardListPage(
          title: 'Pending Requests',
          requests: pendingRequests,
          icon: Icons.pending_actions,
          isLoading: gp.isLoading,
          onRefresh: _loadData,
          isExpiredFn: _isExpired,
          statusColorFn: _statusColor,
          statusLabelFn: _statusLabel,
          cardBgFn: _cardBg,
          cardBorderFn: _cardBorder,
          onCardTap: (ctx, r) => _showPassDetail(ctx, r),
          actionButtonsBuilder: (ctx, r, showDetail) {
            if (r.hodStatus == 'pending' && !_isExpired(r)) {
              return Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  _actionBtn(
                    label: 'Reject',
                    color: AppConstants.rejectedColor,
                    icon: Icons.close,
                    onPressed: showDetail,
                  ),
                  const SizedBox(width: 8),
                  _actionBtn(
                    label: 'Approve',
                    color: AppConstants.successColor,
                    icon: Icons.check,
                    onPressed: showDetail,
                  ),
                ],
              );
            }
            return null;
          },
        );
        break;
      case 2:
        body = DashboardListPage(
          title: 'Approved Requests',
          requests: approvedRequests,
          icon: Icons.verified_user_outlined,
          isLoading: gp.isLoading,
          onRefresh: _loadData,
          isExpiredFn: _isExpired,
          statusColorFn: _statusColor,
          statusLabelFn: _statusLabel,
          cardBgFn: _cardBg,
          cardBorderFn: _cardBorder,
          onCardTap: (ctx, r) => _showPassDetail(ctx, r),
        );
        break;
      case 3:
        body = DashboardListPage(
          title: 'Active Requests',
          requests: activeRequests,
          icon: Icons.verified_outlined,
          isLoading: gp.isLoading,
          onRefresh: _loadData,
          isExpiredFn: _isExpired,
          statusColorFn: _statusColor,
          statusLabelFn: _statusLabel,
          cardBgFn: _cardBg,
          cardBorderFn: _cardBorder,
          onCardTap: (ctx, r) => _showPassDetail(ctx, r),
        );
        break;
      case 4:
        body = DashboardListPage(
          title: 'Rejected Requests',
          requests: rejectedRequests,
          icon: Icons.cancel_outlined,
          isLoading: gp.isLoading,
          onRefresh: _loadData,
          isExpiredFn: _isExpired,
          statusColorFn: _statusColor,
          statusLabelFn: _statusLabel,
          cardBgFn: _cardBg,
          cardBorderFn: _cardBorder,
          onCardTap: (ctx, r) => _showPassDetail(ctx, r),
        );
        break;
      case 5:
        body = departmentId != null
            ? StudentGatePassHistoryScreen(
                scopeType: 'department',
                scopeId: departmentId,
                scopeName: departmentName,
              )
            : const Center(
                child: Text('Department not assigned', style: TextStyle(color: Colors.grey)),
              );
        break;
      case 6:
        body = HodViewStudentsScreen(
          departmentId: departmentId ?? '',
          departmentName: departmentName,
        );
        break;
      case 7:
        body = ManageFacultyScreen(
          departmentId: departmentId ?? '',
          departmentName: departmentName,
        );
        break;
      case 8:
        body = const CommonSettingsScreen();
        break;
      default:
        body = _buildHomePage(
          pendingCount: pendingRequests.length,
          activeCount: activeRequests.length,
          approvedCount: approvedRequests.length,
          rejectedCount: rejectedRequests.length,
          allRequests: gp.requests,
          isLoading: gp.isLoading,
        );
    }

    return PopScope(
      canPop: _selectedIndex == 0,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        setState(() => _selectedIndex = 0);
      },
      child: Scaffold(
        backgroundColor: Colors.grey[50],
        drawer: _buildDrawer(context, auth, fullName, initials),
        body: Column(
          children: [
            if (_selectedIndex == 0)
              _buildHeader(
                context,
                fullName,
                pendingCount: pendingRequests.length,
                approvedCount: approvedRequests.length,
                activeCount: activeRequests.length,
                rejectedCount: rejectedRequests.length,
              ),
            Expanded(child: body),
          ],
        ),
      ),
    );
  }

  // ─────────────────── HEADER ────────────────────────────────────────────────
  Widget _buildHeader(
    BuildContext context,
    String fullName, {
    int pendingCount = 0,
    int approvedCount = 0,
    int activeCount = 0,
    int rejectedCount = 0,
  }) {
    final hasPending = pendingCount > 0;
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppConstants.primaryColor,
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(30)),
      ),
      padding: EdgeInsets.fromLTRB(
          20, MediaQuery.of(context).padding.top + 20, 10, 32),
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
                      color: Colors.white.withValues(alpha: 0.8), fontSize: 14),
                ),
              ),
              Row(
                children: [
                  Stack(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.notifications_none,
                            color: Colors.white),
                        onPressed: () => setState(() => _selectedIndex = 1),
                      ),
                      if (hasPending)
                        Positioned(
                          right: 10,
                          top: 10,
                          child: Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                                color: Color(0xFFEF4444),
                                shape: BoxShape.circle),
                          ),
                        ),
                    ],
                  ),
                  Builder(
                    builder: (ctx) => IconButton(
                      icon: const Icon(Icons.menu, color: Colors.white),
                      onPressed: () => Scaffold.of(ctx).openDrawer(),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '${_getGreeting()},',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.9),
              fontSize: 36,
              fontWeight: FontWeight.w400,
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            fullName,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildStatItem('Pending\nRequests', pendingCount.toString(),
                  () => setState(() => _selectedIndex = 1)),
              Container(
                  height: 40,
                  width: 1,
                  color: Colors.white.withValues(alpha: 0.2)),
              _buildStatItem('Active\nRequests', activeCount.toString(),
                  () => setState(() => _selectedIndex = 3)),
              Container(
                  height: 40,
                  width: 1,
                  color: Colors.white.withValues(alpha: 0.2)),
              _buildStatItem('Rejected\nRequests', rejectedCount.toString(),
                  () => setState(() => _selectedIndex = 4)),
            ],
          ),
        ],
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
              value == '0' ? '0' : value.padLeft(2, '0'),
              style: const TextStyle(
                fontSize: 34,
                fontWeight: FontWeight.bold,
                color: Color(0xFF8DE8C4),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: Colors.white.withValues(alpha: 0.9),
                height: 1.2,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─────────────────── DRAWER ────────────────────────────────────────────────
  Widget _buildDrawer(BuildContext context, AuthProvider authProvider,
      String fullName, String initials) {
    return Drawer(
      child: Container(
        color: AppConstants.primaryColor,
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(20, 60, 20, 28),
              color: AppConstants.primaryColor,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: Colors.white.withValues(alpha: 0.25),
                    child: Text(
                      initials,
                      style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 24),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    fullName,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      'HOD',
                      style: TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            _drawerItem(
                icon: Icons.home_outlined,
                activeIcon: Icons.home,
                label: 'Home',
                index: 0),
            _drawerItem(
                icon: Icons.pending_actions_outlined,
                activeIcon: Icons.pending_actions,
                label: 'Pending Request',
                index: 1),
            _drawerItem(
                icon: Icons.verified_outlined,
                activeIcon: Icons.verified,
                label: 'Active Request',
                index: 3),
            _drawerItem(
                icon: Icons.cancel_outlined,
                activeIcon: Icons.cancel,
                label: 'Rejected Request',
                index: 4),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Divider(
                  height: 24, color: Colors.white.withValues(alpha: 0.15)),
            ),
            _drawerItem(
                icon: Icons.history_outlined,
                activeIcon: Icons.history,
                label: 'Student History',
                index: 5),
            _drawerItem(
                icon: Icons.people_outline_rounded,
                activeIcon: Icons.people_rounded,
                label: 'Students',
                index: 6),
            _drawerItem(
                icon: Icons.badge_outlined,
                activeIcon: Icons.badge_rounded,
                label: 'Faculty',
                index: 7),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Divider(
                  height: 24, color: Colors.white.withValues(alpha: 0.15)),
            ),
            _drawerItem(
                icon: Icons.settings_outlined,
                activeIcon: Icons.settings,
                label: 'Settings',
                index: 8),
            const Spacer(),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              child: ListTile(
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child:
                      const Icon(Icons.logout, color: Colors.white70, size: 20),
                ),
                title: const Text(
                  'Logout',
                  style: TextStyle(
                      color: Colors.white70, fontWeight: FontWeight.w600),
                ),
                onTap: () async {
                  Navigator.pop(context);
                  await authProvider.signOut();
                },
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _drawerItem({
    required IconData icon,
    required IconData activeIcon,
    required String label,
    required int index,
  }) {
    final isSelected = _selectedIndex == index;
    return Padding(
      padding: const EdgeInsets.only(right: 20, bottom: 4),
      child: ListTile(
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
            topRight: Radius.circular(30),
            bottomRight: Radius.circular(30),
          ),
        ),
        tileColor: isSelected
            ? Colors.white.withValues(alpha: 0.15)
            : Colors.transparent,
        leading: Icon(
          isSelected ? activeIcon : icon,
          color: isSelected ? const Color(0xFF8DE8C4) : Colors.white70,
          size: 22,
        ),
        title: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.white70,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w400,
            fontSize: 15,
            letterSpacing: 0.3,
          ),
        ),
        onTap: () {
          setState(() => _selectedIndex = index);
          Navigator.pop(context);
        },
      ),
    );
  }

  // ─────────────────── HOME PAGE ─────────────────────────────────────────────
  Widget _buildHomePage({
    required int pendingCount,
    required int activeCount,
    required int approvedCount,
    required int rejectedCount,
    required List<GatePassModel> allRequests,
    required bool isLoading,
  }) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final filtered = _dashboardSearch.isEmpty
        ? allRequests
        : allRequests.where((r) {
            final q = _dashboardSearch.toLowerCase();
            return (r.studentName ?? '').toLowerCase().contains(q) ||
                r.reason.toLowerCase().contains(q) ||
                r.destination.toLowerCase().contains(q) ||
                (r.className ?? '').toLowerCase().contains(q) ||
                (r.departmentName ?? '').toLowerCase().contains(q);
          }).toList();

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
        children: [
          // ── Search bar ──────────────────────────────────────────────────
          Container(
            height: 48,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                const SizedBox(width: 14),
                Icon(Icons.search, color: Colors.grey[400], size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: _dashboardSearchController,
                    onChanged: (v) => setState(() => _dashboardSearch = v),
                    decoration: InputDecoration(
                      hintText: 'Search students or pass history...',
                      hintStyle:
                          TextStyle(color: Colors.grey[400], fontSize: 14),
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding:
                          const EdgeInsets.symmetric(vertical: 14),
                    ),
                    style: const TextStyle(fontSize: 14),
                  ),
                ),
                if (_dashboardSearch.isNotEmpty)
                  IconButton(
                    icon: Icon(Icons.clear, color: Colors.grey[400], size: 18),
                    onPressed: () {
                      _dashboardSearchController.clear();
                      setState(() => _dashboardSearch = '');
                    },
                  ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // ── Tiles (only when not searching) ─────────────────────────────
          if (_dashboardSearch.isEmpty) ...[
            Row(
              children: [
                Expanded(
                  child: _buildSelectionCard(
                    title: 'Student History',
                    subtitle: 'View pass history',
                    icon: Icons.history_outlined,
                    iconBgColor:
                        AppConstants.primaryColor.withValues(alpha: 0.1),
                    iconColor: AppConstants.primaryColor,
                    onTap: () => setState(() => _selectedIndex = 5),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildSelectionCard(
                    title: 'Approved',
                    subtitle: 'Active + Expired',
                    icon: Icons.verified_user_outlined,
                    iconBgColor: Colors.green.withValues(alpha: 0.1),
                    iconColor: Colors.green,
                    onTap: () => setState(() => _selectedIndex = 2),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildSelectionCard(
                    title: 'Students',
                    subtitle: 'Semester-wise view',
                    icon: Icons.people_outline_rounded,
                    iconBgColor: const Color(0xFF10B981).withValues(alpha: 0.1),
                    iconColor: const Color(0xFF10B981),
                    onTap: () => setState(() => _selectedIndex = 6),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildSelectionCard(
                    title: 'Faculty',
                    subtitle: 'Manage advisors',
                    icon: Icons.badge_outlined,
                    iconBgColor: const Color(0xFF8B5CF6).withValues(alpha: 0.1),
                    iconColor: const Color(0xFF8B5CF6),
                    onTap: () => setState(() => _selectedIndex = 7),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Text(
              'Recent Requests',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),
            const SizedBox(height: 12),
          ] else ...[
            Text(
              'Results for "$_dashboardSearch"',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 12),
          ],

          // ── Cards ────────────────────────────────────────────────────────
          if (filtered.isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 32),
              child: Center(
                child: Column(
                  children: [
                    Icon(Icons.search_off, size: 56, color: Colors.grey[300]),
                    const SizedBox(height: 12),
                    Text(
                      _dashboardSearch.isEmpty
                          ? 'No requests yet'
                          : 'No results for "$_dashboardSearch"',
                      style:
                          TextStyle(color: Colors.grey[500], fontSize: 15),
                    ),
                  ],
                ),
              ),
            )
          else
            ...filtered.map((r) => _buildPassCard(r)),
        ],
      ),
    );
  }

  // ─────────────────── PASS CARD (home) ──────────────────────────────────────
  Widget _buildPassCard(dynamic r) {
    final Color sc = _statusColor(r);
    final Color bg = _cardBg(r);
    final Color border = _cardBorder(r);
    final bool expired = _isExpired(r);
    final String label = _statusLabel(r);

    return GestureDetector(
      onTap: () => _showPassDetail(context, r),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration:
                      BoxDecoration(color: sc, shape: BoxShape.circle),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    r.studentName ?? 'Student',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: expired ? Colors.grey[600] : Colors.grey[900],
                    ),
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: sc.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    label,
                    style: TextStyle(
                        fontSize: 11, fontWeight: FontWeight.bold, color: sc),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              r.reason,
              style: TextStyle(
                fontSize: 14,
                color: expired ? Colors.grey[500] : Colors.grey[700],
                fontWeight: FontWeight.w500,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.location_on_outlined,
                    size: 14, color: Colors.grey[500]),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    r.destination,
                    style: TextStyle(fontSize: 13, color: Colors.grey[500]),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                Icon(Icons.calendar_today_outlined,
                    size: 14, color: Colors.grey[500]),
                const SizedBox(width: 4),
                Text(
                  '${DateFormat('MMM dd').format(r.fromDate)} – ${DateFormat('MMM dd').format(r.toDate)}',
                  style: TextStyle(fontSize: 13, color: Colors.grey[500]),
                ),
              ],
            ),
            if (r.hodStatus == 'pending' && !expired) ...[
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  _actionBtn(
                    label: 'Reject',
                    color: AppConstants.rejectedColor,
                    icon: Icons.close,
                    onPressed: () => _showFullCard(context, r),
                  ),
                  const SizedBox(width: 8),
                  _actionBtn(
                    label: 'Approve',
                    color: AppConstants.successColor,
                    icon: Icons.check,
                    onPressed: () => _showFullCard(context, r),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _actionBtn({
    required String label,
    required Color color,
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 14, color: Colors.white),
      label: Text(label,
          style: const TextStyle(fontSize: 12, color: Colors.white)),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        elevation: 0,
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
    );
  }

  void _showPassDetail(BuildContext context, dynamic r) {
    RequestCard.showDetailSheet(
      context, 
      r, 
      isHod: true,
      onActionComplete: _loadData,
    );
  }

  void _showFullCard(BuildContext context, dynamic r) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(8),
        child: RequestCard(
          request: r,
          isHod: true,
          onActionComplete: () {
            Navigator.pop(context);
            _loadData();
          },
        ),
      ),
    );
  }

  // ─────────────────── SELECTION CARD ────────────────────────────────────────
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
              color: Colors.black.withValues(alpha: 0.04),
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
                  borderRadius: BorderRadius.circular(14)),
              child: Icon(icon, color: iconColor, size: 24),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: const TextStyle(
                  color: Colors.black87,
                  fontSize: 16,
                  fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              style: TextStyle(color: Colors.grey[600], fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}
