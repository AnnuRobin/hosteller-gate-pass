import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../models/gate_pass_model.dart';
import '../../providers/gate_pass_provider.dart';
import '../../utils/location_constants.dart';

class GatePassTokenScreen extends StatefulWidget {
  final GatePassModel request;

  const GatePassTokenScreen({Key? key, required this.request})
      : super(key: key);

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
  bool _isGeneratingPdf = false;
  bool _isLocationActionProcessing = false;
  late GatePassModel _currentRequest;

  @override
  void initState() {
    super.initState();
    _currentRequest = widget.request;
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
      if (mounted) _stampController.forward();
    });
  }

  @override
  void dispose() {
    _stampController.dispose();
    _glowController.dispose();
    super.dispose();
  }

  Future<Position> _getCurrentPosition() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception(
          'Location services are disabled. Please enable location.');
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception('Location permission denied.');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      throw Exception(
          'Location permission permanently denied. Please enable it in settings.');
    }

    return await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
  }

  Future<bool> _isInsideCampus() async {
    final position = await _getCurrentPosition();
    return LocationConstants.isWithinCampus(
      position.latitude,
      position.longitude,
    );
  }

  Future<void> _handleStudentCheckOut() async {
    setState(() => _isLocationActionProcessing = true);
    try {
      final timeNow = DateTime.now();
      final travelStartDateOnly = DateTime(
        _currentRequest.fromDate.year,
        _currentRequest.fromDate.month,
        _currentRequest.fromDate.day,
      );
      final currentDay = DateTime(timeNow.year, timeNow.month, timeNow.day);
      final hasExplicitStartTime = _currentRequest.fromDate.hour != 0 ||
          _currentRequest.fromDate.minute != 0 ||
          _currentRequest.fromDate.second != 0 ||
          _currentRequest.fromDate.millisecond != 0 ||
          _currentRequest.fromDate.microsecond != 0;
      if (currentDay != travelStartDateOnly) {
        throw Exception(
          'Check-out is only allowed on the travel start date (${DateFormat('dd MMM yyyy').format(_currentRequest.fromDate)}).',
        );
      }
      if (hasExplicitStartTime && timeNow.isBefore(_currentRequest.fromDate)) {
        throw Exception(
          'Check-out time must be on or after ${DateFormat('hh:mm a').format(_currentRequest.fromDate)} on ${DateFormat('dd MMM yyyy').format(_currentRequest.fromDate)}.',
        );
      }

      if (!await _isInsideCampus()) {
        throw Exception('You must be inside the college campus to check out.');
      }

      await Provider.of<GatePassProvider>(context, listen: false)
          .recordExitTime(requestId: _currentRequest.id, exitTime: timeNow);

      setState(() {
        _currentRequest = _currentRequest.copyWith(exitTime: timeNow);
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Check-out recorded successfully.')),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Check-out failed: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLocationActionProcessing = false);
    }
  }

  Future<void> _handleStudentCheckIn() async {
    setState(() => _isLocationActionProcessing = true);
    try {
      final timeNow = DateTime.now();
      final travelStartDateOnly = DateTime(
        _currentRequest.fromDate.year,
        _currentRequest.fromDate.month,
        _currentRequest.fromDate.day,
      );
      final travelEndDateOnly = DateTime(
        _currentRequest.toDate.year,
        _currentRequest.toDate.month,
        _currentRequest.toDate.day,
      );
      final currentDay = DateTime(timeNow.year, timeNow.month, timeNow.day);
      if (currentDay.isBefore(travelStartDateOnly) ||
          currentDay.isAfter(travelEndDateOnly)) {
        throw Exception(
          'Check-in is only allowed between ${DateFormat('dd MMM yyyy').format(_currentRequest.fromDate)} and ${DateFormat('dd MMM yyyy').format(_currentRequest.toDate)}.',
        );
      }

      if (!await _isInsideCampus()) {
        throw Exception('You must be inside the college campus to check in.');
      }

      await Provider.of<GatePassProvider>(context, listen: false)
          .recordEntryTime(requestId: _currentRequest.id, entryTime: timeNow);

      setState(() {
        _currentRequest = _currentRequest.copyWith(
          entryTime: timeNow,
          isExpired: true,
        );
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Check-in successful')),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Check-in failed: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLocationActionProcessing = false);
    }
  }

  // ── QR payload ──────────────────────────────────────────────────────────────
  String _buildQrPayload(GatePassModel req) {
    return 'GATE-PASS|${req.id}|${req.studentName ?? ""}|'
        '${DateFormat('dd-MM-yyyy').format(req.fromDate)}|'
        '${DateFormat('dd-MM-yyyy').format(req.toDate)}|'
        '${req.destination}|APPROVED';
  }

  // ── PDF generation ──────────────────────────────────────────────────────────
  Future<Uint8List> _generatePdf(GatePassModel req) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a5,
        margin: const pw.EdgeInsets.all(24),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Header
              pw.Container(
                width: double.infinity,
                padding:
                    const pw.EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                decoration: pw.BoxDecoration(
                  color: PdfColor(0x10 / 255.0, 0xB9 / 255.0, 0x81 / 255.0, 0.2),
                  borderRadius: pw.BorderRadius.circular(12),
                ),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          'HOSTEL GATE PASS',
                          style: pw.TextStyle(
                            color: PdfColor.fromHex('#064E3B'),
                            fontSize: 11,
                            fontWeight: pw.FontWeight.bold,
                            letterSpacing: 2,
                          ),
                        ),
                        pw.SizedBox(height: 4),
                        pw.Text(
                          'PASS #${req.id.substring(0, 8).toUpperCase()}',
                          style: pw.TextStyle(
                            color: PdfColor.fromHex('#064E3B'),
                            fontSize: 10,
                          ),
                        ),
                        pw.SizedBox(height: 8),
                        pw.Text(
                          req.studentName ?? 'Student',
                          style: pw.TextStyle(
                            color: PdfColor.fromHex('#064E3B'),
                            fontSize: 18,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                        pw.Text(
                          '${req.hostelName ?? ""} | ${req.className ?? ""}',
                          style: pw.TextStyle(
                            color: PdfColor.fromHex('#064E3B'),gir
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 20),

              // Details
              _pdfRow('Purpose', req.reason),
              _pdfRow('Destination', req.destination),
              _pdfRow('From', DateFormat('dd MMM yyyy').format(req.fromDate)),
              _pdfRow(
                  'Return by', DateFormat('dd MMM yyyy').format(req.toDate)),
              if (req.exitTime != null)
                _pdfRow('Scheduled Exit',
                    DateFormat('dd MMM yyyy, HH:mm').format(req.exitTime!)),
              pw.SizedBox(height: 20),
              pw.Divider(color: PdfColor.fromHex('#D1FAE5')),
              pw.SizedBox(height: 12),

              // Approval chain
              pw.Text(
                'APPROVAL CHAIN',
                style: pw.TextStyle(
                  fontSize: 9,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColor.fromHex('#059669'),
                  letterSpacing: 1.5,
                ),
              ),
              pw.SizedBox(height: 8),
              _pdfApproval('Class Advisor', req.advisorStatus,
                  req.advisorApprovedAt, req.advisorRemarks),
              _pdfApproval('Head of Department', req.hodStatus,
                  req.hodApprovedAt, req.hodRemarks),
              _pdfApproval('Warden', req.wardenStatus, req.wardenApprovedAt,
                  req.wardenRemarks),
              pw.SizedBox(height: 20),

              // Footer
              pw.Container(
                width: double.infinity,
                padding: const pw.EdgeInsets.all(10),
                decoration: pw.BoxDecoration(
                  color: PdfColor.fromHex('#D1FAE5'),
                  borderRadius: pw.BorderRadius.circular(8),
                ),
                child: pw.Center(
                  child: pw.Text(
                    req.isEffectivelyExpired
                        ? '[!]  EXPIRED - FOR REFERENCE ONLY'
                        : '[OK]  FULLY APPROVED - VALID GATE PASS',
                    style: pw.TextStyle(
                      color: req.isEffectivelyExpired
                          ? PdfColor.fromHex('#B45309')
                          : PdfColor.fromHex('#065F46'),
                      fontSize: 10,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );

    return pdf.save();
  }

  pw.Widget _pdfRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 8),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.SizedBox(
            width: 90,
            child: pw.Text(
              label,
              style: pw.TextStyle(
                fontSize: 9,
                color: PdfColor.fromHex('#6B7280'),
              ),
            ),
          ),
          pw.Expanded(
            child: pw.Text(
              value,
              style: pw.TextStyle(
                fontSize: 10,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _pdfApproval(
      String role, String status, DateTime? at, String? remarks) {
    final isApproved = status == 'approved';
    final isRejected = status == 'rejected';
    final statusText = isApproved
        ? 'Approved'
        : isRejected
            ? 'Rejected'
            : 'Pending';
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 6),
      child: pw.Row(
        children: [
          pw.Text(
            isApproved
                ? '[OK]'
                : isRejected
                    ? '[X]'
                    : '[ ]',
            style: pw.TextStyle(
              fontSize: 11,
              color: isApproved
                  ? PdfColor.fromHex('#059669')
                  : isRejected
                      ? PdfColors.red
                      : PdfColors.grey,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(width: 8),
          pw.Text(
            role,
            style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(width: 8),
          pw.Text(
            statusText,
            style: pw.TextStyle(
              fontSize: 9,
              color: isApproved
                  ? PdfColor.fromHex('#059669')
                  : isRejected
                      ? PdfColors.red
                      : PdfColors.grey,
            ),
          ),
          if (at != null) ...[
            pw.SizedBox(width: 8),
            pw.Text(
              DateFormat('dd MMM, HH:mm').format(at),
              style: const pw.TextStyle(
                fontSize: 8,
                color: PdfColors.grey,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _downloadPass() async {
    if (_isGeneratingPdf) return;
    setState(() => _isGeneratingPdf = true);
    try {
      final bytes = await _generatePdf(widget.request);
      await Printing.sharePdf(
        bytes: bytes,
        filename:
            'GatePass_${widget.request.id.substring(0, 8).toUpperCase()}.pdf',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not generate PDF: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isGeneratingPdf = false);
    }
  }

  // ── Build ───────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final req = _currentRequest;
    final expired = req.isEffectivelyExpired;

    return Scaffold(
      backgroundColor: Colors.grey[50], // Light theme
      appBar: AppBar(
        backgroundColor: Colors.grey[50],
        foregroundColor: Colors.black,
        elevation: 0,
        title: const Text(
          'Gate Pass Token',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            tooltip: 'Download PDF',
            icon: _isGeneratingPdf
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                        color: Colors.black, strokeWidth: 2),
                  )
                : const Icon(Icons.download_rounded, color: Colors.black),
            onPressed: _isGeneratingPdf ? null : _downloadPass,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Column(
          children: [
            const Text(
              'Gate Pass Granted',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black),
            ),
            const SizedBox(height: 8),
            Text(
              'Your gate pass has been issued successfully',
              style: TextStyle(color: Colors.grey[600], fontSize: 14),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            
            if (expired) _buildExpiredBanner(req),
            if (expired) const SizedBox(height: 16),
            
            _buildTicketCard(req, expired),
            const SizedBox(height: 24),
            _buildGeofenceActionSection(req),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildExpiredBanner(GatePassModel req) {
    String reason;
    if (req.entryTime != null) {
      reason = 'Student returned on ${DateFormat('dd MMM yyyy, HH:mm').format(req.entryTime!)}';
    } else if (req.isExpired) {
      reason = 'Marked as used / returned';
    } else {
      reason = 'Return date passed on ${DateFormat('dd MMM yyyy').format(req.toDate)}';
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.orange.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange.withOpacity(0.3), width: 1.5),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline_rounded, color: Colors.orange, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'EXPIRED PASS — INFORMATIONAL',
                  style: TextStyle(
                    color: Colors.orange,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  reason,
                  style: TextStyle(
                    color: Colors.orange[800],
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTicketCard(GatePassModel req, bool expired) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFF10B981).withOpacity(0.12),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
        border: Border.all(color: Colors.grey.withOpacity(0.1)),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            req.studentName ?? 'Student',
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black),
          ),
          const SizedBox(height: 8),
          Text(
            '${req.hostelName ?? 'Hostel'} • ${req.className ?? req.classId}',
            style: TextStyle(fontSize: 14, color: Colors.grey[600]),
          ),
          const SizedBox(height: 24),
          _buildDashedLine(),
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(child: _buildDetailItem('Purpose', req.reason, Icons.assignment_outlined)),
                    Expanded(child: _buildDetailItem('Destination', req.destination, Icons.location_on_outlined)),
                  ],
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(child: _buildDetailItem('Leave Date', DateFormat('dd MMM yyyy').format(req.fromDate), Icons.calendar_today_outlined)),
                    Expanded(child: _buildDetailItem('Return Date', DateFormat('dd MMM yyyy').format(req.toDate), Icons.event_available_outlined)),
                  ],
                ),
                if (req.exitTime != null) ...[
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: _buildDetailItem('Scheduled Exit', DateFormat('dd MMM yyyy, HH:mm').format(req.exitTime!), Icons.access_time_outlined),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 24),
          _buildDashedLine(),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            decoration: BoxDecoration(
              color: expired ? Colors.orange.withOpacity(0.1) : const Color(0xFF10B981).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  expired ? Icons.history_toggle_off : Icons.check_circle_outline,
                  color: expired ? Colors.orange : const Color(0xFF059669),
                ),
                const SizedBox(width: 8),
                Text(
                  expired ? 'EXPIRED PASS' : 'VALID GATE PASS',
                  style: TextStyle(
                    color: expired ? Colors.orange : const Color(0xFF059669),
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailItem(String label, String value, IconData icon) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 14, color: Colors.grey[500]),
            const SizedBox(width: 4),
            Text(label, style: TextStyle(color: Colors.grey[500], fontSize: 12)),
          ],
        ),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black)),
      ],
    );
  }

  Widget _buildDashedLine() {
    return Row(
      children: List.generate(
        30,
        (index) => Expanded(
          child: Container(
            color: index.isEven ? Colors.grey[300] : Colors.transparent,
            height: 1,
          ),
        ),
      ),
    );
  }

  Widget _buildGeofenceActionSection(GatePassModel req) {
    if (!req.isFinallyApproved || req.isEffectivelyExpired) {
      return const SizedBox.shrink();
    }

    final bool canCheckOut = req.exitTime == null && req.entryTime == null;
    final travelStartDateOnly = DateTime(req.fromDate.year, req.fromDate.month, req.fromDate.day);
    final travelEndDateOnly = DateTime(req.toDate.year, req.toDate.month, req.toDate.day);
    final now = DateTime.now();
    final currentDateOnly = DateTime(now.year, now.month, now.day);
    final bool hasValidCheckout = req.exitTime != null &&
        req.exitTime!.isAfter(req.fromDate.subtract(const Duration(days: 1))) &&
        req.exitTime!.isBefore(req.toDate.add(const Duration(days: 1)));
    final bool canCheckIn = hasValidCheckout && req.entryTime == null;
    final bool hasExplicitStartTime = req.fromDate.hour != 0 || req.fromDate.minute != 0 || req.fromDate.second != 0 || req.fromDate.millisecond != 0 || req.fromDate.microsecond != 0;
    final bool isCheckoutAllowedToday = hasExplicitStartTime
        ? now.isAfter(req.fromDate) || now.isAtSameMomentAs(req.fromDate)
        : currentDateOnly == travelStartDateOnly;
    final bool isCheckinAllowedToday = !currentDateOnly.isBefore(travelStartDateOnly) && !currentDateOnly.isAfter(travelEndDateOnly);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF10B981).withOpacity(0.12),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.transparent),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'LOCATION CHECK',
            style: TextStyle(
              color: Colors.grey[500],
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 14),
          if (canCheckOut) ...[
            Text(
              isCheckoutAllowedToday
                  ? 'You can record your campus exit here. You must be inside the college geofence to proceed.'
                  : hasExplicitStartTime
                      ? 'Check-out is only allowed on the travel start date ${DateFormat('dd MMM yyyy').format(travelStartDateOnly)} and on or after ${DateFormat('hh:mm a').format(req.fromDate)}.'
                      : 'Check-out is only allowed on the travel start date ${DateFormat('dd MMM yyyy').format(travelStartDateOnly)}.',
              style: TextStyle(color: Colors.grey[700], fontSize: 13),
            ),
            const SizedBox(height: 14),
            ElevatedButton.icon(
              onPressed: _isLocationActionProcessing || !isCheckoutAllowedToday ? null : _handleStudentCheckOut,
              icon: _isLocationActionProcessing
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.exit_to_app),
              label: const Text('Check Out of Campus'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF10B981),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
          if (canCheckIn) ...[
            Text(
              isCheckinAllowedToday
                  ? 'You can record your return to campus here. You must be inside the college geofence to proceed.'
                  : 'Check-in is only allowed during the travel period from ${DateFormat('dd MMM yyyy').format(travelStartDateOnly)} to ${DateFormat('dd MMM yyyy').format(travelEndDateOnly)}.',
              style: TextStyle(color: Colors.grey[700], fontSize: 13),
            ),
            const SizedBox(height: 14),
            ElevatedButton.icon(
              onPressed: _isLocationActionProcessing || !isCheckinAllowedToday ? null : _handleStudentCheckIn,
              icon: _isLocationActionProcessing
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.login),
              label: const Text('Check In to Campus'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF10B981),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
          if (!canCheckOut && !canCheckIn)
            Text(
              'Your pass state does not allow a location action right now.',
              style: TextStyle(color: Colors.grey[600], fontSize: 13),
            ),
        ],
      ),
    );
  }

}
