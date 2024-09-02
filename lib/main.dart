import 'package:ctp/firebase_options.dart';
import 'package:ctp/pages/add_profile_photo.dart';
import 'package:ctp/pages/add_profile_photo_transporter.dart';
import 'package:ctp/pages/dealer_reg.dart';
import 'package:ctp/pages/first_name_page.dart';
import 'package:ctp/pages/home_page.dart';
import 'package:ctp/pages/house_rules_page.dart';
import 'package:ctp/pages/inspectionPages/inspection_details_page.dart';
import 'package:ctp/pages/login.dart';
import 'package:ctp/pages/otp_page.dart';
import 'package:ctp/pages/pending_offers_page.dart';
import 'package:ctp/pages/phone_number_page.dart';
import 'package:ctp/pages/prefered_brands.dart';
import 'package:ctp/pages/sign_in_page.dart';
import 'package:ctp/pages/signup_page.dart';
import 'package:ctp/pages/trading_category_page.dart';
import 'package:ctp/pages/trading_intrests_page.dart';
import 'package:ctp/pages/transporter_reg.dart';
import 'package:ctp/pages/truckForms/vehcileUpload_form1.dart';
import 'package:ctp/pages/truckForms/vehcileUpload_form2.dart';
import 'package:ctp/pages/truckForms/vehcileUpload_form3.dart';
import 'package:ctp/pages/truckForms/vehcileUpload_form4.dart';
import 'package:ctp/pages/truckForms/vehcileUpload_form5.dart';
import 'package:ctp/pages/truckForms/vehcileUpload_form6.dart';
import 'package:ctp/pages/truckForms/vehcileUpload_form7.dart';
import 'package:ctp/pages/truckForms/vehcileUpload_form8.dart';
import 'package:ctp/pages/truck_page.dart';
import 'package:ctp/pages/tutorial_page.dart';
import 'package:ctp/pages/tutorial_started.dart';
import 'package:ctp/providers/complaints_provider.dart';
import 'package:ctp/providers/offer_provider.dart';
import 'package:ctp/providers/user_provider.dart';
import 'package:ctp/providers/vehicles_provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Enable Crashlytics for Flutter framework errors
  FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterError;

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => UserProvider()),
        ChangeNotifierProvider(create: (context) => VehicleProvider()),
        ChangeNotifierProvider(create: (context) => OfferProvider()),
        ChangeNotifierProvider(create: (context) => ComplaintsProvider()),
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
        '/firstTruckForm': (context) =>
            const FirstTruckForm(vehicleType: 'truck'),
        '/secondTruckForm': (context) => const SecondFormPage(),
        '/thirdTruckForm': (context) => const ThirdFormPage(),
        '/fourthTruckForm': (context) => const FourthFormPage(),
        '/fifthTruckForm': (context) => const FifthFormPage(),
        '/sixthTruckForm': (context) => const SixthFormPage(),
        '/seventhTruckForm': (context) => const SeventhFormPage(),
        '/eighthTruckForm': (context) => const EighthFormPage(),
        '/pendingOffers': (context) => const PendingOffersPage(),
        '/truckPage': (context) => const TruckPage(),
      },
      onGenerateRoute: (settings) {
        if (settings.name == '/inspectionDetails') {
          final args = settings.arguments as Map<String, dynamic>;
          return MaterialPageRoute(
            builder: (context) => InspectionDetailsPage(
              offerId: args['offerId'] as String,
              makeModel: args['makeModel'] as String,
              offerAmount: args['offerAmount'] as String,
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
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasData) {
          return _navigateToHome(
              context); // Navigate to HomePage with removal of previous screens
        } else {
          return const LoginPage();
        }
      },
    );
  }

  // Function to navigate to HomePage and remove previous routes
  Widget _navigateToHome(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const HomePage()),
        (route) => false, // This removes all previous routes
      );
    });
    return Container(); // Return an empty container as a placeholder
  }
}
