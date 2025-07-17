import 'package:auto_route/auto_route.dart';
import 'package:ctp/adminScreens/fleet_detail_page.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

@RoutePage()
class FleetsManagementPage extends StatefulWidget {
  const FleetsManagementPage({super.key});
  @override
  State<FleetsManagementPage> createState() => _FleetsManagementPageState();
}

class _FleetsManagementPageState extends State<FleetsManagementPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<List<QueryDocumentSnapshot>> _fetchFleets() async {
    // Replace 'fleets' with your actual collection name
    final snapshot =
        await _firestore.collection('fleets').orderBy('fleetName').get();
    return snapshot.docs;
  }

  void _showFleetDialog({DocumentSnapshot? existingDoc}) {
    final isEditing = existingDoc != null;
    final TextEditingController nameCtrl = TextEditingController(
      text: existingDoc?.get('fleetName') ?? '',
    );

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(
            isEditing ? 'Edit Fleet' : 'New Fleet',
            style: GoogleFonts.montserrat(fontWeight: FontWeight.bold),
          ),
          content: TextField(
            controller: nameCtrl,
            decoration: const InputDecoration(labelText: 'Fleet Name'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final name = nameCtrl.text.trim();
                if (name.isEmpty) return;
                if (isEditing) {
                  await _firestore
                      .collection('fleets')
                      .doc(existingDoc.id)
                      .update({'fleetName': name});
                } else {
                  await _firestore.collection('fleets').add({
                    'fleetName': name,
                    'createdAt': FieldValue.serverTimestamp(),
                    'vehicleIds': <String>[], // start with empty array
                  });
                }
                Navigator.of(context).pop();
                setState(() {}); // Refresh list
              },
              child: Text(isEditing ? 'Save' : 'Create'),
            ),
          ],
        );
      },
    );
  }

  void _deleteFleet(String docId) async {
    await _firestore.collection('fleets').doc(docId).delete();
    setState(() {}); // Refresh list
  }

  @override
  Widget build(BuildContext context) {
    var blue = const Color(0xFF2F7FFF);
    return FutureBuilder<List<QueryDocumentSnapshot>>(
      future: _fetchFleets(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final fleets = snapshot.data ?? [];
        if (fleets.isEmpty) {
          return Center(
            child: Text(
              'No fleets found.\nTap + to add one.',
              textAlign: TextAlign.center,
              style: GoogleFonts.montserrat(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
          );
        }

        return Column(
          children: [
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: fleets.length,
                separatorBuilder: (_, __) => const Divider(),
                itemBuilder: (context, idx) {
                  final doc = fleets[idx];
                  final fleetName =
                      doc.get('fleetName') as String? ?? 'Unnamed';
                  return Card(
                    color: blue.withOpacity(0.2),
                    elevation: 3,
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                      side: BorderSide(color: blue, width: 2),
                    ),
                    child: ListTile(
                      title: Text(
                        fleetName,
                        style: GoogleFonts.montserrat(
                          fontSize: 18,
                          color: Colors.white,
                        ),
                      ),
                      trailing: PopupMenuButton<String>(
                        icon: const Icon(Icons.more_vert,
                            color: Colors.deepOrange),
                        onSelected: (choice) {
                          if (choice == 'edit') {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    FleetDetailPage(fleetId: doc.id),
                              ),
                            );
                          } else if (choice == 'delete') {
                            _deleteFleet(doc.id);
                          }
                        },
                        itemBuilder: (context) => [
                          PopupMenuItem(
                            value: 'edit',
                            child: Text(
                              'Edit',
                              style:
                                  GoogleFonts.montserrat(color: Colors.black),
                            ),
                          ),
                          PopupMenuItem(
                            value: 'delete',
                            child: Text(
                              'Delete',
                              style:
                                  GoogleFonts.montserrat(color: Colors.black),
                            ),
                          ),
                        ],
                      ),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => FleetDetailPage(fleetId: doc.id),
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}
