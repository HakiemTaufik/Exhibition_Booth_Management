import 'package:flutter/material.dart';
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
    _floorPlanController.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _floorPlanController.dispose();
    super.dispose();
  }

  // --- NEW HELPER: READ DD/MM/YYYY ---
  DateTime? _parseDate(String input) {
    try {
      final parts = input.split('/');
      if (parts.length != 3) return null;
      // DateTime(Year, Month, Day)
      return DateTime(int.parse(parts[2]), int.parse(parts[1]), int.parse(parts[0]));
    } catch (e) {
      return null;
    }
  }

  Future<void> _saveEvent() async {
    if (!_formKey.currentState!.validate()) return;

    // --- VALIDATION: Use _parseDate now ---
    final start = _parseDate(_startDateController.text);
    final end = _parseDate(_endDateController.text);

    if (start != null && end != null && end.isBefore(start)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("End Date cannot be before Start Date!")),
      );
      return;
    }
    // -------------------------------------

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
  }

  // --- UPDATED DATE PICKER: WRITE DD/MM/YYYY ---
  Future<void> _pickDate(TextEditingController controller, {DateTime? minDate}) async {
    DateTime initial = DateTime.now();

    // 1. Check constraints
    if (minDate != null) {
      if (initial.isBefore(minDate)) {
        initial = minDate;
      }
    }

    // 2. Try to read existing date using _parseDate
    if (controller.text.isNotEmpty) {
      DateTime? stored = _parseDate(controller.text);
      if (stored != null) {
        if (minDate == null || !stored.isBefore(minDate)) {
          initial = stored;
        }
      }
    }

    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: minDate ?? DateTime(2025),
      lastDate: DateTime(2030),
    );

    if (picked != null) {
      // --- FORMAT CHANGE: DD/MM/YYYY ---
      controller.text = "${picked.day.toString().padLeft(2,'0')}/${picked.month.toString().padLeft(2,'0')}/${picked.year}";
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
              TextFormField(controller: _titleController, decoration: const InputDecoration(labelText: "Title"), validator: (v) => v!.isEmpty ? "Req" : null),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _startDateController,
                      decoration: const InputDecoration(labelText: "Start Date", suffixIcon: Icon(Icons.calendar_today)),
                      readOnly: true,
                      onTap: () => _pickDate(_startDateController),
                      validator: (v) => v!.isEmpty ? "Req" : null,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextFormField(
                      controller: _endDateController,
                      decoration: const InputDecoration(labelText: "End Date", suffixIcon: Icon(Icons.calendar_today)),
                      readOnly: true,
                      // --- USE _parseDate TO GET MIN DATE ---
                      onTap: () {
                        DateTime? start = _parseDate(_startDateController.text);
                        _pickDate(_endDateController, minDate: start);
                      },
                      validator: (v) => v!.isEmpty ? "Req" : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              TextFormField(controller: _locationController, decoration: const InputDecoration(labelText: "Location"), validator: (v) => v!.isEmpty ? "Req" : null),
              const SizedBox(height: 10),
              TextFormField(controller: _descController, decoration: const InputDecoration(labelText: "Description"), maxLines: 3),
              const SizedBox(height: 20),
              TextFormField(
                controller: _floorPlanController,
                decoration: const InputDecoration(
                  labelText: "Floor Plan Image URL",
                  hintText: "https://example.com/map.png",
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.link),
                ),
              ),
              const SizedBox(height: 10),
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
              SwitchListTile(title: const Text("Published?"), value: _isPublished, onChanged: (v) => setState(() => _isPublished = v)),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(onPressed: _saveEvent, child: const Text("Save Event")),
              ),
            ],
          ),
        ),
      ),
    );
  }
}