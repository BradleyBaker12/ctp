import 'package:ctp/adminScreens/admin_fleets_page.dart';
import 'package:ctp/firebase_options.dart';
import 'package:ctp/pages/accepted_offers.dart';
import 'package:ctp/pages/add_profile_photo.dart';
import 'package:ctp/pages/add_profile_photo_admin_page.dart';
import 'package:ctp/pages/add_profile_photo_transporter.dart';
import 'package:ctp/pages/admin_home_page.dart';
import 'package:ctp/adminScreens/notification_test_page.dart';
import 'package:ctp/pages/bulk_offer_page.dart';
import 'package:ctp/pages/dealer_reg.dart';
import 'package:ctp/pages/editTruckForms/basic_information_edit.dart';
import 'package:ctp/pages/editTruckForms/chassis_edit_page.dart';
import 'package:ctp/pages/editTruckForms/drive_train_edit_page.dart';
import 'package:ctp/pages/editTruckForms/external_cab_edit_page.dart';
import 'package:ctp/pages/editTruckForms/internal_cab_edit_page.dart';
import 'package:ctp/pages/editTruckForms/maintenance_edit_section.dart';
import 'package:ctp/pages/editTruckForms/tyres_edit_page.dart';
import 'package:ctp/pages/error_page.dart';
import 'package:ctp/pages/first_name_page.dart';
import 'package:ctp/pages/home_page.dart';
import 'package:ctp/pages/house_rules_page.dart';
import 'package:ctp/pages/individual_offer_page.dart';
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
import 'package:ctp/pages/truckForms/vehilce_upload_screen.dart';
import 'package:ctp/pages/truck_page.dart';
import 'package:ctp/pages/tutorial_page.dart';
import 'package:ctp/pages/tutorial_started.dart';
import 'package:ctp/pages/vehicles_list.dart';
import 'package:ctp/pages/waiting_for_approval.dart';
import 'package:ctp/pages/wish_list_page.dart';
import 'package:ctp/providers/complaints_provider.dart';
import 'package:ctp/providers/form_data_provider.dart';
import 'package:ctp/providers/offer_provider.dart';
import 'package:ctp/providers/trailer_provider.dart';
import 'package:ctp/providers/user_provider.dart';
import 'package:ctp/providers/vehicles_provider.dart';
import 'package:ctp/providers/truck_conditions_provider.dart';
import 'package:ctp/providers/trailer_form_provider.dart';
import 'package:ctp/services/notification_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ctp/models/vehicle.dart';
import 'package:ctp/pages/vehicle_details_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:provider/provider.dart';
import 'services/auth_service.dart';
import 'package:url_strategy/url_strategy.dart';

// This needs to be a top-level function for background messaging
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Need to initialize Firebase for background handling
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  print('Handling a background message: ${message.messageId}');
  print('Background message data: ${message.data}');
}

// Global notification channel for Android
const AndroidNotificationChannel channel = AndroidNotificationChannel(
  'ctp_app_channel', // id
  'CTP Notifications', // title
  description: 'Commercial Trader Portal notifications', // description
  importance: Importance.high,
);

// Global FlutterLocalNotificationsPlugin for showing messages when in foreground
final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  setPathUrlStrategy();

  // Initialize Firebase only once in main()
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Setup notifications service
  await setupNotifications();

  // Comment out App Check activation as it's causing permission issues
  // await FirebaseAppCheck.instance.activate();

  // For web, ensure user session persistence is local.
  if (kIsWeb) {
    await FirebaseAuth.instance.setPersistence(Persistence.LOCAL);
  }

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => VehicleProvider()),
        ChangeNotifierProvider(create: (_) => UserProvider()),
        ChangeNotifierProvider(create: (_) => TrailerProvider()),
        ChangeNotifierProvider(create: (_) => UserProvider()),
        ChangeNotifierProxyProvider<UserProvider, VehicleProvider>(
          create: (_) => VehicleProvider(),
          update: (_, userProvider, vehicleProvider) {
            vehicleProvider?.initialize(userProvider);
            return vehicleProvider!;
          },
        ),
        ChangeNotifierProvider(create: (_) => OfferProvider()),
        ChangeNotifierProvider(create: (_) => ComplaintsProvider()),
        ChangeNotifierProvider(create: (_) => FormDataProvider()),
        ChangeNotifierProxyProvider<FormDataProvider, TruckConditionsProvider>(
          create: (_) => TruckConditionsProvider(''),
          update: (_, formData, __) =>
              TruckConditionsProvider(formData.vehicleId ?? ''),
        ),
        ChangeNotifierProvider(create: (_) => TrailerFormProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

// Setup notifications, handles permissions and topic subscriptions
Future<void> setupNotifications() async {
  if (kIsWeb) {
    // Web FCM setup
    print('DEBUG: Starting web notification setup');
    FirebaseMessaging messaging = FirebaseMessaging.instance;

    // Request permission
    NotificationSettings settings = await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );
    print('DEBUG: Web permission status - ${settings.authorizationStatus}');

    // Get Web FCM token using VAPID key
    const vapidKey = String.fromEnvironment('WEB_VAPID_KEY');
    String? webToken = await messaging.getToken(vapidKey: vapidKey);
    print('DEBUG: Web FCM Token: $webToken');

    // Handle foreground messages
    FirebaseMessaging.onMessage.listen((RemoteMessage msg) {
      print(
          'DEBUG: Web onMessage - ${msg.notification?.title}: ${msg.notification?.body}');
    });
    return;
  }

  try {
    print('DEBUG: Starting notification setup');

    // Initialize background handler
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // Initialize local notifications
    final initSettings = InitializationSettings(
      android: AndroidInitializationSettings('@drawable/ic_notification'),
      iOS: DarwinInitializationSettings(),
    );
    await flutterLocalNotificationsPlugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (details) {
        print('Notification clicked: ${details.payload}');
      },
    );
    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    // Request permission
    FirebaseMessaging messaging = FirebaseMessaging.instance;
    NotificationSettings settings = await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    print('DEBUG: Permission request result - ${settings.authorizationStatus}');

    // Get FCM token
    String? token = await messaging.getToken();
    print('DEBUG: FCM Token: $token');

    // Subscribe to topic
    await messaging.subscribeToTopic('admins');
    print('DEBUG: Subscribed to "admins" topic');

    // Foreground message handler
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print(
          'DEBUG: Foreground message received: ${message.notification?.title}');
      RemoteNotification? notification = message.notification;
      AndroidNotification? android = notification?.android;
      if (notification != null && android != null) {
        flutterLocalNotificationsPlugin.show(
          notification.hashCode,
          notification.title,
          notification.body,
          NotificationDetails(
            android: AndroidNotificationDetails(
              channel.id,
              channel.name,
              channelDescription: channel.description,
              icon: android.smallIcon ?? '@drawable/ic_notification',
            ),
            iOS: DarwinNotificationDetails(),
          ),
          payload: message.data.toString(),
        );
      }
    });

    // Notification tap handler
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print('DEBUG: Notification opened: ${message.data}');
    });

    // Initialize notification service
    await NotificationService.initialize();
    print('DEBUG: NotificationService initialized');
  } catch (e, stackTrace) {
    print('ERROR setting up notifications: $e');
    print('Stack trace: $stackTrace');
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => TrailerProvider()),
        ChangeNotifierProvider(create: (_) => UserProvider()),
        ChangeNotifierProxyProvider<UserProvider, VehicleProvider>(
          create: (_) => VehicleProvider(),
          update: (_, userProvider, vehicleProvider) {
            vehicleProvider?.initialize(userProvider);
            return vehicleProvider!;
          },
        ),
        ChangeNotifierProvider(create: (_) => OfferProvider()),
        ChangeNotifierProvider(create: (_) => ComplaintsProvider()),
        ChangeNotifierProvider(create: (_) => FormDataProvider()),
        ChangeNotifierProxyProvider<FormDataProvider, TruckConditionsProvider>(
          create: (_) => TruckConditionsProvider(''),
          update: (_, formData, __) =>
              TruckConditionsProvider(formData.vehicleId ?? ''),
        ),
        ChangeNotifierProvider(create: (_) => TrailerFormProvider()),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Commercial Trader Portal',
        theme: ThemeData(
          useMaterial3: true,
        ),
        home: const AppInitializer(),
        routes: {
          '/login': (context) => const LoginPage(),
          '/signup': (context) => const SignUpPage(),
          '/signin': (context) => const SignInPage(),
          '/home': (context) => const HomePage(),
          '/phoneNumber': (context) => const PhoneNumberPage(),
          '/otp': (context) => const OTPScreen(),
          '/firstNamePage': (context) => const FirstNamePage(),
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
          '/profile': (context) => ProfilePage(),
          '/waiting-for-approval': (context) => const AccountStatusPage(),
          '/add-profile-photo-admin': (context) => AddProfilePhotoAdminPage(),
          '/admin-home': (context) => AdminHomePage(),
          '/adminUsers': (context) => const AdminHomePage(initialTab: 0),
          '/adminOffers': (context) => const AdminHomePage(initialTab: 1),
          '/adminComplaints': (context) => const AdminHomePage(initialTab: 2),
          '/adminVehicles': (context) => const AdminHomePage(initialTab: 3),
          '/adminNotificationTest': (context) => const NotificationTestPage(),
          '/vehicleUpload': (context) => const VehicleUploadScreen(),
          '/in-progress': (context) => const AcceptedOffersPage(),
          '/transporterList': (context) => const VehiclesListPage(),
          '/adminFleets': (context) => const AdminFleetsPage(),
          '/wishlist': (context) => const WishlistPage(),
          '/adminHome': (context) => const AdminHomePage(),
          '/error': (context) => ErrorPage(),
          '/waitingApproval': (context) => AccountStatusPage(),
          '/bulkOffer': (context) => BulkOfferPage(),
          '/individualOffer': (context) => IndividualOfferPage(),
          '/basic_information': (context) => BasicInformationEdit(),
          '/maintenance_warranty': (context) {
            final vehicleId =
                ModalRoute.of(context)!.settings.arguments as String;
            return MaintenanceEditSection(
              vehicleId: vehicleId,
              isUploading: false,
              onMaintenanceFileSelected: (file) {},
              onWarrantyFileSelected: (file) {},
              oemInspectionType: '',
              oemInspectionExplanation: '',
              onProgressUpdate: () {},
              maintenanceSelection: '',
              warrantySelection: '',
              isFromAdmin: false,
              isFromTransporter: true,
            );
          },
          '/external_cab': (context) {
            final vehicleId =
                ModalRoute.of(context)!.settings.arguments as String;
            return ExternalCabEditPage(
              vehicleId: vehicleId,
              onProgressUpdate: () {},
              inTabsPage: false,
            );
          },
          '/internal_cab': (context) {
            final vehicleId =
                ModalRoute.of(context)!.settings.arguments as String;
            return InternalCabEditPage(
              vehicleId: vehicleId,
              onProgressUpdate: () {},
              inTabsPage: false,
            );
          },
          '/chassis': (context) {
            final vehicleId =
                ModalRoute.of(context)!.settings.arguments as String;
            return ChassisEditPage(
              vehicleId: vehicleId,
              onProgressUpdate: () {},
              inTabsPage: false,
            );
          },
          '/drive_train': (context) {
            final vehicleId =
                ModalRoute.of(context)!.settings.arguments as String;
            return DriveTrainEditPage(
              vehicleId: vehicleId,
              onProgressUpdate: () {},
              inTabsPage: false,
            );
          },
          '/tyres': (context) {
            final vehicleId =
                ModalRoute.of(context)!.settings.arguments as String;
            return TyresEditPage(
              vehicleId: vehicleId,
              onProgressUpdate: () {},
              inTabsPage: false,
            );
          },
        },
        onGenerateRoute: (settings) {
          // Handle deep link: /vehicle/:vehicleId
          if (settings.name != null && settings.name!.startsWith('/vehicle/')) {
            final uri = Uri.parse(settings.name!);
            final vehicleId =
                uri.pathSegments.length > 1 ? uri.pathSegments[1] : null;
            if (vehicleId != null && vehicleId.isNotEmpty) {
              return MaterialPageRoute(
                builder: (context) => FutureBuilder<DocumentSnapshot>(
                  future: FirebaseFirestore.instance
                      .collection('vehicles')
                      .doc(vehicleId)
                      .get(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Scaffold(
                        body: Center(child: CircularProgressIndicator()),
                      );
                    }
                    if (!snapshot.hasData || !snapshot.data!.exists) {
                      return const ErrorPage();
                    }
                    final vehicle = Vehicle.fromDocument(snapshot.data!);
                    return VehicleDetailsPage(vehicle: vehicle);
                  },
                ),
              );
            }
          }
          if (settings.name == '/inspectionDetails') {
            final args = settings.arguments as Map<String, dynamic>;
            return MaterialPageRoute(
              builder: (context) => InspectionDetailsPage(
                offerId: args['offerId'] as String,
                offerAmount: args['offerAmount'] as String,
                vehicleId: args['vehicleId'] as String,
                brand: args['brands'] as String,
                variant: args['variant'] as String,
              ),
            );
          }
          return null;
        },
        onUnknownRoute: (settings) {
          return MaterialPageRoute(
            builder: (context) => const AuthWrapper(),
          );
        },
      ),
    );
  }
}

class AppInitializer extends StatefulWidget {
  const AppInitializer({super.key});
  @override
  State<AppInitializer> createState() => _AppInitializerState();
}

class _AppInitializerState extends State<AppInitializer> {
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  // Updated _initializeApp() without reinitializing Firebase
  Future<void> _initializeApp() async {
    try {
      // Setup messaging and crashlytics for mobile only
      if (!kIsWeb) {
        FirebaseMessaging.onBackgroundMessage(
            _firebaseMessagingBackgroundHandler);
        // FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterError;
      }
      // Setup auth token refresh
      final authService = AuthService();
      await authService.setupTokenRefresh();
      setState(() {
        _initialized = true;
      });
    } catch (e) {
      await Future.delayed(const Duration(seconds: 2));
      _initializeApp();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_initialized) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    return const AuthWrapper();
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  Future<bool> _verifyAccount(BuildContext context) async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final complaintsProvider =
        Provider.of<ComplaintsProvider>(context, listen: false);
    await Future.wait([
      userProvider.fetchUserData(),
      userProvider.initializeStatusListener(),
      complaintsProvider.fetchAllComplaints(),
    ]);
    if (['admin', 'sales representative']
        .contains(userProvider.getUserRole.toLowerCase())) {
      return true;
    }
    return userProvider.getAccountStatus != 'not_found';
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, authSnapshot) {
        if (authSnapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        final firebaseUser = authSnapshot.data;
        if (firebaseUser == null || firebaseUser.isAnonymous) {
          return const LoginPage();
        }
        return FutureBuilder<bool>(
          future: _verifyAccount(context),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }
            if (snapshot.hasError) {
              return const ErrorPage();
            }
            if (snapshot.data == false) {
              // Allow admins and sales representatives to proceed even if status check failed
              final userProviderSilent =
                  Provider.of<UserProvider>(context, listen: false);
              final role = userProviderSilent.getUserRole.toLowerCase();
              if (role == 'admin' ||
                  role == 'sales representative' ||
                  role == 'sales rep') {
                return const AdminHomePage();
              }
              return const ErrorPage();
            }
            final userProvider = Provider.of<UserProvider>(context);
            if (userProvider.getAccountStatus == 'suspended' ||
                userProvider.getAccountStatus == 'inactive') {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (ModalRoute.of(context)?.settings.name !=
                    '/account-status') {
                  Navigator.of(context).pushReplacementNamed('/account-status');
                }
              });
              return const AccountStatusPage();
            }
            if (userProvider.getUserRole.toLowerCase() == 'admin' ||
                userProvider.getUserRole.toLowerCase() == 'sales rep') {
              return const AdminHomePage();
            } else {
              return const HomePage();
            }
          },
        );
      },
    );
  }
}

Map<String, WidgetBuilder> routes = {
  '/external_cab': (context) {
    final vehicleId = ModalRoute.of(context)!.settings.arguments as String;
    return ExternalCabEditPage(
      vehicleId: vehicleId,
      onProgressUpdate: () {},
      inTabsPage: false,
    );
  },
  '/internal_cab': (context) {
    final vehicleId = ModalRoute.of(context)!.settings.arguments as String;
    return InternalCabEditPage(
      vehicleId: vehicleId,
      onProgressUpdate: () {},
      inTabsPage: false,
    );
  },
  '/chassis': (context) {
    final vehicleId = ModalRoute.of(context)!.settings.arguments as String;
    return ChassisEditPage(
      vehicleId: vehicleId,
      onProgressUpdate: () {},
      inTabsPage: false,
    );
  },
  '/drive_train': (context) {
    final vehicleId = ModalRoute.of(context)!.settings.arguments as String;
    return DriveTrainEditPage(
      vehicleId: vehicleId,
      onProgressUpdate: () {},
      inTabsPage: false,
    );
  },
  '/tyres': (context) {
    final vehicleId = ModalRoute.of(context)!.settings.arguments as String;
    return TyresEditPage(
      vehicleId: vehicleId,
      onProgressUpdate: () {},
      inTabsPage: false,
    );
  },
};
