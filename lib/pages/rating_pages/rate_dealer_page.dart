import 'dart:async';
import 'package:ctp/pages/collectionPages/collection_details_page.dart';
import 'package:flutter/material.dart';
import 'package:ctp/components/gradient_background.dart';
import 'package:ctp/components/custom_button.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ctp/providers/offer_provider.dart';

class RateDealerPage extends StatefulWidget {
  final String offerId;

  const RateDealerPage({
    Key? key,
    required this.offerId,
  }) : super(key: key);

  @override
  _RateDealerPageState createState() => _RateDealerPageState();
}

class _RateDealerPageState extends State<RateDealerPage> {
  int _stars = 5;
  String? _dealerProfileImageUrl;
  String? _dealerId;
  bool _isSecondRating = false;
  bool _useDefaultImage = false;

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
    _startImageLoadingTimer();
    _fetchDealerProfileImage();
    _checkIfSecondRating();
  }

  void _startImageLoadingTimer() {
    Timer(const Duration(seconds: 5), () {
      if (_dealerProfileImageUrl == null) {
        setState(() {
          _useDefaultImage = true;
        });
      }
    });
  }

  void _fetchDealerProfileImage() async {
    try {
      OfferProvider offerProvider =
          Provider.of<OfferProvider>(context, listen: false);
      Offer offer = offerProvider.offers.firstWhere(
        (offer) => offer.offerId == widget.offerId,
        orElse: () => Offer(
          offerId: '', // Default or fallback values
          dealerId: '',
          vehicleId: '',
          transportId: '',
          offerStatus: '',
        ),
      );

      if (offer.offerId.isNotEmpty) {
        _dealerId = offer.dealerId;

        if (_dealerId != null) {
          DocumentSnapshot dealerDoc = await FirebaseFirestore.instance
              .collection('users')
              .doc(_dealerId)
              .get();

          if (dealerDoc.exists) {
            setState(() {
              _dealerProfileImageUrl = dealerDoc['profileImageUrl'];
            });

            print('Dealer profile image URL: $_dealerProfileImageUrl');
          } else {
            print('Error: Dealer document does not exist.');
            setState(() {
              _useDefaultImage = true;
            });
          }
        } else {
          print('Error: Dealer ID is null.');
          setState(() {
            _useDefaultImage = true;
          });
        }
      } else {
        print(
            'Error: Offer not found for the provided offerId: ${widget.offerId}');
        setState(() {
          _useDefaultImage = true;
        });
      }
    } catch (e) {
      print('Error fetching dealer profile image: $e');
      setState(() {
        _useDefaultImage = true;
      });
    }
  }

  void _checkIfSecondRating() async {
    if (_dealerId != null) {
      try {
        CollectionReference ratingsRef = FirebaseFirestore.instance
            .collection('users')
            .doc(_dealerId)
            .collection('ratings');

        QuerySnapshot ratingSnapshot =
            await ratingsRef.where('offerId', isEqualTo: widget.offerId).get();

        if (ratingSnapshot.docs.isNotEmpty) {
          setState(() {
            _isSecondRating = true;
          });
        }
      } catch (e) {
        print('Error checking if this is the second rating: $e');
      }
    }
  }

  void _onTraitChanged(bool value, String trait) {
    setState(() {
      _traits[trait] = value;
      _stars = 5 - _traits.values.where((trait) => !trait).length;
    });
  }

  Future<void> _submitRating() async {
    if (_dealerId != null) {
      try {
        CollectionReference ratingsRef = FirebaseFirestore.instance
            .collection('users')
            .doc(_dealerId)
            .collection('ratings');

        await ratingsRef.add({
          'stars': _stars,
          'timestamp': FieldValue.serverTimestamp(),
          'offerId': widget.offerId,
        });

        QuerySnapshot ratingsSnapshot = await ratingsRef.get();
        List<DocumentSnapshot> ratingsDocs = ratingsSnapshot.docs;

        double totalStars = 0;
        for (var doc in ratingsDocs) {
          totalStars += doc['stars'];
        }

        double averageRating = totalStars / ratingsDocs.length;

        await FirebaseFirestore.instance
            .collection('users')
            .doc(_dealerId)
            .update({
          'averageRating': averageRating,
          'ratingCount': ratingsDocs.length,
        });

        // Removed code that changes the offer status
        // await FirebaseFirestore.instance
        //     .collection('offers')
        //     .doc(widget.offerId)
        //     .update({'offerStatus': 'Done'});
      } catch (e) {
        print('Error submitting rating: $e');
      }
    }
  }

  void _onSubmit() async {
    await _submitRating();

    // Always navigate back to the home page after rating
    Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GradientBackground(
        child: Container(
          constraints: const BoxConstraints.expand(),
          child: SingleChildScrollView(
            child: Container(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  const SizedBox(height: 60),
                  SizedBox(
                      width: 100,
                      height: 100,
                      child: Image.asset('lib/assets/CTPLogo.png')),
                  const SizedBox(height: 32),
                  const Text(
                    'RATE THE DEALER',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'The dealer is automatically given five stars. For every trait you uncheck, the dealer loses one star.',
                    style: TextStyle(
                        fontSize: 14,
                        color: Colors.white,
                        fontWeight: FontWeight.w500),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),
                  CircleAvatar(
                    radius: 60,
                    backgroundImage: _useDefaultImage
                        ? const AssetImage(
                                'lib/assets/default-profile-photo.jpg')
                            as ImageProvider
                        : (_dealerProfileImageUrl != null
                            ? NetworkImage(_dealerProfileImageUrl!)
                            : const AssetImage(
                                'lib/assets/default-profile-photo.jpg')),
                  ),
                  const SizedBox(height: 32),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(5, (index) {
                      return Icon(
                        index < _stars ? Icons.star : Icons.star_border,
                        color: const Color(0xFFFF4E00),
                        size: 40.0,
                      );
                    }),
                  ),
                  const SizedBox(height: 64),
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
                                  height: 20.0,
                                  width: 20.0,
                                  decoration: BoxDecoration(
                                    color: _traits[trait]!
                                        ? const Color(0xFFFF4E00)
                                        : Colors.transparent,
                                    borderRadius: BorderRadius.circular(12.0),
                                    border: Border.all(
                                      width: 3.0,
                                      color: const Color(0xFFFFFFFF),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Text(
                                    trait.toUpperCase(),
                                    style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w500),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 32),
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
    );
  }
}