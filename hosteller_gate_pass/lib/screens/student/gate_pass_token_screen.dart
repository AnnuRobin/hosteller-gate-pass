import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/gate_pass_model.dart';

class GatePassTokenScreen extends StatefulWidget {
  final GatePassModel request;

  const GatePassTokenScreen({Key? key, required this.request}) : super(key: key);

  @override
  State<GatePassTokenScreen> createState() => _GatePassTokenScreenState();
}

class _GatePassTokenScreenState extends State<GatePassTokenScreen>
    with TickerProviderStateMixin {
  late AnimationController _stampController;
  late AnimationController _glowController;
  late Animation<double> _stampScale;
  late Animation<double> _stampOpacity;
  late Animation<double> _glowAnim;

  @override
  void initState() {
    super.initState();
    _stampController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);

    _stampScale = Tween<double>(begin: 0.4, end: 1.0).animate(
      CurvedAnimation(parent: _stampController, curve: Curves.elasticOut),
    );
    _stampOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _stampController,
        curve: const Interval(0.0, 0.4, curve: Curves.easeIn),
      ),
    );
    _glowAnim = Tween<double>(begin: 0.5, end: 1.0).animate(_glowController);

    Future.delayed(const Duration(milliseconds: 200), () {
      _stampController.forward();
    });
  }

  @override
  void dispose() {
    _stampController.dispose();
    _glowController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final req = widget.request;
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F172A),
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Gate Pass Token',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          children: [
            _buildTokenCard(req),
            const SizedBox(height: 24),
            _buildApprovalChain(req),
            const SizedBox(height: 24),
            _buildTravelDetails(req),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildTokenCard(GatePassModel req) {
    return AnimatedBuilder(
      animation: _glowAnim,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF064E3B), Color(0xFF059669), Color(0xFF34D399)],
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF34D399).withOpacity(0.3 * _glowAnim.value),
                blurRadius: 32 * _glowAnim.value,
                spreadRadius: 4,
              ),
            ],
          ),
          child: child,
        );
      },
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'HOSTEL GATE PASS',
                      style: TextStyle(
                        color: Color(0xFF064E3B),
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 2,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'PASS #${req.id.substring(0, 8).toUpperCase()}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                // Stamp animation
                AnimatedBuilder(
                  animation: _stampController,
                  builder: (context, child) => Opacity(
                    opacity: _stampOpacity.value,
                    child: Transform.scale(
                      scale: _stampScale.value,
                      child: child,
                    ),
                  ),
                  child: Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 3),
                      color: Colors.white.withOpacity(0.15),
                    ),
                    child: const Icon(
                      Icons.verified_rounded,
                      color: Colors.white,
                      size: 40,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            // Student name
            Text(
              req.studentName ?? 'Student',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 26,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.home_outlined, color: Colors.white70, size: 16),
                const SizedBox(width: 6),
                Text(
                  req.hostelName ?? 'Hostel',
                  style: const TextStyle(color: Colors.white70, fontSize: 14),
                ),
                const SizedBox(width: 16),
                const Icon(Icons.school_outlined, color: Colors.white70, size: 16),
                const SizedBox(width: 6),
                Text(
                  req.className ?? req.classId,
                  style: const TextStyle(color: Colors.white70, fontSize: 14),
                ),
              ],
            ),
            const SizedBox(height: 20),
            // Dashed divider
            Row(
              children: List.generate(
                30,
                (i) => Expanded(
                  child: Container(
                    height: 1,
                    color: i.isEven ? Colors.white38 : Colors.transparent,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Reason
            _buildTokenField('PURPOSE', req.reason),
            const SizedBox(height: 12),
            _buildTokenField('DESTINATION', req.destination),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildTokenField(
                    'LEAVE DATE',
                    DateFormat('dd MMM yyyy').format(req.fromDate),
                  ),
                ),
                Expanded(
                  child: _buildTokenField(
                    'RETURN DATE',
                    DateFormat('dd MMM yyyy').format(req.toDate),
                  ),
                ),
              ],
            ),
            if (req.exitTime != null) ...[
              const SizedBox(height: 12),
              _buildTokenField(
                'SCHEDULED EXIT',
                DateFormat('dd MMM yyyy – HH:mm').format(req.exitTime!),
              ),
            ],
            const SizedBox(height: 20),
            // ALL APPROVED banner
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.check_circle_rounded,
                      color: Color(0xFF10B981), size: 20),
                  SizedBox(width: 8),
                  Text(
                    'FULLY APPROVED — VALID GATE PASS',
                    style: TextStyle(
                      color: Color(0xFF059669),
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTokenField(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFF064E3B),
            fontSize: 10,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.5,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildApprovalChain(GatePassModel req) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF334155)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'APPROVAL CHAIN',
            style: TextStyle(
              color: Color(0xFF94A3B8),
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 16),
          _buildApprovalStep(
            icon: Icons.person_outlined,
            role: 'Class Advisor',
            status: req.advisorStatus,
            approvedAt: req.advisorApprovedAt,
            remarks: req.advisorRemarks,
            isLast: false,
          ),
          _buildApprovalStep(
            icon: Icons.admin_panel_settings_outlined,
            role: 'Head of Department',
            status: req.hodStatus,
            approvedAt: req.hodApprovedAt,
            remarks: req.hodRemarks,
            isLast: false,
          ),
          _buildApprovalStep(
            icon: Icons.security_outlined,
            role: 'Warden',
            status: req.wardenStatus,
            approvedAt: req.wardenApprovedAt,
            remarks: req.wardenRemarks,
            isLast: true,
          ),
        ],
      ),
    );
  }

  Widget _buildApprovalStep({
    required IconData icon,
    required String role,
    required String status,
    required DateTime? approvedAt,
    String? remarks,
    required bool isLast,
  }) {
    final isApproved = status == 'approved';
    final isRejected = status == 'rejected';
    final color = isApproved
        ? const Color(0xFF10B981)
        : isRejected
            ? const Color(0xFFEF4444)
            : const Color(0xFF64748B);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Step icon + connector
        Column(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color.withOpacity(0.12),
                border: Border.all(color: color, width: 2),
              ),
              child: Icon(
                isApproved
                    ? Icons.check_rounded
                    : isRejected
                        ? Icons.close_rounded
                        : icon,
                color: color,
                size: 20,
              ),
            ),
            if (!isLast)
              Container(
                width: 2,
                height: 32,
                margin: const EdgeInsets.symmetric(vertical: 4),
                color: isApproved
                    ? const Color(0xFF10B981).withOpacity(0.4)
                    : const Color(0xFF334155),
              ),
          ],
        ),
        const SizedBox(width: 14),
        // Text info
        Expanded(
          child: Padding(
            padding: EdgeInsets.only(bottom: isLast ? 0 : 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 10),
                Text(
                  role,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        isApproved
                            ? 'Approved'
                            : isRejected
                                ? 'Rejected'
                                : 'Pending',
                        style: TextStyle(
                          color: color,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    if (approvedAt != null) ...[
                      const SizedBox(width: 8),
                      Text(
                        DateFormat('dd MMM, HH:mm').format(approvedAt),
                        style: const TextStyle(
                          color: Color(0xFF64748B),
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ],
                ),
                if (remarks != null && remarks.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    '"$remarks"',
                    style: const TextStyle(
                      color: Color(0xFF94A3B8),
                      fontSize: 12,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTravelDetails(GatePassModel req) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF334155)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'TRIP INFORMATION',
            style: TextStyle(
              color: Color(0xFF94A3B8),
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 16),
          _buildInfoTile(Icons.category_outlined, 'Reason', req.reason),
          _buildInfoTile(
              Icons.location_on_outlined, 'Destination', req.destination),
          _buildInfoTile(
            Icons.calendar_today_outlined,
            'Travel Period',
            '${DateFormat('dd MMM yyyy').format(req.fromDate)} → ${DateFormat('dd MMM yyyy').format(req.toDate)}',
          ),
          if (req.exitTime != null)
            _buildInfoTile(
              Icons.exit_to_app_rounded,
              'Exit Time',
              DateFormat('dd MMM yyyy, HH:mm').format(req.exitTime!),
            ),
          if (req.entryTime != null)
            _buildInfoTile(
              Icons.login_rounded,
              'Entry Time (Returned)',
              DateFormat('dd MMM yyyy, HH:mm').format(req.entryTime!),
            ),
          if (req.wardenRemarks != null && req.wardenRemarks!.isNotEmpty)
            _buildInfoTile(
                Icons.comment_outlined, 'Warden Notes', req.wardenRemarks!),
        ],
      ),
    );
  }

  Widget _buildInfoTile(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: const Color(0xFF64748B)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: Color(0xFF94A3B8),
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
