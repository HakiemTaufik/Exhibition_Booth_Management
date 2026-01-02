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

  void _addBooth(BuildContext context) {
    showDialog(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text("Add Booth"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameController, decoration: const InputDecoration(labelText: "Name (e.g. A-1)")),
            TextField(controller: priceController, decoration: const InputDecoration(labelText: "Price"), keyboardType: TextInputType.number),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              if (nameController.text.isNotEmpty) {
                final booth = Booth(
                  eventId: event.id!,
                  name: nameController.text,
                  size: '3x3m',
                  price: double.tryParse(priceController.text) ?? 0,
                  status: 'Available',
                );
                FirestoreService.instance.createBooth(booth);
                Navigator.pop(context);
                nameController.clear();
                priceController.clear();
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
                subtitle: Text("RM${booth.price} - ${booth.status}"),
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