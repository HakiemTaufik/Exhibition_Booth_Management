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
  final _dateController = TextEditingController();
  final _locationController = TextEditingController();
  final _floorPlanController = TextEditingController();
  String _status = 'Upcoming';
  bool _isPublished = false;

  @override
  void initState() {
    super.initState();
    if (widget.event != null) {
      _titleController.text = widget.event!.title;
      _descController.text = widget.event!.description;
      _dateController.text = widget.event!.date;
      _locationController.text = widget.event!.location;
      _status = widget.event!.status;
      _isPublished = widget.event!.isPublished == 1;
      _floorPlanController.text = widget.event!.floorPlanImage ?? '';
    }
    // Listen to changes to update preview
    _floorPlanController.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _floorPlanController.dispose();
    super.dispose();
  }

  Future<void> _saveEvent() async {
    if (!_formKey.currentState!.validate()) return;

    final newEvent = Event(
      id: widget.event?.id,
      organizerId: widget.event?.organizerId ?? widget.user.id!,
      title: _titleController.text,
      description: _descController.text,
      date: _dateController.text,
      location: _locationController.text,
      status: _status,
      isPublished: _isPublished ? 1 : 0,
      floorPlanImage: _floorPlanController.text.trim().isEmpty ? null : _floorPlanController.text.trim(),
    );

    if (widget.event == null) {
      await FirestoreService.instance.createEvent(newEvent);
    } else {
      await FirestoreService.instance.updateEvent(newEvent);
    }

    if (!mounted) return;
    Navigator.pop(context);
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
              TextFormField(controller: _dateController, decoration: const InputDecoration(labelText: "Date"), validator: (v) => v!.isEmpty ? "Req" : null),
              const SizedBox(height: 10),
              TextFormField(controller: _locationController, decoration: const InputDecoration(labelText: "Location"), validator: (v) => v!.isEmpty ? "Req" : null),
              const SizedBox(height: 10),
              TextFormField(controller: _descController, decoration: const InputDecoration(labelText: "Description"), maxLines: 3),
              const SizedBox(height: 20),

              // --- URL Input ---
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

              // --- IMAGE PREVIEW SECTION ---
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
              // -----------------------------

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