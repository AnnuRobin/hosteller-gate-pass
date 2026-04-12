import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../utils/constants.dart';

class DashboardListPage extends StatefulWidget {
  final String title;
  final List requests;
  final IconData icon;
  final bool isLoading;
  final Future<void> Function() onRefresh;
  final bool Function(dynamic) isExpiredFn;
  final Color Function(dynamic) statusColorFn;
  final String Function(dynamic) statusLabelFn;
  final Color Function(dynamic) cardBgFn;
  final Color Function(dynamic) cardBorderFn;
  final void Function(BuildContext, dynamic) onCardTap;
  final Widget? Function(BuildContext, dynamic, VoidCallback)? actionButtonsBuilder;

  const DashboardListPage({
    Key? key,
    required this.title,
    required this.requests,
    required this.icon,
    required this.isLoading,
    required this.onRefresh,
    required this.isExpiredFn,
    required this.statusColorFn,
    required this.statusLabelFn,
    required this.cardBgFn,
    required this.cardBorderFn,
    required this.onCardTap,
    this.actionButtonsBuilder,
  }) : super(key: key);

  @override
  State<DashboardListPage> createState() => _DashboardListPageState();
}

class _DashboardListPageState extends State<DashboardListPage> {
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
                r.destination.toLowerCase().contains(q) ||
                (r.className ?? '').toLowerCase().contains(q) ||
                (r.departmentName ?? '').toLowerCase().contains(q);
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
                          hintText: 'Search passes or students...',
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
                            ? 'No ${widget.title} found\nNo results for "$_search"'
                            : 'No results for "$_search"',
                        textAlign: TextAlign.center,
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
      widget.onCardTap(context, r);
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
            if (widget.actionButtonsBuilder != null) ...[
              Builder(
                builder: (ctx) {
                  final btns = widget.actionButtonsBuilder!(ctx, r, showDetail);
                  if (btns != null) {
                    return Padding(
                      padding: const EdgeInsets.only(top: 10),
                      child: btns,
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
            ],
          ],
        ),
      ),
    );
  }
}
