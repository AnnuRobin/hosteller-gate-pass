import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/auth_provider.dart';
import '../../providers/warden_provider.dart';
import '../../utils/constants.dart';

import '../shared/common_settings_screen.dart';
import 'warden_request_detail_screen.dart';

class WardenDashboard extends StatefulWidget {
  const WardenDashboard({Key? key}) : super(key: key);

  @override
  State<WardenDashboard> createState() => _WardenDashboardState();
}

class _WardenDashboardState extends State<WardenDashboard> {
  // 0 = Home, 1 = Pending, 2 = Active, 3 = Completed, 4 = Settings
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    // Defer data load until after the first frame to avoid
    // setState() called during build errors.
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadData());
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final wardenProvider = Provider.of<WardenProvider>(context, listen: false);
    final wardenId = authProvider.userProfile?.id ?? '';
    await wardenProvider.loadWardenRequests(wardenId);
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning';
    if (hour < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  // ─────────────────── EXPIRED LOGIC ────────────────────────────────────────
  bool _isExpired(dynamic r) {
    if (r.wardenStatus == 'rejected') return false;
    final now = DateTime.now();
    final currentDateOnly = DateTime(now.year, now.month, now.day);
    final fromDateOnly = DateTime(r.fromDate.year, r.fromDate.month, r.fromDate.day);
    return fromDateOnly.isBefore(currentDateOnly);
  }

  // ─────────────────── STATUS HELPERS ───────────────────────────────────────
  Color _statusColor(dynamic r) {
    if (_isExpired(r)) return Colors.grey;
    switch (r.wardenStatus as String) {
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
    switch (r.wardenStatus as String) {
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
    switch (r.wardenStatus as String) {
      case 'rejected':
        return AppConstants.rejectedColor.withValues(alpha: 0.07);
      default:
        return AppConstants.primaryColor.withValues(alpha: 0.07);
    }
  }

  Color _cardBorder(dynamic r) {
    if (_isExpired(r)) return Colors.grey.withValues(alpha: 0.2);
    switch (r.wardenStatus as String) {
      case 'rejected':
        return AppConstants.rejectedColor.withValues(alpha: 0.2);
      default:
        return AppConstants.primaryColor.withValues(alpha: 0.18);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final wardenProvider = Provider.of<WardenProvider>(context);

    final fullName = authProvider.userProfile?.fullName ?? 'Warden';
    final initials = fullName.isNotEmpty ? fullName[0].toUpperCase() : 'W';

    final pendingRequests = wardenProvider.pendingWardenRequests
        .where((r) => !_isExpired(r))
        .toList();
    final approvedPasses = wardenProvider.requests
        .where((r) => r.wardenStatus == 'approved')
        .toList();
    approvedPasses.sort((a, b) => b.createdAt.compareTo(a.createdAt));

    final Set<String> _seenStudents = {};
    final List<dynamic> studentList = [];
    for (var r in wardenProvider.requests) {
      if (r.studentId != null && !_seenStudents.contains(r.studentId)) {
        _seenStudents.add(r.studentId!);
        studentList.add(r);
      }
    }

    final activePassess = wardenProvider.requests
        .where((r) => r.wardenStatus == 'approved' && !_isExpired(r))
        .toList();
    final rejectedRequests = wardenProvider.rejectedRequests;
    final activeCount = activePassess.length;

    Widget body;
    switch (_selectedIndex) {
      case 1:
        body = _WardenListPage(
          title: 'Approval History',
          requests: approvedPasses,
          type: 'history',
          icon: Icons.history,
          isLoading: wardenProvider.isLoading,
          onRefresh: _loadData,
          isExpiredFn: _isExpired,
          statusColorFn: _statusColor,
          statusLabelFn: _statusLabel,
          cardBgFn: _cardBg,
          cardBorderFn: _cardBorder,
        );
        break;
      case 2:
        body = _WardenStudentsListPage(
          title: 'Enrolled Students',
          students: studentList,
          isLoading: wardenProvider.isLoading,
          onRefresh: _loadData,
        );
        break;
      case 3:
        body = _WardenListPage(
          title: 'Pending Passes',
          requests: pendingRequests,
          type: 'pending',
          icon: Icons.pending_actions,
          isLoading: wardenProvider.isLoading,
          onRefresh: _loadData,
          isExpiredFn: _isExpired,
          statusColorFn: _statusColor,
          statusLabelFn: _statusLabel,
          cardBgFn: _cardBg,
          cardBorderFn: _cardBorder,
        );
        break;
      case 4:
        body = _WardenListPage(
          title: 'Active Passes',
          requests: activePassess,
          type: 'active',
          icon: Icons.verified_outlined,
          isLoading: wardenProvider.isLoading,
          onRefresh: _loadData,
          isExpiredFn: _isExpired,
          statusColorFn: _statusColor,
          statusLabelFn: _statusLabel,
          cardBgFn: _cardBg,
          cardBorderFn: _cardBorder,
        );
        break;
      case 5:
        body = _WardenListPage(
          title: 'Rejected Passes',
          requests: rejectedRequests,
          type: 'rejected',
          icon: Icons.cancel_outlined,
          isLoading: wardenProvider.isLoading,
          onRefresh: _loadData,
          isExpiredFn: _isExpired,
          statusColorFn: _statusColor,
          statusLabelFn: _statusLabel,
          cardBgFn: _cardBg,
          cardBorderFn: _cardBorder,
        );
        break;
      case 6:
        body = const CommonSettingsScreen();
        break;
      default:
        body = _buildHomePage(
          isLoading: wardenProvider.isLoading,
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
        body: Column(
          children: [
            _buildHeader(
              context,
              fullName,
              initials,
              pendingCount: pendingRequests.length,
              activeCount: activeCount,
              rejectedCount: rejectedRequests.length,
              authProvider: authProvider,
            ),
            Expanded(child: body),
          ],
        ),
      ),
    );
  }

  // ─────────────────── TOP HEADER ──────────────────────────────────────────

  Widget _buildHeader(
    BuildContext context,
    String fullName,
    String initials, {
    required int pendingCount,
    required int activeCount,
    required int rejectedCount,
    required AuthProvider authProvider,
  }) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppConstants.primaryColor,
        borderRadius: const BorderRadius.vertical(
          bottom: Radius.circular(30),
        ),
      ),
      padding: EdgeInsets.fromLTRB(
        20,
        MediaQuery.of(context).padding.top + 20,
        10,
        32,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top row: date, icons
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 12.0),
                child: Text(
                  DateFormat('EEEE, dd MMM yyyy').format(DateTime.now()),
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.8),
                    fontSize: 14,
                  ),
                ),
              ),
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.home, color: Colors.white),
                    onPressed: () => setState(() => _selectedIndex = 0),
                  ),
                  IconButton(
                    icon: const Icon(Icons.settings, color: Colors.white),
                    onPressed: () => setState(() => _selectedIndex = 6),
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
          const SizedBox(height: 8),
          // Greeting
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
          // Stat items
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildStatItem('Pending\nPasses', pendingCount.toString(),
                  () => setState(() => _selectedIndex = 3)),
              Container(
                  height: 40,
                  width: 1,
                  color: Colors.white.withValues(alpha: 0.2)),
              _buildStatItem('Active\nPasses', activeCount.toString(),
                  () => setState(() => _selectedIndex = 4)),
              Container(
                  height: 40,
                  width: 1,
                  color: Colors.white.withValues(alpha: 0.2)),
              _buildStatItem('Rejected\nPasses', rejectedCount.toString(),
                  () => setState(() => _selectedIndex = 5)),
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

  // ─────────────────── HOME PAGE ──────────────────────────────────────────

  Widget _buildHomePage({
    required bool isLoading,
  }) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 30, 20, 20),
        children: [
          Row(
            children: [
              Expanded(
                child: _buildSelectionCard(
                  title: 'Passes',
                  subtitle: 'Approval History',
                  icon: Icons.history,
                  iconBgColor: AppConstants.primaryColor.withValues(alpha: 0.1),
                  iconColor: AppConstants.primaryColor,
                  onTap: () => setState(() => _selectedIndex = 1),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildSelectionCard(
                  title: 'Students',
                  subtitle: 'Enrolled List',
                  icon: Icons.people_outline,
                  iconBgColor: Colors.purple.withValues(alpha: 0.1),
                  iconColor: Colors.purple,
                  onTap: () => setState(() => _selectedIndex = 2),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
        ],
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

  // ————————————————— LIST PAGE ————————————————————————————————————————————————————
}

class _WardenListPage extends StatefulWidget {
  final String title;
  final List requests;
  final String type;
  final IconData icon;
  final bool isLoading;
  final Future<void> Function() onRefresh;
  final bool Function(dynamic) isExpiredFn;
  final Color Function(dynamic) statusColorFn;
  final String Function(dynamic) statusLabelFn;
  final Color Function(dynamic) cardBgFn;
  final Color Function(dynamic) cardBorderFn;

  const _WardenListPage({
    required this.title,
    required this.requests,
    required this.type,
    required this.icon,
    required this.isLoading,
    required this.onRefresh,
    required this.isExpiredFn,
    required this.statusColorFn,
    required this.statusLabelFn,
    required this.cardBgFn,
    required this.cardBorderFn,
  });

  @override
  State<_WardenListPage> createState() => _WardenListPageState();
}

class _WardenListPageState extends State<_WardenListPage> {
  String _search = '';
  final TextEditingController _ctrl = TextEditingController();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final filtered = _search.isEmpty
        ? widget.requests
        : widget.requests.where((r) {
            final q = _search.toLowerCase();
            return (r.studentName ?? '').toLowerCase().contains(q) ||
                r.reason.toLowerCase().contains(q) ||
                r.destination.toLowerCase().contains(q);
          }).toList();

    return Column(
      children: [
        // ── Header with search bar ──────────────────────────────────────
        Container(
          color: Colors.grey[50],
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.title,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppConstants.primaryColor,
                  fontStyle: FontStyle.italic,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                height: 44,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    const SizedBox(width: 12),
                    Icon(Icons.search, color: Colors.grey[400], size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: _ctrl,
                        onChanged: (v) => setState(() => _search = v),
                        decoration: InputDecoration(
                          hintText: 'Search passes...',
                          hintStyle:
                              TextStyle(color: Colors.grey[400], fontSize: 13),
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding:
                              const EdgeInsets.symmetric(vertical: 13),
                        ),
                        style: const TextStyle(fontSize: 13),
                      ),
                    ),
                    if (_search.isNotEmpty)
                      IconButton(
                        icon: Icon(Icons.clear,
                            color: Colors.grey[400], size: 18),
                        onPressed: () {
                          _ctrl.clear();
                          setState(() => _search = '');
                        },
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // ── Content ────────────────────────────────────────────────────
        Expanded(
          child: filtered.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(widget.icon, size: 80, color: Colors.grey[300]),
                      const SizedBox(height: 16),
                      Text(
                        _search.isEmpty
                            ? 'No ${widget.title.toLowerCase()} found'
                            : 'No results for "$_search"',
                        style:
                            TextStyle(fontSize: 16, color: Colors.grey[500]),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: widget.onRefresh,
                  color: AppConstants.primaryColor,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final r = filtered[index];
                      return _buildListCard(context, r);
                    },
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildListCard(BuildContext context, dynamic r) {
    final bool expired = widget.isExpiredFn(r);
    final Color sc = widget.statusColorFn(r);
    final String label = widget.statusLabelFn(r);
    final Color bg = widget.cardBgFn(r);
    final Color border = widget.cardBorderFn(r);

    void showDetail() {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => WardenRequestDetailScreen(
            request: r,
            requestType: widget.type,
          ),
        ),
      ).then((_) => widget.onRefresh());
    }

    return GestureDetector(
      onTap: showDetail,
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
          ],
        ),
      ),
    );
  }
}

class _WardenStudentsListPage extends StatefulWidget {
  final String title;
  final List<dynamic> students;
  final bool isLoading;
  final Future<void> Function() onRefresh;

  const _WardenStudentsListPage({
    required this.title,
    required this.students,
    required this.isLoading,
    required this.onRefresh,
  });

  @override
  State<_WardenStudentsListPage> createState() => _WardenStudentsListPageState();
}

class _WardenStudentsListPageState extends State<_WardenStudentsListPage> {
  String _search = '';
  final TextEditingController _ctrl = TextEditingController();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final filtered = _search.isEmpty
        ? widget.students
        : widget.students.where((s) {
            final q = _search.toLowerCase();
            return (s.studentName ?? '').toLowerCase().contains(q) ||
                (s.className ?? '').toLowerCase().contains(q) ||
                (s.departmentName ?? '').toLowerCase().contains(q);
          }).toList();

    return Column(
      children: [
        // Header
        Container(
          color: Colors.grey[50],
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.title,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppConstants.primaryColor,
                  fontStyle: FontStyle.italic,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                height: 44,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    const SizedBox(width: 12),
                    Icon(Icons.search, color: Colors.grey[400], size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: _ctrl,
                        onChanged: (v) => setState(() => _search = v),
                        decoration: InputDecoration(
                          hintText: 'Search students...',
                          hintStyle: TextStyle(color: Colors.grey[400], fontSize: 13),
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(vertical: 13),
                        ),
                        style: const TextStyle(fontSize: 13),
                      ),
                    ),
                    if (_search.isNotEmpty)
                      IconButton(
                        icon: Icon(Icons.clear, color: Colors.grey[400], size: 18),
                        onPressed: () {
                          _ctrl.clear();
                          setState(() => _search = '');
                        },
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Content
        Expanded(
          child: filtered.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.people_outline, size: 80, color: Colors.grey[300]),
                      const SizedBox(height: 16),
                      Text(
                        _search.isEmpty
                            ? 'No students found'
                            : 'No results for "$_search"',
                        style: TextStyle(fontSize: 16, color: Colors.grey[500]),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: widget.onRefresh,
                  color: AppConstants.primaryColor,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final s = filtered[index];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: Colors.grey.withValues(alpha: 0.1)),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.03),
                              blurRadius: 10,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 22,
                              backgroundColor: AppConstants.primaryColor.withValues(alpha: 0.1),
                              child: Text(
                                s.studentName?.isNotEmpty == true ? s.studentName![0].toUpperCase() : 'S',
                                style: const TextStyle(
                                  color: AppConstants.primaryColor,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    s.studentName ?? 'Student',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black87,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${s.className ?? "Class"} • ${s.departmentName ?? "Dept"}',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
        ),
      ],
    );
  }
}
