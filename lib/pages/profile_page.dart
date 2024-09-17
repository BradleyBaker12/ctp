import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ctp/providers/user_provider.dart';
import 'edit_profile_page.dart';
import 'package:ctp/components/custom_bottom_navigation.dart';
import 'package:ctp/components/gradient_background.dart';
import 'pdf_viewer_page.dart'; // Import the PDF Viewer Page

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    var screenSize = MediaQuery.of(context).size;
    final userProvider = Provider.of<UserProvider>(context);
    // final size = MediaQuery.of(context).size;
    const Color borderColor = Color(0xFFFF4E00);
    final Color backgroundColor = borderColor.withOpacity(0.6);

    String capitalizeFirstLetter(String? value) {
      if (value == null || value.isEmpty) return '';
      return value[0].toUpperCase() + value.substring(1).toLowerCase();
    }

    return Scaffold(
      body: GradientBackground(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(height: screenSize.height * 0.1),
              Image.asset(
                'lib/assets/CTPLogo.png',
                height: screenSize.height * 0.1,
                width: screenSize.height * 0.1,
                fit: BoxFit.cover,
              ),
              SizedBox(height: screenSize.height * 0.03),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 50,
                      backgroundImage:
                          userProvider.getProfileImageUrl.isNotEmpty
                              ? NetworkImage(userProvider.getProfileImageUrl)
                              : const AssetImage(
                                      'lib/assets/default_profile_photo.jpg')
                                  as ImageProvider,
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  userProvider.getUserName.toUpperCase(),
                                  style: const TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              GestureDetector(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          const EditProfilePage(),
                                    ),
                                  );
                                },
                                child: Text(
                                  'Edit Profile'.toUpperCase(),
                                  style: TextStyle(
                                      fontSize: 16,
                                      color: Colors.white,
                                      decoration: TextDecoration.underline,
                                      decorationColor: Colors.white),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              _buildProfileDetail('FULL NAME',
                  '${userProvider.getFirstName ?? ''} ${userProvider.getMiddleName ?? ''} ${userProvider.getLastName ?? ''}'),
              _buildProfileDetail('EMAIL', userProvider.getUserEmail),
              _buildProfileDetail(
                  'PHONE NUMBER', userProvider.getPhoneNumber ?? ''),
              _buildProfileDetail(
                  'ROLE', capitalizeFirstLetter(userProvider.getUserRole)),
              _buildProfileDetail(
                  'COMPANY NAME', userProvider.getCompanyName ?? ''),
              _buildProfileDetail(
                  'TRADING NAME', userProvider.getTradingName ?? ''),
              _buildProfileDetail(
                  'REG NO.', userProvider.getRegistrationNumber ?? ''),
              _buildProfileDetail('VAT NO.', userProvider.getVatNumber ?? ''),
              _buildProfileDetail(
                  'ADDRESS',
                  '${userProvider.getAddressLine1 ?? ''}\n'
                      '${userProvider.getAddressLine2 ?? ''}\n'
                      '${userProvider.getCity ?? ''}\n'
                      '${userProvider.getState ?? ''}\n'
                      '${userProvider.getPostalCode ?? ''}'),
              const SizedBox(height: 20),
              const Padding(
                padding: EdgeInsets.only(left: 16.0),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'DOCUMENTS',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const Divider(color: Colors.white),
              const SizedBox(height: 10),
              _buildDocumentItem(
                  'BANK CONFIRMATION',
                  userProvider.getBankConfirmationUrl,
                  Icons.visibility,
                  context),
              _buildDocumentItem(
                  'CIPC CERTIFICATE',
                  userProvider.getCipcCertificateUrl,
                  Icons.visibility,
                  context),
              _buildDocumentItem(
                  'PROXY', userProvider.getProxyUrl, Icons.visibility, context),
              _buildDocumentItem(
                  'BRNC', userProvider.getBrncUrl, Icons.visibility, context),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () async {
                  await userProvider.signOut();
                  Navigator.of(context).pushReplacementNamed('/login');
                },
                style: ElevatedButton.styleFrom(
                  side: const BorderSide(color: borderColor, width: 2),
                  backgroundColor: backgroundColor,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text(
                  'Sign Out',
                  style: TextStyle(fontSize: 18, color: Colors.white),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
      bottomNavigationBar: CustomBottomNavigation(
        selectedIndex: 5, // Index for the profile tab
        onItemTapped: (index) {
          // Handle navigation
        },
      ),
    );
  }

  Widget _buildProfileDetail(String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title.toUpperCase(),
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          Flexible(
            child: Text(
              value.toUpperCase(),
              style: const TextStyle(
                  fontSize: 14,
                  color: Colors.white,
                  fontWeight: FontWeight.w600),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDocumentItem(
      String title, String? url, IconData icon, BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          Row(
            children: [
              GestureDetector(
                onTap: url != null
                    ? () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => PdfViewerPage(pdfUrl: url),
                          ),
                        );
                      }
                    : null,
                child: Text(
                  url != null ? 'VIEW' : 'NOT UPLOADED',
                  style: TextStyle(
                    fontSize: 14,
                    color: url != null ? Colors.white : Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 5),
              Icon(icon,
                  color: url != null ? Colors.white : Colors.white, size: 20),
            ],
          ),
        ],
      ),
    );
  }
}
