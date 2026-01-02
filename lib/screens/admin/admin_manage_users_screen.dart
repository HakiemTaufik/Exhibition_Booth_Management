import 'package:flutter/material.dart';
import '../../models/user_model.dart';
import '../../database/firestore_service.dart';

class AdminManageUsersScreen extends StatefulWidget {
  const AdminManageUsersScreen({super.key});

  @override
  State<AdminManageUsersScreen> createState() => _AdminManageUsersScreenState();
}

class _AdminManageUsersScreenState extends State<AdminManageUsersScreen> {
  // Default filter is 'All'
  String _filterRole = 'All';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Manage Users"),
        actions: [
          // --- FILTER BUTTON ---
          PopupMenuButton<String>(
            icon: const Icon(Icons.filter_list),
            tooltip: "Filter by Role",
            onSelected: (value) {
              setState(() {
                _filterRole = value;
              });
            },
            itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
              const PopupMenuItem(value: 'All', child: Text('All Roles')),
              const PopupMenuDivider(),
              const PopupMenuItem(value: 'Exhibitor', child: Text('Exhibitors')),
              const PopupMenuItem(value: 'Organizer', child: Text('Organizers')),
              const PopupMenuItem(value: 'Administrator', child: Text('Admins')),
            ],
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          // Optional: Show which filter is active
          if (_filterRole != 'All')
            Container(
              width: double.infinity,
              color: Colors.blue[50],
              padding: const EdgeInsets.all(8),
              child: Center(
                child: Text(
                  "Showing: $_filterRole" "s",
                  style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold),
                ),
              ),
            ),

          Expanded(
            child: StreamBuilder<List<AppUser>>(
              stream: FirestoreService.instance.getAllUsers(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

                final allUsers = snapshot.data!;

                // --- FILTERING LOGIC ---
                final filteredUsers = _filterRole == 'All'
                    ? allUsers
                    : allUsers.where((u) => u.role == _filterRole).toList();

                if (filteredUsers.isEmpty) {
                  return const Center(child: Text("No users found for this role."));
                }

                return ListView.builder(
                  itemCount: filteredUsers.length,
                  itemBuilder: (context, index) {
                    final user = filteredUsers[index];
                    final isMe = user.role == 'Administrator'; // Prevent deleting yourself (basic check)

                    return Card(
                      color: user.isDisabled ? Colors.grey[200] : null,
                      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: user.isDisabled ? Colors.grey : _getRoleColor(user.role),
                          child: Text(user.role.isNotEmpty ? user.role[0] : "?"),
                        ),
                        title: Text(
                          user.email,
                          style: TextStyle(
                            decoration: user.isDisabled ? TextDecoration.lineThrough : null,
                            color: user.isDisabled ? Colors.grey : Colors.black,
                          ),
                        ),
                        subtitle: Text(user.isDisabled ? "DISABLED" : user.role),
                        trailing: PopupMenuButton<String>(
                          onSelected: (value) async {
                            if (value == 'toggle') {
                              await FirestoreService.instance.toggleUserDisabled(user.id!, user.isDisabled);
                            } else if (value == 'reset') {
                              await FirestoreService.instance.sendPasswordReset(user.email);
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text("Reset link sent! (Check SPAM folder)"),
                                    backgroundColor: Colors.green,
                                    duration: Duration(seconds: 4),
                                  ),
                                );
                              }
                            } else if (value == 'delete') {
                              _confirmDelete(context, user);
                            }
                          },
                          itemBuilder: (context) => [
                            PopupMenuItem(
                              value: 'toggle',
                              child: Row(
                                children: [
                                  Icon(user.isDisabled ? Icons.check_circle : Icons.block,
                                      color: user.isDisabled ? Colors.green : Colors.orange, size: 20),
                                  const SizedBox(width: 8),
                                  Text(user.isDisabled ? "Enable" : "Disable"),
                                ],
                              ),
                            ),
                            const PopupMenuItem(
                              value: 'reset',
                              child: Row(
                                children: [
                                  Icon(Icons.lock_reset, color: Colors.blue, size: 20),
                                  const SizedBox(width: 8),
                                  Text("Reset Password"),
                                ],
                              ),
                            ),
                            if (!isMe) // Don't show delete for yourself/admins if preferred
                              const PopupMenuItem(
                                value: 'delete',
                                child: Row(
                                  children: [
                                    Icon(Icons.delete, color: Colors.red, size: 20),
                                    const SizedBox(width: 8),
                                    Text("Delete"),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // Helper for colors
  Color _getRoleColor(String role) {
    switch (role) {
      case 'Administrator': return Colors.redAccent;
      case 'Organizer': return Colors.orangeAccent;
      case 'Exhibitor': return Colors.blueAccent;
      default: return Colors.blue;
    }
  }

  void _confirmDelete(BuildContext context, AppUser user) {
    showDialog(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text("Confirm Delete"),
        content: const Text("This user will lose access immediately. This cannot be undone."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c), child: const Text("Cancel")),
          TextButton(
            onPressed: () {
              FirestoreService.instance.deleteUser(user.id!);
              Navigator.pop(c);
            },
            child: const Text("Delete", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}