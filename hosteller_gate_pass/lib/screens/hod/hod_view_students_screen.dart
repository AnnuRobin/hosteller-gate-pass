import 'package:flutter/material.dart';
import '../../models/user_model.dart';
import '../../services/hod_management_service.dart';
import '../../utils/constants.dart';

/// Screen for HOD to view all students in their department, grouped/filtered
/// by semester (1–8 or "All").
class HodViewStudentsScreen extends StatefulWidget {
  final String departmentId;
  final String departmentName;

  const HodViewStudentsScreen({
    Key? key,
    required this.departmentId,
    required this.departmentName,
  }) : super(key: key);

  @override
  State<HodViewStudentsScreen> createState() => _HodViewStudentsScreenState();
}

class _HodViewStudentsScreenState extends State<HodViewStudentsScreen> {
  final HodManagementService _service = HodManagementService();

  List<UserModel> _allStudents = [];
  bool _isLoading = true;
  String? _error;
  int? _selectedSemester; // null = All
  String _search = '';
  final TextEditingController _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadStudents();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadStudents() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final students =
          await _service.getDepartmentStudents(widget.departmentId);
      if (mounted) {
        setState(() {
          _allStudents = students;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  List<UserModel> get _filtered {
    var list = _allStudents;
    // Semester filter
    if (_selectedSemester != null) {
      list = list.where((s) => s.semester == _selectedSemester).toList();
    }
    // Text search
    if (_search.trim().isNotEmpty) {
      final q = _search.toLowerCase();
      list = list
          .where((s) =>
              s.fullName.toLowerCase().contains(q) ||
              (s.email).toLowerCase().contains(q) ||
              (s.phone ?? '').contains(q))
          .toList();
    }
    return list;
  }

  // Group students by semester for display when "All" is selected
  Map<int, List<UserModel>> get _groupedBySemester {
    final map = <int, List<UserModel>>{};
    for (final s in _filtered) {
      final sem = s.semester ?? 0;
      map.putIfAbsent(sem, () => []).add(s);
    }
    return Map.fromEntries(
        map.entries.toList()..sort((a, b) => a.key.compareTo(b.key)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: AppConstants.primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Students',
              style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 17),
            ),
            Text(
              widget.departmentName,
              style: const TextStyle(color: Colors.white70, fontSize: 12),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          // ── Semester + Search bar ────────────────────────────────────
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            child: Column(
              children: [
                // Semester chips
                SizedBox(
                  height: 36,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      _semChip(null, 'All'),
                      ...List.generate(8, (i) => _semChip(i + 1, 'S${i + 1}')),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                // Search bar
                Container(
                  height: 44,
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: Row(
                    children: [
                      const SizedBox(width: 12),
                      Icon(Icons.search, color: Colors.grey[400], size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: _searchCtrl,
                          onChanged: (v) => setState(() => _search = v),
                          decoration: InputDecoration(
                            hintText: 'Search students...',
                            hintStyle: TextStyle(
                                color: Colors.grey[400], fontSize: 13),
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
                            _searchCtrl.clear();
                            setState(() => _search = '');
                          },
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // ── Student count chip ──────────────────────────────────────
          if (!_isLoading && _error == null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Row(
                children: [
                  Icon(Icons.people_outline,
                      color: AppConstants.primaryColor, size: 16),
                  const SizedBox(width: 6),
                  Text(
                    '${_filtered.length} student${_filtered.length == 1 ? '' : 's'}${_selectedSemester != null ? ' in Semester $_selectedSemester' : ''}',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),

          // ── Content ─────────────────────────────────────────────────
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.error_outline,
                                color: Colors.red, size: 48),
                            const SizedBox(height: 12),
                            Text('Error: $_error',
                                style:
                                    const TextStyle(color: Colors.black54)),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: _loadStudents,
                              child: const Text('Retry'),
                            ),
                          ],
                        ),
                      )
                    : _filtered.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.people_outline,
                                    size: 64, color: Colors.grey[300]),
                                const SizedBox(height: 12),
                                Text(
                                  _search.isNotEmpty
                                      ? 'No results for "$_search"'
                                      : _selectedSemester != null
                                          ? 'No students in Semester $_selectedSemester'
                                          : 'No students found',
                                  style: TextStyle(
                                      color: Colors.grey[500], fontSize: 15),
                                ),
                              ],
                            ),
                          )
                        : RefreshIndicator(
                            onRefresh: _loadStudents,
                            child: _selectedSemester != null
                                ? _buildFlatList(_filtered)
                                : _buildGroupedList(),
                          ),
          ),
        ],
      ),
    );
  }

  // ── Semester filter chip ────────────────────────────────────────────────
  Widget _semChip(int? sem, String label) {
    final selected = _selectedSemester == sem;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: () => setState(() => _selectedSemester = sem),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          decoration: BoxDecoration(
            color: selected
                ? AppConstants.primaryColor
                : Colors.grey[100],
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: selected
                  ? AppConstants.primaryColor
                  : Colors.grey[300]!,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: selected ? Colors.white : Colors.grey[700],
              fontWeight:
                  selected ? FontWeight.bold : FontWeight.normal,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }

  // ── Flat list (when a specific semester is selected) ────────────────────
  Widget _buildFlatList(List<UserModel> students) {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      itemCount: students.length,
      itemBuilder: (ctx, i) => _studentCard(students[i]),
    );
  }

  // ── Grouped list by semester (when "All" is selected) ──────────────────
  Widget _buildGroupedList() {
    final groups = _groupedBySemester;
    final keys = groups.keys.toList();

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      itemCount: keys.length,
      itemBuilder: (ctx, i) {
        final sem = keys[i];
        final students = groups[sem]!;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Section header
            Padding(
              padding: const EdgeInsets.fromLTRB(0, 8, 0, 8),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppConstants.primaryColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                          color: AppConstants.primaryColor
                              .withValues(alpha: 0.3)),
                    ),
                    child: Text(
                      sem == 0 ? 'Unassigned' : 'Semester $sem',
                      style: TextStyle(
                        color: AppConstants.primaryColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${students.length} student${students.length == 1 ? '' : 's'}',
                    style: TextStyle(color: Colors.grey[500], fontSize: 12),
                  ),
                ],
              ),
            ),
            ...students.map((s) => _studentCard(s)),
          ],
        );
      },
    );
  }

  // ── Student card ────────────────────────────────────────────────────────
  Widget _studentCard(UserModel student) {
    final initials = student.fullName.isNotEmpty
        ? student.fullName[0].toUpperCase()
        : '?';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
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
          // Avatar
          CircleAvatar(
            radius: 24,
            backgroundColor:
                AppConstants.primaryColor.withValues(alpha: 0.12),
            child: Text(
              initials,
              style: TextStyle(
                color: AppConstants.primaryColor,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ),
          const SizedBox(width: 14),
          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  student.fullName,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  student.email,
                  style: TextStyle(color: Colors.grey[500], fontSize: 12),
                ),
                if (student.phone != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    student.phone!,
                    style:
                        TextStyle(color: Colors.grey[500], fontSize: 12),
                  ),
                ],
              ],
            ),
          ),
          // Semester badge
          if (student.semester != null)
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppConstants.primaryColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'S${student.semester}',
                style: TextStyle(
                  color: AppConstants.primaryColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
