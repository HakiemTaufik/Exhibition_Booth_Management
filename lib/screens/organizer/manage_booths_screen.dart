import 'package:flutter/material.dart';
import '../../models/event_model.dart';
import '../../models/booking_model.dart';
import '../../models/booth_model.dart';
import '../../database/firestore_service.dart';

class ManageBoothsScreen extends StatelessWidget {
  final Event event;
  ManageBoothsScreen({super.key, required this.event});

  final nameController = TextEditingController();
  final priceController = TextEditingController();
  // --- NEW ---
  final sizeController = TextEditingController();

  void _addBooth(BuildContext context) {
    showDialog(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text("Add Booth"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameController, decoration: const InputDecoration(labelText: "Name (e.g. A-1)")),
            const SizedBox(height: 10),
            // --- NEW INPUT ---
            TextField(
                controller: sizeController,
                decoration: const InputDecoration(labelText: "Size", hintText: "3x3", suffixText: "m²")
            ),
            const SizedBox(height: 10),
            TextField(controller: priceController, decoration: const InputDecoration(labelText: "Price"), keyboardType: TextInputType.number),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              if (nameController.text.isNotEmpty) {

                String size = sizeController.text.isEmpty ? "3x3" : sizeController.text;
                if (!size.contains("m²")) size += " m²";

                final booth = Booth(
                  eventId: event.id!,
                  name: nameController.text,
                  size: size, // Save size
                  price: double.tryParse(priceController.text) ?? 0,
                  status: 'Available',
                  dimensions: size, // Update both fields just to be safe if model has both
                );
                FirestoreService.instance.createBooth(booth);
                Navigator.pop(context);

                // Clear inputs
                nameController.clear();
                priceController.clear();
                sizeController.clear();
              }
            },
            child: const Text("Add"),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Manage Booths")),
      body: StreamBuilder<List<Booth>>(
        stream: FirestoreService.instance.getBoothsForEvent(event.id!),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final booths = snapshot.data!;

          return ListView.builder(
            itemCount: booths.length,
            itemBuilder: (context, index) {
              final booth = booths[index];
              return ListTile(
                leading: Icon(Icons.store, color: booth.status == 'Available' ? Colors.green : Colors.red),
                title: Text(booth.name),
                // --- SHOW SIZE ---
                subtitle: Text("${booth.dimensions} • RM${booth.price} • ${booth.status}"),
                trailing: IconButton(
                  icon: const Icon(Icons.delete),
                  onPressed: () => FirestoreService.instance.deleteBooth(booth.id!),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _addBooth(context),
        child: const Icon(Icons.add),
      ),
    );
  }
}