import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class OemRequestDetailPage extends StatefulWidget {
  final String requestId;
  const OemRequestDetailPage({super.key, required this.requestId});

  @override
  State<OemRequestDetailPage> createState() => _OemRequestDetailPageState();
}

class _OemRequestDetailPageState extends State<OemRequestDetailPage> {
  DocumentSnapshot? _requestDoc;
  bool _loading = true;
  String? _error;
  bool _processing = false;
  FirebaseAuth? _secondaryAuth;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _ensureSecondaryAuth() async {
    if (_secondaryAuth != null) return;
    try {
      final app = await Firebase.initializeApp(
        name: 'oemRequestSecondary',
        options: Firebase.app().options,
      );
      _secondaryAuth = FirebaseAuth.instanceFor(app: app);
    } catch (_) {
      // If already exists
      try {
        final app = Firebase.app('oemRequestSecondary');
        _secondaryAuth = FirebaseAuth.instanceFor(app: app);
      } catch (e) {
        rethrow;
      }
    }
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final doc = await FirebaseFirestore.instance
          .collection('oem_employee_requests')
          .doc(widget.requestId)
          .get();
      if (!doc.exists) {
        setState(() {
          _error = 'Request not found';
        });
      } else {
        setState(() {
          _requestDoc = doc;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Failed to load: $e';
      });
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  String _genPassword([int length = 12]) {
    const chars =
        'ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz23456789!@#%^*';
    return List.generate(
        length,
        (i) => chars[(DateTime.now().microsecondsSinceEpoch + i * 37) %
            chars.length]).join();
  }

  Future<void> _approve() async {
    if (_requestDoc == null) return;
    final data = _requestDoc!.data() as Map<String, dynamic>;
    if ((data['status'] ?? '').toString().toLowerCase() != 'pending') {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Request already processed.')));
      return;
    }

    final passwordCtrl = TextEditingController(text: _genPassword());
    final formKey = GlobalKey<FormState>();
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: Text('Set Initial Password',
            style: GoogleFonts.montserrat(color: Colors.white)),
        content: Form(
          key: formKey,
          child: TextFormField(
            controller: passwordCtrl,
            style: GoogleFonts.montserrat(color: Colors.white),
            decoration: InputDecoration(
              labelText: 'Password',
              labelStyle: GoogleFonts.montserrat(color: Colors.white70),
            ),
            validator: (v) {
              if (v == null || v.length < 6) return 'Min 6 characters';
              return null;
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel',
                style: GoogleFonts.montserrat(color: Colors.white70)),
          ),
          TextButton(
            child: Text('Approve',
                style: GoogleFonts.montserrat(color: const Color(0xFFFF4E00))),
            onPressed: () {
              if (formKey.currentState!.validate()) {
                Navigator.pop(ctx, passwordCtrl.text.trim());
              }
            },
          )
        ],
      ),
    );
    if (result == null) return; // Cancelled

    setState(() {
      _processing = true;
    });
    try {
      await _ensureSecondaryAuth();
      final email = data['proposedEmail'];
      final firstName = data['firstName'];
      final lastName = data['lastName'];
      final phone = data['phoneNumber'];
      final oemBrand = data['oemBrand'];
      final companyName = data['companyName'];
      final managerId = data['requestedBy'];

      // Use transaction to ensure still pending
      await FirebaseFirestore.instance.runTransaction((tx) async {
        final fresh = await tx.get(_requestDoc!.reference);
        final freshData = fresh.data() as Map<String, dynamic>?;
        if (freshData == null ||
            (freshData['status'] ?? '').toString().toLowerCase() != 'pending') {
          throw Exception('Request already processed');
        }
        final cred = await _secondaryAuth!
            .createUserWithEmailAndPassword(email: email, password: result);
        final newUserId = cred.user!.uid;
        tx.set(FirebaseFirestore.instance.collection('users').doc(newUserId), {
          'firstName': firstName,
          'lastName': lastName,
          'phoneNumber': phone,
          'email': email,
          'createdAt': FieldValue.serverTimestamp(),
          'userRole': 'oem',
          'accountStatus': 'active',
          'createdBy': 'admin',
          'oemBrand': oemBrand,
          'companyName': companyName,
          'isOemManager': false,
          'managerId': managerId,
        });
        tx.update(_requestDoc!.reference, {
          'status': 'created',
          'createdUserId': newUserId,
          'initialPassword':
              result, // NOTE: Storing plain password has security implications.
          'processedAt': FieldValue.serverTimestamp(),
        });
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text(
                'Employee account created. Password copied into request document.')));
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) {
        setState(() {
          _processing = false;
        });
      }
    }
  }

  Future<void> _reject() async {
    if (_requestDoc == null) return;
    setState(() {
      _processing = true;
    });
    try {
      await _requestDoc!.reference.update({
        'status': 'rejected',
        'processedAt': FieldValue.serverTimestamp(),
      });
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Request rejected.')));
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) {
        setState(() {
          _processing = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('OEM Request Detail'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Text(_error!,
                      style: GoogleFonts.montserrat(color: Colors.red)))
              : _requestDoc == null
                  ? const Center(child: Text('No data'))
                  : Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _infoRow('Email', _requestDoc!['proposedEmail']),
                          _infoRow('Name',
                              '${_requestDoc!['firstName'] ?? ''} ${_requestDoc!['lastName'] ?? ''}'),
                          _infoRow('Phone', _requestDoc!['phoneNumber'] ?? ''),
                          _infoRow('OEM Brand', _requestDoc!['oemBrand'] ?? ''),
                          _infoRow(
                              'Company', _requestDoc!['companyName'] ?? ''),
                          _infoRow('Status', _requestDoc!['status'] ?? ''),
                          const Spacer(),
                          if (_processing) const LinearProgressIndicator(),
                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: _processing ? null : _reject,
                                  icon: const Icon(Icons.close),
                                  style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.red),
                                  label: const Text('Reject'),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: _processing ? null : _approve,
                                  icon: const Icon(Icons.check),
                                  style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF0E4CAF)),
                                  label: const Text('Approve & Create'),
                                ),
                              ),
                            ],
                          )
                        ],
                      ),
                    ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
              width: 120,
              child: Text(label,
                  style: GoogleFonts.montserrat(fontWeight: FontWeight.bold))),
          Expanded(child: Text(value, style: GoogleFonts.montserrat())),
        ],
      ),
    );
  }
}
