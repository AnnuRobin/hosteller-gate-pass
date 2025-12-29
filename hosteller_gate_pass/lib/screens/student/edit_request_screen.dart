import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../models/gate_pass_model.dart';
import '../../providers/gate_pass_provider.dart';
import '../../utils/constants.dart';

class EditRequestScreen extends StatefulWidget {
  final GatePassModel request;

  const EditRequestScreen({Key? key, required this.request}) : super(key: key);

  @override
  State<EditRequestScreen> createState() => _EditRequestScreenState();
}

class _EditRequestScreenState extends State<EditRequestScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _reasonController;
  late TextEditingController _destinationController;
  late DateTime _fromDate;
  late DateTime _toDate;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _reasonController = TextEditingController(text: widget.request.reason);
    _destinationController = TextEditingController(text: widget.request.destination);
    _fromDate = widget.request.fromDate;
    _toDate = widget.request.toDate;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Request'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _reasonController,
                decoration: const InputDecoration(
                  labelText: 'Reason',
                  prefixIcon: Icon(Icons.description),
                ),
                maxLines: 3,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a reason';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _destinationController,
                decoration: const InputDecoration(
                  labelText: 'Destination',
                  prefixIcon: Icon(Icons.location_on),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a destination';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              InkWell(
                onTap: () => _selectDate(context, isFromDate: true),
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'From Date & Time',
                    prefixIcon: Icon(Icons.calendar_today),
                  ),
                  child: Text(
                    DateFormat('MMM dd, yyyy - HH:mm').format(_fromDate),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              InkWell(
                onTap: () => _selectDate(context, isFromDate: false),
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'To Date & Time',
                    prefixIcon: Icon(Icons.event),
                  ),
                  child: Text(
                    DateFormat('MMM dd, yyyy - HH:mm').format(_toDate),
                  ),
                ),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _updateRequest,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: _isSubmitting
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Text('Update Request', style: TextStyle(fontSize: 16)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _selectDate(BuildContext context, {required bool isFromDate}) async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: isFromDate ? _fromDate : _toDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (pickedDate != null) {
      final TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(isFromDate ? _fromDate : _toDate),
      );

      if (pickedTime != null) {
        setState(() {
          final DateTime finalDateTime = DateTime(
            pickedDate.year,
            pickedDate.month,
            pickedDate.day,
            pickedTime.hour,
            pickedTime.minute,
          );

          if (isFromDate) {
            _fromDate = finalDateTime;
          } else {
            _toDate = finalDateTime;
          }
        });
      }
    }
  }

  Future<void> _updateRequest() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_toDate.isBefore(_fromDate)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('To date must be after from date')),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final gatePassProvider = Provider.of<GatePassProvider>(context, listen: false);

      await gatePassProvider.updateRequest(
        requestId: widget.request.id,
        reason: _reasonController.text,
        destination: _destinationController.text,
        fromDate: _fromDate,
        toDate: _toDate,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Request updated successfully!')),
      );

      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      setState(() {
        _isSubmitting = false;
      });
    }
  }

  @override
  void dispose() {
    _reasonController.dispose();
    _destinationController.dispose();
    super.dispose();
  }
}