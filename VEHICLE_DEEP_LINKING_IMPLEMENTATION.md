# Vehicle Deep Linking Implementation

## Overview

The CTP app now supports comprehensive deep linking for vehicle details pages, allowing users to share direct links to specific vehicles that work across web, mobile, and when the app is closed.

## How It Works

### 1. Sharing a Vehicle

When users are viewing a vehicle details page, they can tap the share button which:

- Generates a URL in the format: `https://www.ctpapp.co.za/vehicle/{vehicleId}`
- Creates a descriptive message with vehicle details (brand, model, year)
- Uses the native sharing functionality of the device

### 2. Deep Link Routing

When someone clicks a vehicle link:

- The URL is processed by the `onGenerateRoute` function in `main.dart`
- The route pattern `/vehicle/:vehicleId` is detected
- The vehicle ID is extracted from the URL path
- The vehicle is fetched from Firestore
- The `VehicleDetailsPage` is displayed with the loaded vehicle data

### 3. URL Structure

```
https://www.ctpapp.co.za/vehicle/{vehicleId}
```

Example:

```
https://www.ctpapp.co.za/vehicle/abc123xyz
```

## Implementation Details

### Enhanced Share Function

Located in `lib/pages/vehicle_details_page.dart`:

```dart
void _shareVehicle() {
  final String vehicleId = vehicle.id;
  final String url = 'https://www.ctpapp.co.za/vehicle/$vehicleId';

  // Create a more descriptive message with vehicle details
  final String vehicleName = '${vehicle.brands.join(', ')} ${vehicle.makeModel} ${vehicle.year}';
  final String message = 'Check out this $vehicleName on CTP:\n\n$url';

  Share.share(message, subject: 'Vehicle Details - $vehicleName');
}
```

### Route Handling

Located in `lib/main.dart` `onGenerateRoute` function:

```dart
if (settings.name != null && settings.name!.startsWith('/vehicle/')) {
  final uri = Uri.parse(settings.name!);
  final vehicleId = uri.pathSegments.length > 1 ? uri.pathSegments[1] : null;
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
```

## Testing

### Manual Testing Steps

1. Navigate to any vehicle details page in the app
2. Tap the share button (located in the top right)
3. Copy the generated URL
4. Open the URL in a browser or share it with someone
5. Verify that clicking the link opens the app and navigates to the correct vehicle

### Test Page

A dedicated test page is available at `/vehicleDeepLinkTest` that allows:

- Entering a vehicle ID to test
- Generating the deep link URL
- Copying the URL to clipboard
- Testing navigation to the vehicle details

## Key Features

### ✅ Cross-Platform Support

- Works on iOS, Android, and Web
- Functions when app is closed (launches app)
- Functions when app is in background (brings to foreground)

### ✅ Error Handling

- Shows loading indicator while fetching vehicle data
- Displays error page if vehicle doesn't exist
- Graceful fallback for malformed URLs

### ✅ Enhanced Sharing

- Includes vehicle details in shared message
- Professional subject line for sharing
- Maintains clean URL structure

### ✅ Integration with Existing Systems

- Works with existing notification deep linking
- Compatible with existing route structure
- No breaking changes to current functionality

## URL Strategy

The app uses path-based URL strategy (`setPathUrlStrategy()`) which ensures:

- Clean URLs without hash fragments
- Better SEO for web deployment
- Professional appearance in shared links

## Security Considerations

- Vehicle IDs are validated against Firestore
- Non-existent vehicles show error page
- No sensitive data exposed in URLs
- Standard Firebase security rules apply

## Future Enhancements

- Could add UTM parameters for analytics tracking
- Could include thumbnail images in shared links (Open Graph)
- Could add preview cards for social media sharing
- Could implement QR code generation for vehicle links
