import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ctp/providers/user_provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

@RoutePage()
class OemInviteEmployeePage extends StatefulWidget {
  const OemInviteEmployeePage({super.key});

  @override
  State<OemInviteEmployeePage> createState() => _OemInviteEmployeePageState();
}

class _OemInviteEmployeePageState extends State<OemInviteEmployeePage> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _firstNameCtrl = TextEditingController();
  final _lastNameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _oemBrandCtrl = TextEditingController();
  final _companyNameCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  bool _submitting = false;
  bool _prefillsApplied = false;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _firstNameCtrl.dispose();
    _lastNameCtrl.dispose();
    _phoneCtrl.dispose();
    _oemBrandCtrl.dispose();
    _companyNameCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _submitting = true);
    try {
      final userProvider = context.read<UserProvider>();
      final managerId = userProvider.user?.uid;
      if (managerId == null) throw Exception('Not authenticated');

      // Prevent duplicate pending requests for same email + manager.
      final existing = await FirebaseFirestore.instance
          .collection('oem_employee_requests')
          .where('proposedEmail', isEqualTo: _emailCtrl.text.trim())
          .where('requestedBy', isEqualTo: managerId)
          .where('status', isEqualTo: 'pending')
          .limit(1)
          .get();
      if (existing.docs.isNotEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content:
                  Text('A pending request already exists for this email.')));
        }
        return;
      }

      // Create pending request for admin review instead of direct account creation.
      await FirebaseFirestore.instance.collection('oem_employee_requests').add({
        'requestedBy': managerId,
        'requestedByEmail': userProvider.getUserEmail,
        'managerName': userProvider.getUserName,
        'managerIsOemManager': userProvider.isOemManager,
        'proposedEmail': _emailCtrl.text.trim(),
        'firstName': _firstNameCtrl.text.trim(),
        'lastName': _lastNameCtrl.text.trim(),
        'phoneNumber': _phoneCtrl.text.trim(),
        'companyName': _companyNameCtrl.text.trim(),
        'oemBrand': _oemBrandCtrl.text.trim(),
        'notes': _notesCtrl.text.trim(),
        'status': 'pending', // pending | approved | rejected | created
        'createdAt': FieldValue.serverTimestamp(),
        'processedAt': null,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Request submitted. Admin will review.')),
        );
        Navigator.of(context).maybePop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to invite: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = context.watch<UserProvider>();
    final isAllowed = userProvider.getUserRole.toLowerCase() == 'admin' ||
        (userProvider.getUserRole.toLowerCase() == 'oem' &&
            userProvider.isOemManager);

    // Pre-fill OEM brand & company name only once to avoid erasing user edits on rebuild.
    if (!_prefillsApplied) {
      _oemBrandCtrl.text = userProvider.oemBrand ?? _oemBrandCtrl.text;
      _companyNameCtrl.text =
          userProvider.getCompanyName ?? _companyNameCtrl.text;
      _prefillsApplied = true;
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Invite OEM Employee')),
      body: !isAllowed
          ? const Center(
              child: Text('Only OEM managers or admins can invite employees.'))
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    TextFormField(
                      controller: _emailCtrl,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                        labelText: 'Employee Email *',
                      ),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) {
                          return 'Email is required';
                        }
                        final emailRegex = RegExp(r'^.+@.+\..+$');
                        if (!emailRegex.hasMatch(v.trim())) {
                          return 'Enter a valid email';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _firstNameCtrl,
                      decoration: const InputDecoration(
                        labelText: 'First name *',
                      ),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) {
                          return 'First name required';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _lastNameCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Last name *',
                      ),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) {
                          return 'Last name required';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _phoneCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Phone Number *',
                      ),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) {
                          return 'Phone required';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _companyNameCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Company Name (Employee)',
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _oemBrandCtrl,
                      decoration: const InputDecoration(
                        labelText: 'OEM Brand *',
                      ),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) {
                          return 'OEM Brand required';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _notesCtrl,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: 'Additional Notes (for Admin)',
                      ),
                    ),
                    const Spacer(),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _submitting ? null : _submit,
                        icon: _submitting
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.send),
                        label: Text(_submitting ? 'Sending...' : 'Send Invite'),
                      ),
                    )
                  ],
                ),
              ),
            ),
    );
  }
}
