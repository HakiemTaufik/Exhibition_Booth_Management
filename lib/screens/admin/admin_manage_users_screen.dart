import 'package:flutter/material.dart';
import '../../models/user_model.dart';
import '../../database/firestore_service.dart';

class AdminManageUsersScreen extends StatelessWidget {
  const AdminManageUsersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Manage Users")),
      body: StreamBuilder<List<AppUser>>(
        stream: FirestoreService.instance.getAllUsers(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final users = snapshot.data!;
          return ListView.builder(
            itemCount: users.length,
            itemBuilder: (context, index) {
              final user = users[index];
              return ListTile(
                leading: CircleAvatar(child: Text(user.role[0])),
                title: Text(user.email),
                subtitle: Text(user.role),
                trailing: user.role == 'Administrator'
                    ? null
                    : IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () => FirestoreService.instance.deleteUser(user.id!), // Deletes Firestore doc only
                ),
              );
            },
          );
        },
      ),
    );
  }
}