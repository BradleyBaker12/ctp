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
import 'package:ctp/pages/deep_link_test_vehicle_page.dart';
import 'package:ctp/pages/deep_link_test_offer_page.dart';
import 'package:ctp/pages/deep_link_vehicle_test_page.dart';
import 'package:ctp/pages/transport_offer_details_page.dart';
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
import 'package:ctp/pages/setup_collection.dart';
import 'package:ctp/pages/collectionPages/collection_details_page.dart';
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

// Global navigation key for deep linking
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

// Handle notification data from FCM
void _handleNotificationTap(Map<String, dynamic> data) {
  print('DEBUG: Handling notification tap with data: $data');

  final context = navigatorKey.currentContext;
  if (context == null) {
    print('DEBUG: Navigator context not available, storing for later');
    // Store the navigation data for when the app becomes available
    _pendingNotificationData = data;
    return;
  }

  _navigateBasedOnNotification(context, data);
}

// Handle notification payload from local notifications
void _handleNotificationPayload(String payload) {
  print('DEBUG: Handling notification payload: $payload');

  final context = navigatorKey.currentContext;
  if (context == null) {
    print('DEBUG: Navigator context not available for payload');
    return;
  }

  // Try to parse the payload
  try {
    // Remove outer braces and parse key-value pairs
    String cleanPayload = payload.replaceAll(RegExp(r'^{|}$'), '');
    Map<String, dynamic> data = {};

    // Split by commas and parse each key-value pair
    for (String pair in cleanPayload.split(', ')) {
      List<String> keyValue = pair.split(': ');
      if (keyValue.length == 2) {
        String key = keyValue[0].trim();
        String value = keyValue[1].trim();
        // Remove null values
        if (value != 'null') {
          data[key] = value;
        }
      }
    }

    _navigateBasedOnNotification(context, data);
  } catch (e) {
    print('DEBUG: Could not parse payload: $e');
    // Fallback to home page
    Navigator.of(context).pushNamedAndRemoveUntil('/home', (route) => false);
  }
}

// Navigate based on notification type and data
void _navigateBasedOnNotification(
    BuildContext context, Map<String, dynamic> data) {
  final notificationType = data['notificationType']?.toString();
  final vehicleId = data['vehicleId']?.toString();
  final offerId = data['offerId']?.toString();

  print('DEBUG: ===== DEEP LINKING NAVIGATION =====');
  print('DEBUG: Full notification data: $data');
  print(
      'DEBUG: Navigation data - Type: $notificationType, VehicleId: $vehicleId, OfferId: $offerId');
  print('DEBUG: =====================================');

  try {
    switch (notificationType) {
      // Offer-related notifications
      case 'new_offer':
      case 'offer_response':
      case 'offer_accepted_admin':
      case 'offer_status_change':
        if (offerId != null) {
          _navigateToOfferDetails(
              context, offerId, vehicleId, notificationType);
        } else if (vehicleId != null) {
          _navigateToVehicle(context, vehicleId, notificationType);
        } else {
          Navigator.of(context).pushNamed('/offers');
        }
        break;

      // Vehicle-related notifications
      case 'new_vehicle':
      case 'live_vehicle_update':
      case 'vehicle_pending_approval':
        if (vehicleId != null) {
          _navigateToVehicle(context, vehicleId, notificationType);
        } else {
          Navigator.of(context).pushNamed('/transporterList');
        }
        break;

      // Inspection-related notifications
      case 'inspection_booked':
      case 'inspection_booked_confirmation':
      case 'inspection_booked_admin':
      case 'inspection_today_dealer':
      case 'inspection_today_transporter':
      case 'inspection_results_uploaded':
      case 'inspection_results_uploaded_confirmation':
      case 'inspection_results_uploaded_admin':
        if (offerId != null) {
          _navigateToOfferDetails(
              context, offerId, vehicleId, notificationType);
        } else {
          Navigator.of(context).pushNamed('/offers');
        }
        break;

      // Collection-related notifications
      case 'collection_booked':
      case 'collection_booked_confirmation':
      case 'collection_booked_admin':
      case 'collection_confirmed':
      case 'truck_ready_for_collection':
      case 'truck_ready_for_collection_admin':
      case 'vehicle_collected':
        if (offerId != null) {
          _navigateToOfferDetails(
              context, offerId, vehicleId, notificationType);
        } else {
          Navigator.of(context).pushNamed('/offers');
        }
        break;
      // New: collection setup flow
      case 'collection_setup_needed':
        if (offerId != null) {
          _navigateToCollectionSetup(context, offerId);
        } else {
          Navigator.of(context).pushNamed('/offers');
        }
        break;
      case 'collection_setup_ready':
        if (offerId != null) {
          _navigateToCollectionSelection(context, offerId);
        } else {
          Navigator.of(context).pushNamed('/offers');
        }
        break;

      // Sale completion and transaction notifications
      case 'sale_completion_transporter':
      case 'sale_completion_dealer':
      case 'transaction_completed':
        if (offerId != null) {
          _navigateToOfferDetails(
              context, offerId, vehicleId, notificationType);
        } else {
          Navigator.of(context).pushNamed('/offers');
        }
        break;

      // Payment and invoice-related notifications
      case 'invoice_payment_reminder':
      case 'invoice_payment_reminder_transporter':
      case 'invoice_payment_reminder_admin':
      case 'invoice_request':
      case 'proof_of_payment_uploaded':
        if (offerId != null) {
          _navigateToOfferDetails(
              context, offerId, vehicleId, notificationType);
        } else {
          Navigator.of(context).pushNamed('/offers');
        }
        break;

      // User registration notifications (for admins)
      case 'new_user_registration':
      case 'registration_completed':
        Navigator.of(context).pushNamed('/adminUsers');
        break;

      // Document reminder notifications
      case 'document_reminder':
        Navigator.of(context).pushNamed('/profile');
        break;

      default:
        print('DEBUG: Unknown notification type: $notificationType');
        // For unknown types, try to route based on available data
        if (offerId != null) {
          print('DEBUG: Unknown type but has offerId, navigating to offers');
          _navigateToOfferDetails(
              context, offerId, vehicleId, notificationType);
        } else if (vehicleId != null) {
          print('DEBUG: Unknown type but has vehicleId, navigating to vehicle');
          _navigateToVehicle(context, vehicleId, notificationType);
        } else {
          print('DEBUG: Unknown type and no data, fallback to offers page');
          Navigator.of(context).pushNamed('/offers');
        }
        break;
    }
  } catch (e) {
    print('DEBUG: Error during navigation: $e');
    print(
        'DEBUG: Original data - Type: $notificationType, VehicleId: $vehicleId, OfferId: $offerId');

    // Intelligent fallback based on available data
    if (offerId != null) {
      print('DEBUG: Fallback - Navigating to offers due to offerId presence');
      Navigator.of(context).pushNamed('/offers');
    } else if (vehicleId != null) {
      print(
          'DEBUG: Fallback - Navigating to vehicle list due to vehicleId presence');
      Navigator.of(context).pushNamed('/transporterList');
    } else {
      print('DEBUG: Fallback - Navigating to home page as last resort');
      Navigator.of(context).pushNamedAndRemoveUntil('/home', (route) => false);
    }
  }
}

// Navigate to vehicle details
void _navigateToVehicle(
    BuildContext context, String vehicleId, String? notificationType) {
  print('DEBUG: Navigating to vehicle: $vehicleId');

  // Check if this is a test vehicle ID
  if (vehicleId.startsWith('test_vehicle_')) {
    print('DEBUG: Detected test vehicle ID, navigating to test page');
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => DeepLinkTestVehiclePage(
          vehicleId: vehicleId,
        ),
      ),
    );
    return;
  }

  // Navigate to vehicle details page (handled by onGenerateRoute)
  print('DEBUG: Navigating to production vehicle page: /vehicle/$vehicleId');
  Navigator.of(context).pushNamed('/vehicle/$vehicleId');
}

// Navigate to offer details - determine the appropriate page based on user role
Future<void> _navigateToOfferDetails(BuildContext context, String offerId,
    String? vehicleId, String? notificationType) async {
  print('DEBUG: Navigating to offer: $offerId');

  // Check if this is a test offer ID
  if (offerId.startsWith('test_offer_')) {
    print('DEBUG: Detected test offer ID, navigating to test page');
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => DeepLinkTestOfferPage(
          offerId: offerId,
          vehicleId: vehicleId,
          notificationType: notificationType ?? 'new_offer',
        ),
      ),
    );
    return;
  }

  try {
    // Get offer details from Firestore to determine navigation
    final offerDoc = await FirebaseFirestore.instance
        .collection('offers')
        .doc(offerId)
        .get();

    if (!offerDoc.exists) {
      print('DEBUG: Offer not found: $offerId, navigating to offers page');
      Navigator.of(context).pushNamed('/offers');
      return;
    }

    final offerData = offerDoc.data()!;
    final currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser == null) {
      print('DEBUG: No authenticated user');
      Navigator.of(context).pushNamed('/login');
      return;
    }

    print('DEBUG: Current user ID: ${currentUser.uid}');
    print('DEBUG: Offer dealer ID: ${offerData['dealerId']}');
    print('DEBUG: Notification type: $notificationType');

    // Get vehicle details if vehicleId is provided
    if (vehicleId != null) {
      final vehicleDoc = await FirebaseFirestore.instance
          .collection('vehicles')
          .doc(vehicleId)
          .get();

      if (vehicleDoc.exists) {
        final vehicleData = vehicleDoc.data()!;
        final isTransporter = vehicleData['userId'] == currentUser.uid;
        final isDealer = offerData['dealerId'] == currentUser.uid;

        print(
            'DEBUG: User role - isTransporter: $isTransporter, isDealer: $isDealer');
        print('DEBUG: Vehicle owner ID: ${vehicleData['userId']}');

        if (isTransporter) {
          // Navigate to transporter specific offer details page
          try {
            final vehicle = Vehicle.fromDocument(vehicleDoc);
            final offer = Offer.fromFirestore(offerDoc);

            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => TransporterOfferDetailsPage(
                  offer: offer,
                  vehicle: vehicle,
                ),
              ),
            );
            return;
          } catch (e) {
            print('DEBUG: Error creating vehicle/offer objects: $e');
            // Fallback to offers page
            Navigator.of(context).pushNamed('/offers');
            return;
          }
        } else if (isDealer) {
          // For dealers, navigate to offers page where they can see their offers
          Navigator.of(context).pushNamed('/offers');
          return;
        } else {
          // Admin or other role - check user role from Firestore
          final userDoc = await FirebaseFirestore.instance
              .collection('users')
              .doc(currentUser.uid)
              .get();

          if (userDoc.exists) {
            final userData = userDoc.data()!;
            final userRole =
                userData['userRole']?.toString().toLowerCase() ?? '';

            if (userRole == 'admin' || userRole == 'sales representative') {
              // Navigate to admin offers page
              Navigator.of(context).pushNamed('/adminOffers');
              return;
            }
          }

          // Default to offers page
          Navigator.of(context).pushNamed('/offers');
          return;
        }
      } else {
        print('DEBUG: Vehicle not found: $vehicleId');
      }
    }

    // Fallback navigation based on user role when vehicle data is not available
    final userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(currentUser.uid)
        .get();

    if (userDoc.exists) {
      final userData = userDoc.data()!;
      final userRole = userData['userRole']?.toString().toLowerCase() ?? '';

      if (userRole == 'admin' || userRole == 'sales representative') {
        Navigator.of(context).pushNamed('/adminOffers');
      } else if (userRole == 'dealer') {
        Navigator.of(context).pushNamed('/offers');
      } else if (userRole == 'transporter') {
        Navigator.of(context).pushNamed('/offers');
      } else {
        Navigator.of(context).pushNamed('/offers');
      }
    } else {
      // Final fallback - navigate to offers page
      Navigator.of(context).pushNamed('/offers');
    }
  } catch (e) {
    print('DEBUG: Error navigating to offer details: $e');
    Navigator.of(context).pushNamed('/offers');
  }
}

// Navigate seller to setup collection availability
void _navigateToCollectionSetup(BuildContext context, String offerId) {
  Navigator.of(context).push(
    MaterialPageRoute(
      builder: (context) => SetupCollectionPage(offerId: offerId),
    ),
  );
}

// Navigate buyer to choose from provided collection options
void _navigateToCollectionSelection(BuildContext context, String offerId) {
  Navigator.of(context).push(
    MaterialPageRoute(
      builder: (context) => CollectionDetailsPage(offerId: offerId),
    ),
  );
}

// === Deep link helpers ===
bool _isAuthenticated() {
  try {
    return FirebaseAuth.instance.currentUser != null;
  } catch (_) {
    return false;
  }
}

Route<dynamic> _guarded(WidgetBuilder builder) {
  return MaterialPageRoute(builder: (context) {
    if (!_isAuthenticated()) {
      return const LoginPage();
    }
    return builder(context);
  });
}

// Store pending notification data when app context is not available
Map<String, dynamic>? _pendingNotificationData;

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
        if (details.payload != null) {
          _handleNotificationPayload(details.payload!);
        }
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
        // Include notification data in the payload for deep linking
        final payloadData = {
          'notificationType': message.data['notificationType'],
          'vehicleId': message.data['vehicleId'],
          'offerId': message.data['offerId'],
          'dealerId': message.data['dealerId'],
          'transporterId': message.data['transporterId'],
        };

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
          payload: payloadData.toString(),
        );
      }
    });

    // Notification tap handler
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print('DEBUG: Notification opened: ${message.data}');
      _handleNotificationTap(message.data);
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
        navigatorKey: navigatorKey, // Add navigation key for deep linking
        debugShowCheckedModeBanner: false,
        title: 'Commercial Trader Portal',
        theme: ThemeData(
          useMaterial3: true,
        ),
        // Don't use `home` so the initial browser URL deep link is honored.
        routes: {
          '/': (context) => const AppInitializer(),
          '/login': (context) => const LoginPage(),
          '/signup': (context) => const SignUpPage(),
          '/signin': (context) => const SignInPage(),
          // Route '/home' through the initializer so refreshes always land on the correct home
          '/home': (context) => const AppInitializer(),
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
          '/vehicleDeepLinkTest': (context) => const DeepLinkVehicleTestPage(),
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
          // Handle deep links for vehicle details in multiple URL shapes to be resilient:
          //  - /vehicle/:vehicleId
          //  - /vehicle?id=:vehicleId
          //  - /public/vehicle/:vehicleId
          //  - /v/:vehicleId
          if (settings.name != null) {
            final uri = Uri.parse(settings.name!);

            String? vehicleId;
            // /vehicle/:id
            if (uri.pathSegments.length >= 2 &&
                uri.pathSegments.first == 'vehicle') {
              vehicleId = uri.pathSegments[1];
            }
            // /vehicle?id=:id
            vehicleId ??= uri.pathSegments.length == 1 &&
                    uri.pathSegments.first == 'vehicle'
                ? (uri.queryParameters['id'] ??
                    uri.queryParameters['vehicleId'])
                : null;
            // /public/vehicle/:id
            if (vehicleId == null &&
                uri.pathSegments.length >= 3 &&
                uri.pathSegments[0] == 'public' &&
                uri.pathSegments[1] == 'vehicle') {
              vehicleId = uri.pathSegments[2];
            }
            // /v/:id (short form)
            if (vehicleId == null &&
                uri.pathSegments.length >= 2 &&
                uri.pathSegments.first == 'v') {
              vehicleId = uri.pathSegments[1];
            }

            if (vehicleId != null && vehicleId.isNotEmpty) {
              return _guarded((context) => FutureBuilder<DocumentSnapshot>(
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
                  ));
            }

            // Deep link: /basic_information/:vehicleId (existing block below kept for args)
            if (uri.pathSegments.length >= 2 &&
                uri.pathSegments.first == 'basic_information') {
              final id = uri.pathSegments[1];
              if (id.isNotEmpty) {
                return _guarded((context) => FutureBuilder<DocumentSnapshot>(
                      future: FirebaseFirestore.instance
                          .collection('vehicles')
                          .doc(id)
                          .get(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Scaffold(
                            body: Center(child: CircularProgressIndicator()),
                          );
                        }
                        if (!snapshot.hasData || !snapshot.data!.exists) {
                          return const ErrorPage();
                        }
                        final vehicle = Vehicle.fromDocument(snapshot.data!);
                        return BasicInformationEdit(vehicle: vehicle);
                      },
                    ));
              }
            }

            if (uri.pathSegments.isNotEmpty) {
              switch (uri.pathSegments.first) {
                case 'external_cab':
                  if (uri.pathSegments.length >= 2) {
                    final id = uri.pathSegments[1];
                    return _guarded((context) => ExternalCabEditPage(
                          vehicleId: id,
                          onProgressUpdate: () {},
                          inTabsPage: false,
                        ));
                  }
                  break;
                case 'internal_cab':
                  if (uri.pathSegments.length >= 2) {
                    final id = uri.pathSegments[1];
                    return _guarded((context) => InternalCabEditPage(
                          vehicleId: id,
                          onProgressUpdate: () {},
                          inTabsPage: false,
                        ));
                  }
                  break;
                case 'chassis':
                  if (uri.pathSegments.length >= 2) {
                    final id = uri.pathSegments[1];
                    return _guarded((context) => ChassisEditPage(
                          vehicleId: id,
                          onProgressUpdate: () {},
                          inTabsPage: false,
                        ));
                  }
                  break;
                case 'drive_train':
                  if (uri.pathSegments.length >= 2) {
                    final id = uri.pathSegments[1];
                    return _guarded((context) => DriveTrainEditPage(
                          vehicleId: id,
                          onProgressUpdate: () {},
                          inTabsPage: false,
                        ));
                  }
                  break;
                case 'tyres':
                  if (uri.pathSegments.length >= 2) {
                    final id = uri.pathSegments[1];
                    return _guarded((context) => TyresEditPage(
                          vehicleId: id,
                          onProgressUpdate: () {},
                          inTabsPage: false,
                        ));
                  }
                  break;
                case 'maintenance_warranty':
                  if (uri.pathSegments.length >= 2) {
                    final id = uri.pathSegments[1];
                    return _guarded((context) => MaintenanceEditSection(
                          vehicleId: id,
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
                        ));
                  }
                  break;
                case 'inspectionDetails':
                  // Support query params: /inspectionDetails?offerId=...&vehicleId=...&brands=...&variant=...&offerAmount=...
                  final q = uri.queryParameters;
                  if (q['offerId'] != null) {
                    final args = {
                      'offerId': q['offerId']!,
                      'offerAmount': q['offerAmount'] ?? '',
                      'vehicleId': q['vehicleId'] ?? '',
                      'brands': q['brands'] ?? '',
                      'variant': q['variant'] ?? '',
                    };
                    return _guarded((context) => InspectionDetailsPage(
                          offerId: args['offerId'] as String,
                          offerAmount: args['offerAmount'] as String,
                          vehicleId: args['vehicleId'] as String,
                          brand: args['brands'] as String,
                          variant: args['variant'] as String,
                        ));
                  }
                  break;
              }
            }
          }
          // Handle deep link: /basic_information/:vehicleId
          if (settings.name != null &&
              settings.name!.startsWith('/basic_information/')) {
            final uri = Uri.parse(settings.name!);
            final vehicleId =
                uri.pathSegments.length > 1 ? uri.pathSegments[1] : null;
            if (vehicleId != null && vehicleId.isNotEmpty) {
              return _guarded((context) => FutureBuilder<DocumentSnapshot>(
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
                      return BasicInformationEdit(vehicle: vehicle);
                    },
                  ));
            }
          }
          // Guard common protected named routes when entered directly (not exhaustive)
          final protected = <String>{
            '/offers',
            '/profile',
            '/wishlist',
            '/adminHome',
            '/adminUsers',
            '/adminOffers',
            '/adminComplaints',
            '/adminVehicles',
            '/adminFleets',
            '/truckPage',
            '/vehicleUpload',
            '/in-progress',
            '/transporterList',
          };
          if (settings.name != null && protected.contains(settings.name)) {
            return _guarded((context) => routes[settings.name!]!(context));
          }
          if (settings.name == '/inspectionDetails') {
            final args = settings.arguments as Map<String, dynamic>;
            return _guarded((context) => InspectionDetailsPage(
                  offerId: args['offerId'] as String,
                  offerAmount: args['offerAmount'] as String,
                  vehicleId: args['vehicleId'] as String,
                  brand: args['brands'] as String,
                  variant: args['variant'] as String,
                ));
          }
          return null;
        },
        onUnknownRoute: (settings) {
          // Route any unknown paths through the initializer to compute the correct destination
          return MaterialPageRoute(
            builder: (context) => const AppInitializer(),
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

        // Handle notification when app is launched from terminated state
        final initialMessage =
            await FirebaseMessaging.instance.getInitialMessage();
        if (initialMessage != null) {
          print(
              'DEBUG: App launched from notification: ${initialMessage.data}');
          // Store for handling after app is fully initialized
          _pendingNotificationData = initialMessage.data;
        }
      }
      // Setup auth token refresh
      final authService = AuthService();
      await authService.setupTokenRefresh();
      setState(() {
        _initialized = true;
      });

      // Handle pending notification after initialization
      if (_pendingNotificationData != null && mounted) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          final context = navigatorKey.currentContext;
          if (context != null) {
            _navigateBasedOnNotification(context, _pendingNotificationData!);
            _pendingNotificationData = null;
          }
        });
      }
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
    // Always return a widget synchronously; avoid eager navigation before first frame
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
