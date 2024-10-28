import 'package:ctp/firebase_options.dart';
import 'package:ctp/pages/add_profile_photo.dart';
import 'package:ctp/pages/add_profile_photo_admin_page.dart';
import 'package:ctp/pages/add_profile_photo_transporter.dart';
import 'package:ctp/pages/admin_home_page.dart';
import 'package:ctp/pages/dealer_reg.dart';
import 'package:ctp/pages/first_name_page.dart';
import 'package:ctp/pages/home_page.dart';
import 'package:ctp/pages/house_rules_page.dart';
import 'package:ctp/pages/inspectionPages/inspection_details_page.dart';
import 'package:ctp/pages/login.dart';
import 'package:ctp/pages/offersPage.dart';
import 'package:ctp/pages/otp_page.dart';
import 'package:ctp/pages/pending_offers_page.dart';
import 'package:ctp/pages/phone_number_page.dart';
import 'package:ctp/pages/prefered_brands.dart';
import 'package:ctp/pages/profile_page.dart';
import 'package:ctp/pages/sign_in_page.dart';
import 'package:ctp/pages/signup_page.dart';
import 'package:ctp/pages/trading_category_page.dart';
import 'package:ctp/pages/trading_intrests_page.dart';
import 'package:ctp/pages/transporter_reg.dart';
import 'package:ctp/pages/truckForms/vehilce_upload_tabs.dart';
import 'package:ctp/pages/truck_page.dart';
import 'package:ctp/pages/tutorial_page.dart';
import 'package:ctp/pages/tutorial_started.dart';
import 'package:ctp/pages/waiting_for_approval.dart';
import 'package:ctp/providers/complaints_provider.dart';
import 'package:ctp/providers/form_data_provider.dart';
import 'package:ctp/providers/offer_provider.dart';
import 'package:ctp/providers/user_provider.dart';
import 'package:ctp/providers/vehicles_provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print('Handling a background message: ${message.messageId}');
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  // Enable Crashlytics for Flutter framework errors
  FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterError;

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => UserProvider()),
        ChangeNotifierProvider(create: (context) => VehicleProvider()),
        ChangeNotifierProvider(create: (context) => OfferProvider()),
        ChangeNotifierProvider(create: (context) => ComplaintsProvider()),
        ChangeNotifierProvider(create: (context) => FormDataProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Commercial Trader Portal',
      theme: ThemeData(
        useMaterial3: true,
      ),
      home: const AuthWrapper(),
      routes: {
        '/login': (context) => const LoginPage(),
        '/signup': (context) => const SignUpPage(),
        '/signin': (context) => const SignInPage(),
        '/home': (context) => const HomePage(),
        '/phoneNumber': (context) => const PhoneNumberPage(),
        '/otp': (context) => const OTPScreen(),
        '/firstName': (context) => const FirstNamePage(),
        '/tradingCategory': (context) => const TradingCategoryPage(),
        '/addProfilePhoto': (context) => const AddProfilePhotoPage(),
        '/addProfilePhotoTransporter': (context) =>
            const AddProfilePhotoPageTransporter(),
        '/transporterRegister': (context) =>
            const TransporterRegistrationPage(),
        '/dealerRegister': (context) => const DealerRegPage(),
        '/houseRules': (context) => const HouseRulesPage(),
        '/preferedBrands': (context) => const PreferredBrandsPage(),
        '/tradingInterests': (context) => const TradingInterestsPage(),
        '/tutorial': (context) => const TutorialPage(),
        '/tutorialStarted': (context) => const TutorialStartedPage(),
        '/pendingOffers': (context) => const PendingOffersPage(),
        '/truckPage': (context) => const TruckPage(),
        '/offers': (context) => const OffersPage(),
        '/profile': (context) => const ProfilePage(),
        '/waiting-for-approval': (context) => const WaitingForApprovalPage(),
        '/add-profile-photo-admin': (context) => AddProfilePhotoAdminPage(),
        '/admin-home': (context) => AdminHomePage(),
        '/vehicleUpload': (context) => VehicleUploadTabs(),
      },
      onGenerateRoute: (settings) {
        if (settings.name == '/inspectionDetails') {
          final args = settings.arguments as Map<String, dynamic>;
          return MaterialPageRoute(
            builder: (context) => InspectionDetailsPage(
              offerId: args['offerId'] as String,
              makeModel: args['makeModel'] as String,
              offerAmount: args['offerAmount'] as String,
              vehicleId: args['vehicleId'] as String,
            ),
          );
        }
        // Handle other routes if necessary
        return null;
      },
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final complaintsProvider =
        Provider.of<ComplaintsProvider>(context, listen: false);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      userProvider.fetchUserData();
      complaintsProvider.fetchAllComplaints();
    });

    User? firebaseUser = FirebaseAuth.instance.currentUser;

    if (firebaseUser != null && !firebaseUser.isAnonymous) {
      if (userProvider.getAccountStatus == 'suspended') {
        return const WaitingForApprovalPage();
      }
      return const HomePage();
    } else {
      return const LoginPage();
    }
  }

  Widget _navigateToHome(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const HomePage()),
        (route) => false,
      );
    });
    return Container();
  }
}
