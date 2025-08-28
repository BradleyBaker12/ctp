import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ctp/providers/user_provider.dart';

class OemDemoPage extends StatefulWidget {
  final String? brand;
  const OemDemoPage({super.key, this.brand});

  @override
  State<OemDemoPage> createState() => _OemDemoPageState();
}

class _OemDemoPageState extends State<OemDemoPage> {
  final TextEditingController _controller = TextEditingController();
  final List<String> _popularBrands = const [
    'Scania',
    'Volvo',
    'Mercedes-Benz',
    'MAN',
    'DAF',
    'Iveco',
    'Isuzu',
    'Hino',
  ];
  bool _busy = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    if (widget.brand != null && widget.brand!.isNotEmpty) {
      // Perform setup immediately
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _applyBrand(widget.brand!);
      });
    }
  }

  Future<void> _applyBrand(String brand) async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      await userProvider.setOemRoleAndBrand(brand.trim());
      if (!mounted) return;
      // Go straight to upload flow
      Navigator.of(context).pushReplacementNamed('/vehicleUpload');
    } catch (e) {
      setState(() => _error = 'Failed to enable OEM demo: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_busy) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    return Scaffold(
      appBar: AppBar(title: const Text('OEM Demo Setup')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Pick a brand for your OEM demo account. You’ll only be able to upload vehicles for that brand.',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _popularBrands
                  .map((b) => OutlinedButton(
                        onPressed: () => _applyBrand(b),
                        child: Text(b),
                      ))
                  .toList(),
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _controller,
              decoration: const InputDecoration(
                labelText: 'Or enter a brand name',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () {
                final val = _controller.text.trim();
                if (val.isNotEmpty) _applyBrand(val);
              },
              child: const Text('Start OEM Demo'),
            ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(
                _error!,
                style: const TextStyle(color: Colors.red),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
