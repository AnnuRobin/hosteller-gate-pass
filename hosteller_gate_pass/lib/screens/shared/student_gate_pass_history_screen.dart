import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/gate_pass_model.dart';
import '../../services/gate_pass_service.dart';
import '../../utils/constants.dart';

/// Reusable screen for HOD (department-scoped) and Advisor (class-scoped)
/// to view per-student gate pass history totals.
class StudentGatePassHistoryScreen extends StatefulWidget {
  /// Fetch mode: 'department' or 'class'
  final String scopeType;
  final String scopeId; // departmentId or classId
  final String scopeName; // e.g. 'Computer Science' or 'CS-A'

  const StudentGatePassHistoryScreen({
    Key? key,
    required this.scopeType,
    required this.scopeId,
    required this.scopeName,
  }) : super(key: key);

  @override
  State<StudentGatePassHistoryScreen> createState() =>
      _StudentGatePassHistoryScreenState();
}

class _StudentGatePassHistoryScreenState
    extends State<StudentGatePassHistoryScreen> {
  final GatePassService _service = GatePassService();
  Map<String, List<GatePassModel>> _grouped = {};
  bool _isLoading = true;
  String? _error;
  String _search = '';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final result = widget.scopeType == 'department'
          ? await _service.getStudentHistoryForDepartment(widget.scopeId)
          : await _service.getStudentHistoryForClass(widget.scopeId);
      setState(() {
        _grouped = result;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  List<MapEntry<String, List<GatePassModel>>> _filteredEntries() {
    final entries = _grouped.entries.toList();
    if (_search.trim().isEmpty) return entries;
    final q = _search.toLowerCase();
    return entries.where((e) {
      final name = e.value.isNotEmpty
          ? (e.value.first.studentName ?? '').toLowerCase()
          : '';
      return name.contains(q);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E293B),
        foregroundColor: Colors.white,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Student Gate Pass History',
              style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16),
            ),
            Text(
              widget.scopeName,
              style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF334155)),
              ),
              child: TextField(
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  hintText: 'Search by student name...',
                  hintStyle: TextStyle(color: Color(0xFF64748B)),
                  prefixIcon: Icon(Icons.search, color: Color(0xFF64748B)),
                  border: InputBorder.none,
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
                onChanged: (v) => setState(() => _search = v),
              ),
            ),
          ),

          // Summary chip
          if (!_isLoading && _error == null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Row(
                children: [
                  _summaryChip(
                    '${_grouped.length}',
                    'Students',
                    const Color(0xFF3B82F6),
                    Icons.people_outline,
                  ),
                  const SizedBox(width: 10),
                  _summaryChip(
                    '${_grouped.values.fold(0, (s, l) => s + l.length)}',
                    'Total Passes',
                    const Color(0xFF10B981),
                    Icons.badge_outlined,
                  ),
                  const SizedBox(width: 10),
                  _summaryChip(
                    '${_grouped.values.fold(0, (s, l) => s + l.where((p) => p.isFinallyApproved).length)}',
                    'Granted',
                    const Color(0xFF059669),
                    Icons.verified_outlined,
                  ),
                ],
              ),
            ),

          // List
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: Color(0xFF059669)))
                : _error != null
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.error_outline,
                                color: Colors.red, size: 48),
                            const SizedBox(height: 12),
                            Text('Error: $_error',
                                style: const TextStyle(color: Colors.white70)),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: _loadData,
                              child: const Text('Retry'),
                            ),
                          ],
                        ),
                      )
                    : _grouped.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.inbox,
                                    size: 64, color: Colors.grey[700]),
                                const SizedBox(height: 12),
                                const Text(
                                  'No gate pass history found',
                                  style: TextStyle(
                                      color: Colors.white70, fontSize: 16),
                                ),
                              ],
                            ),
                          )
                        : RefreshIndicator(
                            onRefresh: _loadData,
                            color: const Color(0xFF059669),
                            child: ListView.builder(
                              padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                              itemCount: _filteredEntries().length,
                              itemBuilder: (context, i) {
                                final entry = _filteredEntries()[i];
                                return _buildStudentHistoryCard(
                                    entry.key, entry.value);
                              },
                            ),
                          ),
          ),
        ],
      ),
    );
  }

  Widget _summaryChip(
      String count, String label, Color color, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
        decoration: BoxDecoration(
          color: color.withOpacity(0.12),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(width: 6),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  count,
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                Text(
                  label,
                  style:
                      TextStyle(color: color.withOpacity(0.8), fontSize: 11),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStudentHistoryCard(
      String studentId, List<GatePassModel> passes) {
    final studentName =
        passes.isNotEmpty ? passes.first.studentName ?? 'Unknown' : 'Unknown';
    final className =
        passes.isNotEmpty ? passes.first.className ?? '' : '';
    final total = passes.length;
    final approved = passes.where((p) => p.isFinallyApproved).length;
    final pending = passes
        .where((p) => !p.isFinallyApproved && p.status != 'rejected')
        .length;
    final rejected = passes.where((p) => p.status == 'rejected').length;
    final expired = passes.where((p) => p.isEffectivelyExpired).length;

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => _StudentDetailHistoryScreen(
              studentName: studentName,
              passes: passes,
            ),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF1E293B),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFF334155)),
        ),
        child: Row(
          children: [
            // Avatar
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: const Color(0xFF059669).withOpacity(0.15),
                shape: BoxShape.circle,
                border: Border.all(
                    color: const Color(0xFF059669).withOpacity(0.4), width: 1.5),
              ),
              child: Center(
                child: Text(
                  studentName.isNotEmpty
                      ? studentName[0].toUpperCase()
                      : '?',
                  style: const TextStyle(
                    color: Color(0xFF34D399),
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    studentName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (className.isNotEmpty)
                    Text(
                      className,
                      style: const TextStyle(
                          color: Color(0xFF94A3B8), fontSize: 12),
                    ),
                  const SizedBox(height: 8),
                  // Stats row
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: [
                      _miniChip('$total Total', const Color(0xFF64748B)),
                      _miniChip('$approved Granted', const Color(0xFF10B981)),
                      if (pending > 0)
                        _miniChip('$pending Pending', const Color(0xFFF59E0B)),
                      if (rejected > 0)
                        _miniChip('$rejected Rejected', const Color(0xFFEF4444)),
                      if (expired > 0)
                        _miniChip('$expired Expired', const Color(0xFF8B5CF6)),
                    ],
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Color(0xFF64748B), size: 22),
          ],
        ),
      ),
    );
  }

  Widget _miniChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

// ── Per-student detail screen ─────────────────────────────────────────────────

class _StudentDetailHistoryScreen extends StatelessWidget {
  final String studentName;
  final List<GatePassModel> passes;

  const _StudentDetailHistoryScreen({
    required this.studentName,
    required this.passes,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E293B),
        foregroundColor: Colors.white,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              studentName,
              style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 15),
            ),
            Text(
              '${passes.length} gate pass${passes.length == 1 ? '' : 'es'} total',
              style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
            ),
          ],
        ),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: passes.length,
        itemBuilder: (context, i) => _buildPassTile(context, passes[i]),
      ),
    );
  }

  Widget _buildPassTile(BuildContext context, GatePassModel pass) {
    Color statusColor;
    String statusLabel;
    IconData statusIcon;

    if (pass.isEffectivelyExpired) {
      statusColor = const Color(0xFF8B5CF6);
      statusLabel = 'Expired';
      statusIcon = Icons.history_toggle_off_rounded;
    } else if (pass.isFinallyApproved) {
      statusColor = const Color(0xFF10B981);
      statusLabel = 'Approved';
      statusIcon = Icons.verified_rounded;
    } else if (pass.status == 'rejected') {
      statusColor = const Color(0xFFEF4444);
      statusLabel = 'Rejected';
      statusIcon = Icons.cancel_outlined;
    } else {
      statusColor = const Color(0xFFF59E0B);
      statusLabel = pass.getStatusText();
      statusIcon = Icons.hourglass_top_rounded;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
            color: statusColor.withOpacity(0.3), width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  pass.reason,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: statusColor.withOpacity(0.5)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(statusIcon, color: statusColor, size: 12),
                    const SizedBox(width: 4),
                    Text(
                      statusLabel,
                      style: TextStyle(
                        color: statusColor,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.location_on_outlined,
                  color: Color(0xFF64748B), size: 14),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  pass.destination,
                  style: const TextStyle(
                      color: Color(0xFF94A3B8), fontSize: 12),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              const Icon(Icons.calendar_today_outlined,
                  color: Color(0xFF64748B), size: 14),
              const SizedBox(width: 4),
              Text(
                '${DateFormat('dd MMM yyyy').format(pass.fromDate)} → ${DateFormat('dd MMM yyyy').format(pass.toDate)}',
                style: const TextStyle(
                    color: Color(0xFF94A3B8), fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              const Icon(Icons.access_time_outlined,
                  color: Color(0xFF64748B), size: 14),
              const SizedBox(width: 4),
              Text(
                'Applied ${DateFormat('dd MMM yyyy').format(pass.createdAt)}',
                style: const TextStyle(
                    color: Color(0xFF64748B), fontSize: 11),
              ),
            ],
          ),
          if (pass.entryTime != null) ...[
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.login_rounded,
                    color: Color(0xFF8B5CF6), size: 14),
                const SizedBox(width: 4),
                Text(
                  'Returned ${DateFormat('dd MMM yyyy, HH:mm').format(pass.entryTime!)}',
                  style: const TextStyle(
                      color: Color(0xFF8B5CF6), fontSize: 11),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
