import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart'; // <--- 1. IMPORT THIS
import '../../models/user_model.dart';
import '../../models/event_model.dart';
import '../../models/booking_model.dart';
import '../../models/booth_model.dart';
import '../../database/firestore_service.dart';
import '../../providers/user_provider.dart';

class BoothSelectionScreen extends StatefulWidget {
  final Event event;
  final AppUser? user;

  const BoothSelectionScreen({super.key, required this.event, this.user});

  @override
  State<BoothSelectionScreen> createState() => _BoothSelectionScreenState();
}

class _BoothSelectionScreenState extends State<BoothSelectionScreen> {
  final Set<String> _selectedBoothIds = {};
  List<Booth> _allBooths = [];
  List<Booking> _existingBookings = [];

  bool _showFullDescription = false;

  bool _isCompetitorAdjacent(String boothName, String myIndustry) {
    try {
      final parts = boothName.split('-');
      if (parts.length < 2) return false;
      final prefix = parts[0];
      final number = int.parse(parts[1]);
      final neighbors = ["$prefix-${number-1}", "$prefix-${number+1}"];

      for (var booking in _existingBookings) {
        if (booking.status == 'Approved' && neighbors.contains(booking.boothName)) {
          if (booking.industry == myIndustry) return true;
        }
      }
    } catch (e) {
      // Ignore parsing errors
    }
    return false;
  }

  void _toggleSelection(Booth booth) {
    setState(() {
      if (_selectedBoothIds.contains(booth.id)) {
        _selectedBoothIds.remove(booth.id);
      } else {
        _selectedBoothIds.add(booth.id!);
      }
    });
  }

  void _showApplicationForm() {
    final companyCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final industryCtrl = TextEditingController();
    final addOnsCtrl = TextEditingController();
    final user = Provider.of<UserProvider>(context, listen: false).user ?? widget.user;

    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Error: User not found. Please login.")));
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Apply for ${_selectedBoothIds.length} Booths"),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text("Please provide details for your exhibition profile."),
              const SizedBox(height: 10),
              TextField(controller: companyCtrl, decoration: const InputDecoration(labelText: "Company Name", border: OutlineInputBorder())),
              const SizedBox(height: 10),
              TextField(controller: descCtrl, decoration: const InputDecoration(labelText: "Exhibit Description", border: OutlineInputBorder()), maxLines: 2),
              const SizedBox(height: 10),
              TextField(controller: industryCtrl, decoration: const InputDecoration(labelText: "Industry (e.g. Tech, Food)", border: OutlineInputBorder(), helperText: "Used for competitor placement checks")),
              const SizedBox(height: 10),
              TextField(controller: addOnsCtrl, decoration: const InputDecoration(labelText: "Add-ons (WiFi, Furniture)", border: OutlineInputBorder())),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () async {
              if (companyCtrl.text.isEmpty || industryCtrl.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Company & Industry Required")));
                return;
              }

              bool blocked = false;
              for (var boothId in _selectedBoothIds) {
                final booth = _allBooths.firstWhere((b) => b.id == boothId);
                if (_isCompetitorAdjacent(booth.name, industryCtrl.text)) {
                  blocked = true;
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Competitor detected near ${booth.name}. Selection blocked.")));
                  break;
                }
              }

              if (blocked) {
                Navigator.pop(context);
                return;
              }

              for (var boothId in _selectedBoothIds) {
                final booth = _allBooths.firstWhere((b) => b.id == boothId);
                final booking = Booking(
                  userId: user.id!,
                  boothId: boothId,
                  eventId: widget.event.id!,
                  companyName: companyCtrl.text,
                  description: descCtrl.text,
                  status: 'Pending',
                  industry: industryCtrl.text,
                  addOns: addOnsCtrl.text,
                  boothName: booth.name,
                  eventTitle: widget.event.title,
                  exhibitorEmail: user.email,
                  startDate: widget.event.startDate,
                  endDate: widget.event.endDate,
                );
                await FirestoreService.instance.createBooking(booking);
              }

              if (!mounted) return;
              Navigator.pop(context);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Application Submitted Successfully!")));
            },
            child: const Text("Submit Application"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // --- 2. DATE FORMATTING LOGIC ---
    String formattedDate = "${widget.event.startDate} - ${widget.event.endDate}";
    try {
      final inputFormat = DateFormat("d/M/yyyy");
      DateTime start = inputFormat.parse(widget.event.startDate);
      DateTime end = inputFormat.parse(widget.event.endDate);

      final outputFormat = DateFormat('MMM dd, yyyy');
      formattedDate = "${outputFormat.format(start)} - ${outputFormat.format(end)}";
    } catch (e) {
      // Ignore errors
    }
    // --------------------------------

    return Scaffold(
      appBar: AppBar(title: Text("Select Booths: ${widget.event.title}")),
      body: StreamBuilder<List<Booth>>(
        stream: FirestoreService.instance.getBoothsForEvent(widget.event.id!),
        builder: (context, snapshotBooths) {
          return StreamBuilder<List<Booking>>(
              stream: FirestoreService.instance.getBookingsForEvent(widget.event.id!),
              builder: (context, snapshotBookings) {
                if (!snapshotBooths.hasData) return const Center(child: CircularProgressIndicator());

                _allBooths = snapshotBooths.data!;
                if (snapshotBookings.hasData) _existingBookings = snapshotBookings.data!;

                return Column(
                  children: [
                    // --- EVENT DETAILS SECTION ---
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16.0),
                      color: Colors.blue[50],
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.calendar_today, size: 16, color: Colors.blue),
                              const SizedBox(width: 8),
                              // --- 3. USE FORMATTED DATE ---
                              Text(formattedDate, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              const Icon(Icons.location_on, size: 16, color: Colors.grey),
                              const SizedBox(width: 8),
                              Text(widget.event.location, style: const TextStyle(fontSize: 14)),
                            ],
                          ),
                          const SizedBox(height: 12),

                          // EXPANDABLE DESCRIPTION
                          InkWell(
                            onTap: () => setState(() => _showFullDescription = !_showFullDescription),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  widget.event.description,
                                  style: TextStyle(color: Colors.grey[700], height: 1.3),
                                  maxLines: _showFullDescription ? null : 2,
                                  overflow: _showFullDescription ? TextOverflow.visible : TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _showFullDescription ? "Show Less" : "Read More...",
                                  style: TextStyle(color: Colors.blue[700], fontWeight: FontWeight.bold, fontSize: 12),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Floor Plan Image
                    if (widget.event.floorPlanImage != null && widget.event.floorPlanImage!.isNotEmpty)
                      Expanded(
                        flex: 2,
                        child: Container(
                          width: double.infinity,
                          color: Colors.black12,
                          child: Image.network(
                            widget.event.floorPlanImage!,
                            fit: BoxFit.contain,
                            errorBuilder: (c,e,s) => const Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.broken_image, size: 50, color: Colors.grey),
                                  Text("Could not load map"),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),

                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _legendItem(Colors.green, "Available"),
                          _legendItem(Colors.blue, "Selected"),
                          _legendItem(Colors.red, "Booked"),
                        ],
                      ),
                    ),

                    // Booth Grid
                    Expanded(
                      flex: 3,
                      child: GridView.builder(
                        padding: const EdgeInsets.all(16),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 3, crossAxisSpacing: 10, mainAxisSpacing: 10),
                        itemCount: _allBooths.length,
                        itemBuilder: (context, index) {
                          final booth = _allBooths[index];
                          final isBooked = booth.status == 'Booked';
                          final isSelected = _selectedBoothIds.contains(booth.id);

                          Color color = Colors.green[100]!;
                          Color borderColor = Colors.green;

                          if (isBooked) {
                            color = Colors.red[100]!;
                            borderColor = Colors.red;
                          } else if (isSelected) {
                            color = Colors.blue[100]!;
                            borderColor = Colors.blue;
                          }

                          return InkWell(
                            onTap: isBooked ? null : () => _toggleSelection(booth),
                            child: Container(
                              decoration: BoxDecoration(
                                color: color,
                                border: Border.all(color: borderColor, width: 2),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(booth.name, style: TextStyle(fontWeight: FontWeight.bold, color: borderColor)),
                                    if (!isBooked) Text(booth.dimensions, style: const TextStyle(fontSize: 10, fontStyle: FontStyle.italic)),
                                    if (!isBooked) Text("RM${booth.price.toInt()}", style: const TextStyle(fontSize: 10)),
                                    if (isSelected) const Icon(Icons.check_circle, size: 16, color: Colors.blue)
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                );
              }
          );
        },
      ),
      floatingActionButton: _selectedBoothIds.isNotEmpty
          ? FloatingActionButton.extended(
        onPressed: _showApplicationForm,
        label: Text("Apply (${_selectedBoothIds.length})"),
        icon: const Icon(Icons.shopping_cart_checkout),
        backgroundColor: Colors.blue,
      )
          : null,
    );
  }

  Widget _legendItem(Color color, String label) {
    return Row(children: [
      Container(width: 16, height: 16, color: color),
      const SizedBox(width: 4),
      Text(label)
    ]);
  }
}