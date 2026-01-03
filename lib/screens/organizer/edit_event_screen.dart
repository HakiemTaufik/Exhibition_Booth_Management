import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // <--- 1. IMPORT THIS
import '../../models/user_model.dart';
import '../../models/event_model.dart';
import '../../database/firestore_service.dart';

class EditEventScreen extends StatefulWidget {
  final AppUser user;
  final Event? event;

  const EditEventScreen({super.key, required this.user, this.event});

  @override
  State<EditEventScreen> createState() => _EditEventScreenState();
}

class _EditEventScreenState extends State<EditEventScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  final _locationController = TextEditingController();
  final _floorPlanController = TextEditingController();
  final _startDateController = TextEditingController();
  final _endDateController = TextEditingController();

  String _status = 'Upcoming';
  bool _isPublished = false;

  @override
  void initState() {
    super.initState();
    if (widget.event != null) {
      _titleController.text = widget.event!.title;
      _descController.text = widget.event!.description;
      _locationController.text = widget.event!.location;
      _status = widget.event!.status;
      _isPublished = widget.event!.isPublished == 1;
      _floorPlanController.text = widget.event!.floorPlanImage ?? '';
      _startDateController.text = widget.event!.startDate;
      _endDateController.text = widget.event!.endDate;
    }

    // Listen to changes to update the image preview instantly
    _floorPlanController.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _floorPlanController.dispose();
    _titleController.dispose();
    _descController.dispose();
    _locationController.dispose();
    _startDateController.dispose();
    _endDateController.dispose();
    super.dispose();
  }

  // --- HELPER: Parse Date using intl ---
  DateTime? _parseDate(String input) {
    if (input.isEmpty) return null;
    try {
      // Matches the "d/M/yyyy" format used elsewhere in the app
      return DateFormat("d/M/yyyy").parse(input);
    } catch (e) {
      return null;
    }
  }

  Future<void> _saveEvent() async {
    if (!_formKey.currentState!.validate()) return;

    // Validate Date Logic
    final start = _parseDate(_startDateController.text);
    final end = _parseDate(_endDateController.text);

    if (start != null && end != null && end.isBefore(start)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("End Date cannot be before Start Date!")),
      );
      return;
    }

    final newEvent = Event(
      id: widget.event?.id,
      organizerId: widget.event?.organizerId ?? widget.user.id!,
      title: _titleController.text,
      description: _descController.text,
      location: _locationController.text,
      status: _status,
      isPublished: _isPublished ? 1 : 0,
      floorPlanImage: _floorPlanController.text.trim().isEmpty ? null : _floorPlanController.text.trim(),
      startDate: _startDateController.text,
      endDate: _endDateController.text,
    );

    if (widget.event == null) {
      await FirestoreService.instance.createEvent(newEvent);
    } else {
      await FirestoreService.instance.updateEvent(newEvent);
    }

    if (!mounted) return;
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(widget.event == null ? "Event Created!" : "Event Updated!"))
    );
  }

  // --- DATE PICKER LOGIC ---
  Future<void> _pickDate(TextEditingController controller, {DateTime? minDate}) async {
    DateTime initial = DateTime.now();

    // 1. If valid minDate exists, ensure initial is not before it
    if (minDate != null && initial.isBefore(minDate)) {
      initial = minDate;
    }

    // 2. If controller has a date, try to use it as initial
    DateTime? currentSelection = _parseDate(controller.text);
    if (currentSelection != null) {
      if (minDate == null || !currentSelection.isBefore(minDate)) {
        initial = currentSelection;
      }
    }

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: minDate ?? DateTime(2025),
      lastDate: DateTime(2030),
    );

    if (picked != null) {
      // --- FORMAT: d/M/yyyy (e.g. 8/1/2026 or 08/01/2026) ---
      // utilizing intl to keep it standard
      controller.text = DateFormat("d/M/yyyy").format(picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.event == null ? "Create Event" : "Edit Event")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title
              TextFormField(
                  controller: _titleController,
                  decoration: const InputDecoration(labelText: "Title"),
                  validator: (v) => v!.isEmpty ? "Required" : null
              ),
              const SizedBox(height: 10),

              // Dates Row
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _startDateController,
                      decoration: const InputDecoration(labelText: "Start Date", suffixIcon: Icon(Icons.calendar_today)),
                      readOnly: true,
                      onTap: () => _pickDate(_startDateController),
                      validator: (v) => v!.isEmpty ? "Required" : null,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextFormField(
                      controller: _endDateController,
                      decoration: const InputDecoration(labelText: "End Date", suffixIcon: Icon(Icons.calendar_today)),
                      readOnly: true,
                      onTap: () {
                        // Pass start date as minimum for end date
                        DateTime? start = _parseDate(_startDateController.text);
                        _pickDate(_endDateController, minDate: start);
                      },
                      validator: (v) => v!.isEmpty ? "Required" : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // Location
              TextFormField(
                  controller: _locationController,
                  decoration: const InputDecoration(labelText: "Location"),
                  validator: (v) => v!.isEmpty ? "Required" : null
              ),
              const SizedBox(height: 10),

              // Description
              TextFormField(
                  controller: _descController,
                  decoration: const InputDecoration(labelText: "Description"),
                  maxLines: 3
              ),
              const SizedBox(height: 20),

              // Floor Plan Image URL
              TextFormField(
                controller: _floorPlanController,
                keyboardType: TextInputType.url,
                decoration: const InputDecoration(
                  labelText: "Floor Plan Image URL",
                  hintText: "https://example.com/map.png",
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.link),
                ),
              ),
              const SizedBox(height: 10),

              // Image Preview
              if (_floorPlanController.text.isNotEmpty)
                Container(
                  height: 200,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(8),
                    color: Colors.grey[200],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      _floorPlanController.text,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) {
                        return const Center(child: Text("Invalid Image URL", style: TextStyle(color: Colors.red)));
                      },
                    ),
                  ),
                ),
              const SizedBox(height: 10),

              // Published Switch
              SwitchListTile(
                  title: const Text("Published?"),
                  subtitle: Text(_isPublished ? "Visible to guests" : "Hidden (Draft)"),
                  value: _isPublished,
                  onChanged: (v) => setState(() => _isPublished = v)
              ),

              const SizedBox(height: 20),

              // Save Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: _saveEvent,
                  child: const Text("Save Event", style: TextStyle(fontSize: 16)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}