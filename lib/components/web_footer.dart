import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart'; // Add this package for social icons

class WebFooter extends StatelessWidget {
  const WebFooter({super.key});

  Widget _buildSocialIcon(IconData icon, String url) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () {
          // Add URL launch logic here
        },
        child: Container(
          width: 40,
          height: 40,
          margin: const EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(
            shape: icon == FontAwesomeIcons.facebook
                ? BoxShape.circle
                : BoxShape.rectangle,
            borderRadius: icon == FontAwesomeIcons.linkedin
                ? BorderRadius.circular(4)
                : null,
            color: Colors.black,
            border: Border.all(color: Colors.white, width: 1),
          ),
          child: Icon(
            icon,
            color: Colors.white,
            size: 20,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
      decoration: const BoxDecoration(
        color: Colors.black,
        border: Border(
          top: BorderSide(color: Colors.grey, width: 0.5),
        ),
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: Column(
            mainAxisSize: MainAxisSize.min, // Add this to ensure minimum height
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Contact Information (Left)
                  Expanded(
                    flex: 2,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'CONTACT',
                          style: GoogleFonts.openSans(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'info@commericaltraderportal.com',
                          style: GoogleFonts.openSans(
                            color: Colors.white,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Vertical Divider
                  Container(
                    height: 100,
                    width: 1,
                    margin: const EdgeInsets.symmetric(horizontal: 32),
                    color: Colors.grey,
                  ),

                  // Social Media Icons (Right)
                  Expanded(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        _buildSocialIcon(
                            FontAwesomeIcons.facebook, 'https://facebook.com'),
                        _buildSocialIcon(
                            FontAwesomeIcons.linkedin, 'https://linkedin.com'),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              const Divider(color: Colors.grey, height: 1),
              const SizedBox(height: 24),
              // Copyright Notice
              Text(
                '© ${DateTime.now().year} Commercial Trader Portal',
                style: GoogleFonts.openSans(
                  color: Colors.white,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
