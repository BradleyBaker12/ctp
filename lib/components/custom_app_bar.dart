import 'package:flutter/material.dart';
import 'dart:ui'; // Required for the AppBar's blur effect
import 'package:provider/provider.dart';
import 'package:ctp/providers/user_provider.dart';
import 'package:ctp/pages/profile_page.dart'; // Import the ProfilePage
import 'package:ctp/components/custom_back_button.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final double height;

  const CustomAppBar({super.key, this.height = 70.0});

  @override
  Widget build(BuildContext context) {
    final canPop = Navigator.of(context).canPop();
    return PreferredSize(
      preferredSize: Size.fromHeight(height), // Set desired height
      child: AppBar(
        automaticallyImplyLeading:
            false, // We'll handle the back button manually
        leadingWidth: canPop ? 56 : null,
        leading: canPop
            ? Padding(
                padding: const EdgeInsets.only(left: 8.0),
                child: Center(
                  child: SizedBox(
                    width: 32,
                    height: 32,
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        customBorder: const CircleBorder(),
                        onTap: () => Navigator.of(context).maybePop(),
                        child: const Center(child: CustomBackButton()),
                      ),
                    ),
                  ),
                ),
              )
            : null,
        backgroundColor: Colors.transparent,
        elevation: 0,
        flexibleSpace: ClipRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
            child: Container(
              color: Colors.grey.withValues(alpha: 0.1),
            ),
          ),
        ),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Padding(
              padding: EdgeInsets.only(
                  left: canPop
                      ? 8.0
                      : 35.0), // Space on the left (reduced when back button is present)
              child: Image.asset(
                'lib/assets/CTPLogo.png',
                width: 60,
                height: 60,
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(right: 25.0), // Space on the right
              child: Consumer<UserProvider>(
                builder: (context, userProvider, _) {
                  final profileImageUrl = userProvider.getProfileImageUrl;
                  final hasNotifications = userProvider
                      .hasNotifications; // Assuming you have a boolean flag for notifications

                  return GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ProfilePage(),
                        ),
                      );
                    },
                    child: Stack(
                      children: [
                        CircleAvatar(
                          radius: 26,
                          backgroundColor: Colors.grey[200],
                          backgroundImage: profileImageUrl.isNotEmpty
                              ? NetworkImage(profileImageUrl)
                              : const AssetImage(
                                      'lib/assets/default-profile-photo.jpg')
                                  as ImageProvider,
                          onBackgroundImageError: (exception, stackTrace) {
                            // Log the error
                            debugPrint(
                                'Error loading profile image: $exception');
                          },
                          child: (profileImageUrl.isEmpty)
                              ? const Icon(Icons.person,
                                  size: 26, color: Colors.grey)
                              : null,
                        ),
                        // Conditionally show the red dot if there are notifications
                        if (hasNotifications)
                          Positioned(
                            top: 0,
                            right: 0,
                            child: Container(
                              width: 10,
                              height: 10,
                              decoration: BoxDecoration(
                                color: Colors.red,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Size get preferredSize => Size.fromHeight(height);
}
