import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ctp/providers/user_provider.dart';

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
  bool _submitting = false;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _firstNameCtrl.dispose();
    _lastNameCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _submitting = true);
    try {
      final userProvider = context.read<UserProvider>();
      await userProvider.createCompanyEmployee(
        email: _emailCtrl.text.trim(),
        firstName: _firstNameCtrl.text.trim().isEmpty
            ? null
            : _firstNameCtrl.text.trim(),
        lastName: _lastNameCtrl.text.trim().isEmpty
            ? null
            : _lastNameCtrl.text.trim(),
        phoneNumber:
            _phoneCtrl.text.trim().isEmpty ? null : _phoneCtrl.text.trim(),
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Employee invited. Pending admin approval.')),
        );
        context.router.maybePop();
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
                      decoration: const InputDecoration(labelText: 'Email'),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty)
                          return 'Email is required';
                        final emailRegex = RegExp(r'^.+@.+\..+$');
                        if (!emailRegex.hasMatch(v.trim()))
                          return 'Enter a valid email';
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _firstNameCtrl,
                      decoration: const InputDecoration(
                          labelText: 'First name (optional)'),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _lastNameCtrl,
                      decoration: const InputDecoration(
                          labelText: 'Last name (optional)'),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _phoneCtrl,
                      decoration:
                          const InputDecoration(labelText: 'Phone (optional)'),
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
