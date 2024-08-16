import 'package:ctp/pages/collectionPages/collection_details_page.dart';
import 'package:flutter/material.dart';
import 'package:ctp/components/gradient_background.dart';
import 'package:ctp/components/custom_button.dart';
import 'package:ctp/components/custom_bottom_navigation.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ctp/providers/offer_provider.dart';

class RateTransporterPage extends StatefulWidget {
  final String offerId;
  final bool fromCollectionPage;

  const RateTransporterPage({
    super.key,
    required this.offerId,
    required this.fromCollectionPage,
  });

  @override
  _RateTransporterPageState createState() => _RateTransporterPageState();
}

class _RateTransporterPageState extends State<RateTransporterPage> {
  int _stars = 5;
  int _selectedIndex = 0;
  String? _transporterProfileImageUrl;
  String? _transportId;

  final Map<String, bool> _traits = {
    'Punctual': true,
    'Professional': true,
    'Friendly': true,
    'Communicative': true,
    'Honest/Transparent': true,
  };

  @override
  void initState() {
    super.initState();
    _fetchTransporterProfileImage();
  }

  void _fetchTransporterProfileImage() async {
    try {
      OfferProvider offerProvider =
          Provider.of<OfferProvider>(context, listen: false);
      List<Offer> offers = offerProvider.offers;

      Offer? offer;
      try {
        offer = offers.firstWhere((offer) => offer.offerId == widget.offerId);
      } catch (e) {
        offer = null;
      }

      if (offer != null) {
        print('Found offer with offerId: ${offer.offerId}');
        _transportId = offer.transportId;

        // Fetch transporter profile image URL using the UserProvider
        DocumentSnapshot transporterDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(_transportId)
            .get();

        if (transporterDoc.exists) {
          setState(() {
            _transporterProfileImageUrl = transporterDoc['profileImageUrl'];
          });
        } else {
          print('Error: Transporter document does not exist.');
        }
      } else {
        print(
            'Error: Offer not found for the provided offerId: ${widget.offerId}');
      }
    } catch (e) {
      print('Error fetching transporter profile image: $e');
    }
  }

  void _onTraitChanged(bool value, String trait) {
    setState(() {
      _traits[trait] = value;
      _stars = 5 - _traits.values.where((trait) => !trait).length;
    });
  }

  Future<void> _submitRating() async {
    if (_transportId != null) {
      try {
        CollectionReference ratingsRef = FirebaseFirestore.instance
            .collection('users')
            .doc(_transportId)
            .collection('ratings');

        // Add new rating to the sub-collection
        await ratingsRef.add({
          'stars': _stars,
          'timestamp': FieldValue.serverTimestamp(),
        });

        // Recalculate average rating
        QuerySnapshot ratingsSnapshot = await ratingsRef.get();
        List<DocumentSnapshot> ratingsDocs = ratingsSnapshot.docs;

        double totalStars = 0;
        for (var doc in ratingsDocs) {
          totalStars += doc['stars'];
        }

        double averageRating = totalStars / ratingsDocs.length;

        // Update transporter's average rating
        await FirebaseFirestore.instance
            .collection('users')
            .doc(_transportId)
            .update({
          'averageRating': averageRating,
          'ratingCount': ratingsDocs.length,
        });

        print('Rating submitted and average rating updated.');
      } catch (e) {
        print('Error submitting rating: $e');
      }
    }
  }

  void _onSubmit() async {
    await _submitRating();

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

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GradientBackground(
        child: Container(
          constraints: BoxConstraints.expand(),
          child: SingleChildScrollView(
            child: Container(
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
                          icon:
                              const Icon(Icons.arrow_back, color: Colors.white),
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
                      if (_transporterProfileImageUrl != null)
                        CircleAvatar(
                          radius: 40,
                          backgroundImage:
                              NetworkImage(_transporterProfileImageUrl!),
                        )
                      else
                        const CircularProgressIndicator(),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(5, (index) {
                          return Icon(
                            index < _stars ? Icons.star : Icons.star_border,
                            color: Color(0xFFFF4E00),
                            size: 40.0,
                          );
                        }),
                      ),
                      const SizedBox(height: 20),
                      Padding(
                        padding: const EdgeInsets.only(left: 80.0),
                        child: Column(
                          children: _traits.keys.map((trait) {
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 16.0),
                              child: GestureDetector(
                                onTap: () {
                                  _onTraitChanged(!_traits[trait]!, trait);
                                },
                                child: Row(
                                  children: [
                                    Container(
                                      height: 24.0,
                                      width: 24.0,
                                      decoration: BoxDecoration(
                                        color: _traits[trait]!
                                            ? Color(0xFFFF4E00)
                                            : Colors.transparent,
                                        borderRadius:
                                            BorderRadius.circular(12.0),
                                        border: Border.all(
                                          width: 2.0,
                                          color: Color(0xFFFF4E00),
                                        ),
                                      ),
                                      // Removed the tick mark (Icon)
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Text(
                                        trait,
                                        style: const TextStyle(
                                            color: Colors.white),
                                      ),
                                    ),
                                  ],
                                ),
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
        ),
      ),
      bottomNavigationBar: CustomBottomNavigation(
        selectedIndex: _selectedIndex,
        onItemTapped: _onItemTapped,
      ),
    );
  }
}
