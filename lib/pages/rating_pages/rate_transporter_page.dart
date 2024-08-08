import 'package:ctp/pages/collectionPages/collection_details_page.dart';
import 'package:flutter/material.dart';
import 'package:ctp/components/gradient_background.dart';
import 'package:ctp/components/custom_button.dart';

class RateTransporterPage extends StatefulWidget {
  final String offerId;
  final bool fromCollectionPage; // Add new parameter

  const RateTransporterPage(
      {Key? key, required this.offerId, required this.fromCollectionPage})
      : super(key: key);

  @override
  _RateTransporterPageState createState() => _RateTransporterPageState();
}

class _RateTransporterPageState extends State<RateTransporterPage> {
  int _stars = 5;
  Map<String, bool> _traits = {
    'Punctual': true,
    'Professional': true,
    'Friendly': true,
    'Communicative': true,
    'Honest/Transparent': true,
  };

  void _onTraitChanged(bool value, String trait) {
    setState(() {
      _traits[trait] = value;
      _stars = 5 - _traits.values.where((trait) => !trait).length;
    });
  }

  void _onSubmit() {
    if (widget.fromCollectionPage) {
      Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => CollectionDetailsPage(
            offerId: widget.offerId,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GradientBackground(
        child: Container(
          height: MediaQuery.of(context).size.height,
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Align(
                    alignment: Alignment.topLeft,
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Image.asset('lib/assets/CTPLogo.png'),
                  const SizedBox(height: 16),
                  const Text(
                    'RATE THE TRANSPORTER',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'The transporter is automatically given five stars. For every trait you uncheck, the transporter loses one star.',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  CircleAvatar(
                    radius: 40,
                    backgroundImage: NetworkImage(
                        'https://via.placeholder.com/150'), // Placeholder image
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(5, (index) {
                      return Icon(
                        index < _stars ? Icons.star : Icons.star_border,
                        color: Colors.orange,
                        size: 40.0, // Increase the size of the stars
                      );
                    }),
                  ),
                  const SizedBox(height: 20),
                  Padding(
                    padding: const EdgeInsets.only(
                        left: 80.0), // Adjust padding to align with stars
                    child: Column(
                      children: _traits.keys.map((trait) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 16.0),
                          child: Row(
                            children: [
                              Container(
                                height: 24.0,
                                width: 24.0,
                                decoration: BoxDecoration(
                                  color: _traits[trait]!
                                      ? Colors.orange
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(12.0),
                                  border: Border.all(
                                    width: 2.0,
                                    color: Colors.orange,
                                  ),
                                ),
                                child: null,
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: GestureDetector(
                                  onTap: () {
                                    _onTraitChanged(!_traits[trait]!, trait);
                                  },
                                  child: Text(
                                    trait,
                                    style: const TextStyle(color: Colors.white),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
              CustomButton(
                text: 'SUBMIT',
                borderColor: Colors.blue,
                onPressed: _onSubmit,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
