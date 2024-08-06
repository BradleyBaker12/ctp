import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:ctp/components/custom_button.dart';
import 'package:ctp/components/gradient_background.dart';
import 'package:provider/provider.dart';
import 'package:ctp/providers/user_provider.dart';

class ConfirmationPage extends StatelessWidget {
  final String location;
  final String address;
  final DateTime date;
  final String time;
  final LatLng latLng;

  const ConfirmationPage({
    super.key,
    required this.location,
    required this.address,
    required this.date,
    required this.time,
    required this.latLng,
  });

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final profilePictureUrl = userProvider.getProfileImageUrl.isNotEmpty
        ? userProvider.getProfileImageUrl
        : 'lib/assets/default_profile_picture.png';

    return Scaffold(
      body: GradientBackground(
        child: SingleChildScrollView(
          child: Container(
            height:
                MediaQuery.of(context).size.height, // Ensure full screen height
            padding: const EdgeInsets.all(16.0),
            child: Column(
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
                  'WAITING ON FINAL INSPECTION',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                CircleAvatar(
                  radius: 40,
                  backgroundImage: NetworkImage(profilePictureUrl),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(5,
                      (index) => const Icon(Icons.star, color: Colors.orange)),
                ),
                const SizedBox(height: 8),
                const Text(
                  'TOYOTA DYNA 7-145',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                const Text(
                  'OFFER',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                const Text(
                  'R 1 000 000',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'TIME: $time',
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  address,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                CustomButton(
                  text: 'RESCHEDULE',
                  borderColor: Colors.blue,
                  onPressed: () {
                    // Handle reschedule action
                  },
                ),
                CustomButton(
                  text: 'INSPECTION COMPLETE',
                  borderColor: Colors.orange, 
                  onPressed: () {
                    // Handle inspection complete action
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
