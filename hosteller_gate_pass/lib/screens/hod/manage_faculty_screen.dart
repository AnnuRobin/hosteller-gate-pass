import 'package:flutter/material.dart';
import '../../models/user_model.dart';
import '../../services/hod_management_service.dart';
import '../../utils/constants.dart';
import 'add_faculty_screen.dart';

/// Screen for HOD to view, and manage all faculty (advisors) in their department.
class ManageFacultyScreen extends StatefulWidget {
  final String departmentId;
  final String departmentName;

  const ManageFacultyScreen({
    Key? key,
    required this.departmentId,
    required this.departmentName,
  }) : super(key: key);

  @override
  State<ManageFacultyScreen> createState() => _ManageFacultyScreenState();
}

class _ManageFacultyScreenState extends State<ManageFacultyScreen> {
  final HodManagementService _service = HodManagementService();
  List<UserModel> _faculty = [];
  bool _isLoading = true;
  String? _error;
  String _search = '';
  final TextEditingController _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadFaculty();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadFaculty() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final faculty =
          await _service.getDepartmentFaculty(widget.departmentId);
      if (mounted) {
        setState(() {
          _faculty = faculty;
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
    if (_search.trim().isEmpty) return _faculty;
    final q = _search.toLowerCase();
    return _faculty
        .where((f) =>
            f.fullName.toLowerCase().contains(q) ||
            f.email.toLowerCase().contains(q) ||
            (f.phone ?? '').contains(q))
        .toList();
  }

  Future<void> _deleteFaculty(UserModel faculty) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remove Faculty'),
        content: Text(
            'Are you sure you want to remove ${faculty.fullName}? This action cannot be undone.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Remove', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _service.deleteFaculty(faculty.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${faculty.fullName} removed successfully'),
              backgroundColor: Colors.green,
            ),
          );
          _loadFaculty();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
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
              'Manage Faculty',
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
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add_rounded, color: Colors.white),
            tooltip: 'Add Faculty',
            onPressed: () async {
              final created = await Navigator.push<bool>(
                context,
                MaterialPageRoute(
                  builder: (_) => AddFacultyScreen(
                    departmentId: widget.departmentId,
                    departmentName: widget.departmentName,
                  ),
                ),
              );
              if (created == true) _loadFaculty();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // ── Search bar ──────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
            child: Container(
              height: 44,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
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
                      controller: _searchCtrl,
                      onChanged: (v) => setState(() => _search = v),
                      decoration: InputDecoration(
                        hintText: 'Search faculty...',
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
                      icon:
                          Icon(Icons.clear, color: Colors.grey[400], size: 18),
                      onPressed: () {
                        _searchCtrl.clear();
                        setState(() => _search = '');
                      },
                    ),
                ],
              ),
            ),
          ),

          // ── Faculty count ───────────────────────────────────────────
          if (!_isLoading && _error == null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
              child: Row(
                children: [
                  Icon(Icons.badge_outlined,
                      color: AppConstants.primaryColor, size: 16),
                  const SizedBox(width: 6),
                  Text(
                    '${_filtered.length} faculty member${_filtered.length == 1 ? '' : 's'}',
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
                              onPressed: _loadFaculty,
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
                                Icon(Icons.badge_outlined,
                                    size: 64, color: Colors.grey[300]),
                                const SizedBox(height: 12),
                                Text(
                                  _search.isNotEmpty
                                      ? 'No results for "$_search"'
                                      : 'No faculty members yet.\nTap + to add one.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                      color: Colors.grey[500], fontSize: 15),
                                ),
                              ],
                            ),
                          )
                        : RefreshIndicator(
                            onRefresh: _loadFaculty,
                            child: ListView.builder(
                              padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                              itemCount: _filtered.length,
                              itemBuilder: (ctx, i) =>
                                  _facultyCard(_filtered[i]),
                            ),
                          ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final created = await Navigator.push<bool>(
            context,
            MaterialPageRoute(
              builder: (_) => AddFacultyScreen(
                departmentId: widget.departmentId,
                departmentName: widget.departmentName,
              ),
            ),
          );
          if (created == true) _loadFaculty();
        },
        backgroundColor: AppConstants.primaryColor,
        icon: const Icon(Icons.person_add_rounded, color: Colors.white),
        label: const Text('Add Faculty',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _facultyCard(UserModel faculty) {
    final initials = faculty.fullName.isNotEmpty
        ? faculty.fullName[0].toUpperCase()
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
            radius: 26,
            backgroundColor:
                const Color(0xFF8B5CF6).withValues(alpha: 0.12),
            child: Text(
              initials,
              style: const TextStyle(
                color: Color(0xFF8B5CF6),
                fontWeight: FontWeight.bold,
                fontSize: 20,
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
                  faculty.fullName,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  faculty.email,
                  style: TextStyle(color: Colors.grey[500], fontSize: 12),
                ),
                if (faculty.phone != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    faculty.phone!,
                    style:
                        TextStyle(color: Colors.grey[500], fontSize: 12),
                  ),
                ],
              ],
            ),
          ),
          // Actions
          PopupMenuButton<String>(
            icon: Icon(Icons.more_vert, color: Colors.grey[400]),
            onSelected: (value) {
              if (value == 'delete') _deleteFaculty(faculty);
            },
            itemBuilder: (_) => [
              const PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Icons.delete_outline, color: Colors.red, size: 18),
                    SizedBox(width: 8),
                    Text('Remove', style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
