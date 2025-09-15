import 'package:flutter/material.dart';
import 'dart:ui'; // Required for the AppBar's blur effect
import 'package:provider/provider.dart';
import 'package:ctp/providers/user_provider.dart';
import 'package:ctp/pages/profile_page.dart'; // Import the ProfilePage
import 'package:ctp/components/custom_back_button.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final double height;
  final bool showBackButton;

  const CustomAppBar({super.key, this.height = 70.0, this.showBackButton = true});

  @override
  Widget build(BuildContext context) {
    final canPop = Navigator.of(context).canPop();
    final showLeading = showBackButton && canPop;
    return PreferredSize(
      preferredSize: Size.fromHeight(height),
      child: AppBar(
        automaticallyImplyLeading: false,
        leadingWidth: showLeading ? 56 : null,
        leading: showLeading
            ? Padding(
                padding: const EdgeInsets.only(left: 8.0),
                child: Center(
                  child: SizedBox(
                    width: 32,
                    height: 32,
                    child: const Center(
                      child: CustomBackButton(),
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
              color: Colors.transparent, // Remove overlay color
            ),
          ),
        ),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Padding(
              padding: EdgeInsets.only(left: showLeading ? 8.0 : 35.0),
              child: Image.asset(
                'lib/assets/CTPLogo.png',
                width: 60,
                height: 60,
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(right: 25.0),
              child: Consumer<UserProvider>(
                builder: (context, userProvider, _) {
                  final profileImageUrl = userProvider.getProfileImageUrl;
                  final hasNotifications = userProvider.hasNotifications;
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
                            debugPrint(
                                'Error loading profile image: $exception');
                          },
                          child: (profileImageUrl.isEmpty)
                              ? const Icon(Icons.person,
                                  size: 26, color: Colors.grey)
                              : null,
                        ),
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
