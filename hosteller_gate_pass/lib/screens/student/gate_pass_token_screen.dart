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
        const SnackBar(content: Text('Check-in recorded successfully.')),
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
    final qrData = _buildQrPayload(req);

    // Render QR as image bytes for PDF
    final qrImageBytes = await QrPainter(
      data: qrData,
      version: QrVersions.auto,
      eyeStyle: const QrEyeStyle(
        eyeShape: QrEyeShape.square,
        color: Color(0xFF064E3B),
      ),
      dataModuleStyle: const QrDataModuleStyle(
        dataModuleShape: QrDataModuleShape.square,
        color: Color(0xFF059669),
      ),
    ).toImageData(300, format: ui.ImageByteFormat.png);

    final qrBytes = qrImageBytes?.buffer.asUint8List();

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
                  color: PdfColor.fromHex('#059669'),
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
                            color: PdfColors.white,
                            fontSize: 11,
                            fontWeight: pw.FontWeight.bold,
                            letterSpacing: 2,
                          ),
                        ),
                        pw.SizedBox(height: 4),
                        pw.Text(
                          'PASS #${req.id.substring(0, 8).toUpperCase()}',
                          style: pw.TextStyle(
                            color: PdfColors.white,
                            fontSize: 10,
                          ),
                        ),
                        pw.SizedBox(height: 8),
                        pw.Text(
                          req.studentName ?? 'Student',
                          style: pw.TextStyle(
                            color: PdfColors.white,
                            fontSize: 18,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                        pw.Text(
                          '${req.hostelName ?? ""} | ${req.className ?? ""}',
                          style: const pw.TextStyle(
                            color: PdfColors.white,
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                    if (qrBytes != null)
                      pw.Container(
                        width: 100,
                        height: 100,
                        padding: const pw.EdgeInsets.all(6),
                        decoration: pw.BoxDecoration(
                          color: PdfColors.white,
                          borderRadius: pw.BorderRadius.circular(6),
                        ),
                        child: pw.Image(pw.MemoryImage(qrBytes)),
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
        actions: [
          IconButton(
            tooltip: 'Download PDF',
            icon: _isGeneratingPdf
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                        color: Colors.white, strokeWidth: 2),
                  )
                : const Icon(Icons.download_rounded, color: Colors.white),
            onPressed: _isGeneratingPdf ? null : _downloadPass,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          children: [
            // Expired info banner (informational, not blocking)
            if (expired) _buildExpiredBanner(req),
            if (expired) const SizedBox(height: 14),
            _buildTokenCard(req, expired),
            const SizedBox(height: 20),
            _buildQrSection(req),
            const SizedBox(height: 20),
            _buildApprovalChain(req),
            const SizedBox(height: 20),
            _buildTravelDetails(req),
            const SizedBox(height: 24),
            _buildGeofenceActionSection(req),
            const SizedBox(height: 24),
            // Download button at the bottom
            _buildDownloadButton(),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  // ── Expired banner ──────────────────────────────────────────────────────────
  Widget _buildExpiredBanner(GatePassModel req) {
    String reason;
    if (req.entryTime != null) {
      reason =
          'Student returned on ${DateFormat('dd MMM yyyy, HH:mm').format(req.entryTime!)}';
    } else if (req.isExpired) {
      reason = 'Marked as used / returned';
    } else {
      reason =
          'Return date passed on ${DateFormat('dd MMM yyyy').format(req.toDate)}';
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF78350F).withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFBBF24), width: 1.5),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline_rounded,
              color: Color(0xFFFBBF24), size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'EXPIRED PASS — INFORMATIONAL',
                  style: TextStyle(
                    color: Color(0xFFFBBF24),
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  reason,
                  style: const TextStyle(
                    color: Color(0xFFFDE68A),
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

  // ── Token card ──────────────────────────────────────────────────────────────
  Widget _buildTokenCard(GatePassModel req, bool expired) {
    final cardColors = expired
        ? const [Color(0xFF374151), Color(0xFF4B5563), Color(0xFF6B7280)]
        : const [Color(0xFF064E3B), Color(0xFF059669), Color(0xFF34D399)];

    return AnimatedBuilder(
      animation: _glowAnim,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: cardColors,
            ),
            boxShadow: [
              BoxShadow(
                color: (expired
                        ? const Color(0xFFFBBF24)
                        : const Color(0xFF34D399))
                    .withOpacity(0.25 * _glowAnim.value),
                blurRadius: 28 * _glowAnim.value,
                spreadRadius: 3,
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
                    Text(
                      expired ? 'EXPIRED GATE PASS' : 'HOSTEL GATE PASS',
                      style: TextStyle(
                        color: expired
                            ? const Color(0xFFFDE68A)
                            : const Color(0xFF064E3B),
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
                    child: Icon(
                      expired ? Icons.schedule_rounded : Icons.verified_rounded,
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
                const Icon(Icons.home_outlined,
                    color: Colors.white70, size: 16),
                const SizedBox(width: 6),
                Text(
                  req.hostelName ?? 'Hostel',
                  style: const TextStyle(color: Colors.white70, fontSize: 14),
                ),
                const SizedBox(width: 16),
                const Icon(Icons.school_outlined,
                    color: Colors.white70, size: 16),
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
            // Status banner
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    expired
                        ? Icons.history_toggle_off_rounded
                        : Icons.check_circle_rounded,
                    color: expired
                        ? const Color(0xFFD97706)
                        : const Color(0xFF10B981),
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    expired
                        ? 'EXPIRED — FOR REFERENCE ONLY'
                        : 'FULLY APPROVED — VALID GATE PASS',
                    style: TextStyle(
                      color: expired
                          ? const Color(0xFFD97706)
                          : const Color(0xFF059669),
                      fontSize: 11,
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

  // ── QR code section ──────────────────────────────────────────────────────────
  Widget _buildQrSection(GatePassModel req) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF334155)),
      ),
      child: Column(
        children: [
          const Text(
            'SCAN QR TO VERIFY',
            style: TextStyle(
              color: Color(0xFF94A3B8),
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: QrImageView(
              data: _buildQrPayload(req),
              version: QrVersions.auto,
              size: 180,
              eyeStyle: const QrEyeStyle(
                eyeShape: QrEyeShape.square,
                color: Color(0xFF064E3B),
              ),
              dataModuleStyle: const QrDataModuleStyle(
                dataModuleShape: QrDataModuleShape.square,
                color: Color(0xFF059669),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Pass ID: ${req.id.substring(0, 8).toUpperCase()}',
            style: const TextStyle(
              color: Color(0xFF64748B),
              fontSize: 12,
              letterSpacing: 1,
            ),
          ),
        ],
      ),
    );
  }

  // ── Approval chain ──────────────────────────────────────────────────────────
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

  // ── Travel details ──────────────────────────────────────────────────────────
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

  // ── Download button ─────────────────────────────────────────────────────────
  Widget _buildGeofenceActionSection(GatePassModel req) {
    if (!req.isFinallyApproved || req.isEffectivelyExpired) {
      return const SizedBox.shrink();
    }

    final bool canCheckOut = req.exitTime == null && req.entryTime == null;
    final travelStartDateOnly = DateTime(
      req.fromDate.year,
      req.fromDate.month,
      req.fromDate.day,
    );
    final travelEndDateOnly = DateTime(
      req.toDate.year,
      req.toDate.month,
      req.toDate.day,
    );
    final now = DateTime.now();
    final currentDateOnly = DateTime(now.year, now.month, now.day);
    final bool hasValidCheckout = req.exitTime != null &&
        req.exitTime!.isAfter(req.fromDate.subtract(const Duration(days: 1))) &&
        req.exitTime!.isBefore(req.toDate.add(const Duration(days: 1)));
    final bool canCheckIn = hasValidCheckout && req.entryTime == null;
    final bool hasExplicitStartTime = req.fromDate.hour != 0 ||
        req.fromDate.minute != 0 ||
        req.fromDate.second != 0 ||
        req.fromDate.millisecond != 0 ||
        req.fromDate.microsecond != 0;
    final bool isCheckoutAllowedToday = hasExplicitStartTime
        ? now.isAfter(req.fromDate) || now.isAtSameMomentAs(req.fromDate)
        : currentDateOnly == travelStartDateOnly;
    final bool isCheckinAllowedToday =
        !currentDateOnly.isBefore(travelStartDateOnly) &&
            !currentDateOnly.isAfter(travelEndDateOnly);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF334155)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Location Check',
            style: TextStyle(
              color: Color(0xFF94A3B8),
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
              style: const TextStyle(color: Colors.white70, fontSize: 13),
            ),
            const SizedBox(height: 14),
            ElevatedButton.icon(
              onPressed: _isLocationActionProcessing || !isCheckoutAllowedToday
                  ? null
                  : _handleStudentCheckOut,
              icon: _isLocationActionProcessing
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.exit_to_app),
              label: const Text('Check Out of Campus'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0EA5E9),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
          if (canCheckIn) ...[
            Text(
              isCheckinAllowedToday
                  ? 'You can record your return to campus here. You must be inside the college geofence to proceed.'
                  : 'Check-in is only allowed during the travel period from ${DateFormat('dd MMM yyyy').format(travelStartDateOnly)} to ${DateFormat('dd MMM yyyy').format(travelEndDateOnly)}.',
              style: const TextStyle(color: Colors.white70, fontSize: 13),
            ),
            const SizedBox(height: 14),
            ElevatedButton.icon(
              onPressed: _isLocationActionProcessing || !isCheckinAllowedToday
                  ? null
                  : _handleStudentCheckIn,
              icon: _isLocationActionProcessing
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.login),
              label: const Text('Check In to Campus'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF22C55E),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
          if (!canCheckOut && !canCheckIn)
            const Text(
              'Your pass state does not allow a location action right now.',
              style: TextStyle(color: Colors.white70, fontSize: 13),
            ),
        ],
      ),
    );
  }

  Widget _buildDownloadButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _isGeneratingPdf ? null : _downloadPass,
        icon: _isGeneratingPdf
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : const Icon(Icons.download_rounded),
        label: Text(
          _isGeneratingPdf ? 'Generating PDF...' : 'Download Gate Pass (PDF)',
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF059669),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }
}
