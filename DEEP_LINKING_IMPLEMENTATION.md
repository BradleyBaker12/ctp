# Deep Linking Implementation for Notifications

## Overview

This implementation adds comprehensive deep linking functionality to the CTP app, allowing users to navigate directly to specific vehicles or offers when they tap on push notifications.

## Implementation Details

### 1. Global Navigation Key

Added a global navigator key in `main.dart`:

```dart
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
```

This allows navigation from anywhere in the app, including from background notification handlers.

### 2. Notification Handlers

#### FCM Background/Foreground Notifications

- **`FirebaseMessaging.onMessageOpenedApp`**: Handles notifications when app is in background
- **`FirebaseMessaging.onMessage`**: Handles foreground notifications and passes data to local notifications
- **`FirebaseMessaging.getInitialMessage()`**: Handles notifications when app is launched from terminated state

#### Local Notification Responses

- **`onDidReceiveNotificationResponse`**: Handles taps on local notifications displayed while app is in foreground

### 3. Deep Linking Logic

The navigation logic is handled by `_navigateBasedOnNotification()` which:

1. **Extracts notification data**:

   - `notificationType`: Type of notification (e.g., 'new_offer', 'vehicle_collected')
   - `vehicleId`: ID of the related vehicle
   - `offerId`: ID of the related offer
   - `dealerId`: ID of the dealer
   - `transporterId`: ID of the transporter

2. **Routes based on notification type**:

   - `new_offer`, `offer_response`: Navigate to offer details
   - `new_vehicle`: Navigate to vehicle details
   - `inspection_booked`, `collection_booked`: Navigate to offer details
   - `sale_completion_*`: Navigate to offer details
   - `invoice_payment_reminder`: Navigate to offer details

3. **Determines user context**: Checks user role and relationship to the offer/vehicle to navigate to the appropriate page

### 4. Navigation Targets

Based on the notification and user context:

- **Vehicle Details**: `/vehicle/{vehicleId}` for new vehicle notifications
- **Offers Page**: `/offers` for offer-related notifications (filtered by user role)
- **Admin Pages**: `/adminOffers` for admin users
- **Fallback**: `/home` for unknown notification types

## Notification Data Structure

The Cloud Functions already send the necessary data for deep linking:

```javascript
data: {
  vehicleId: "vehicle123",
  offerId: "offer456",
  dealerId: "dealer789",
  notificationType: "new_offer",
  timestamp: "2024-01-01T00:00:00.000Z"
}
```

## Supported Notification Types

- `new_offer`: New offer made on a vehicle
- `offer_response`: Offer accepted/rejected by transporter
- `offer_accepted_admin`: Admin notification for accepted offers
- `new_vehicle`: New vehicle available
- `inspection_booked`: Inspection scheduled
- `inspection_today_dealer/transporter`: Inspection reminder
- `collection_booked`: Collection scheduled
- `collection_confirmed`: Collection confirmed
- `vehicle_collected`: Vehicle collected
- `sale_completion_transporter/dealer`: Sale completed
- `invoice_payment_reminder`: Payment reminder

## Testing

### Manual Testing Steps

1. **Background Navigation**:

   - Send a notification when app is in background
   - Tap notification
   - Verify navigation to correct page

2. **Foreground Navigation**:

   - Send a notification when app is in foreground
   - Tap the local notification
   - Verify navigation to correct page

3. **Terminated State**:
   - Kill the app completely
   - Send a notification
   - Tap notification to launch app
   - Verify navigation after app loads

### Test Notification Examples

```dart
// Test via NotificationTestPage in admin panel
final testData = {
  'notificationType': 'new_offer',
  'vehicleId': 'test_vehicle_id',
  'offerId': 'test_offer_id',
  'dealerId': 'test_dealer_id',
};
```

## Error Handling

- **Missing Context**: Stores pending navigation data for when app becomes available
- **Invalid Data**: Falls back to home page navigation
- **Network Errors**: Gracefully handles Firestore fetch failures
- **Authentication**: Redirects to login if user not authenticated

## Performance Considerations

- Minimal data stored in notification payload
- Lazy loading of full document data only when needed
- Efficient navigation without unnecessary rebuilds
- Proper cleanup of pending notification data

## Future Enhancements

1. **Deep Links to Specific Offer States**: Navigate to inspection details, collection details, etc.
2. **Smart Navigation**: Remember user's last position and navigate more contextually
3. **Notification History**: Track which notifications led to which actions
4. **A/B Testing**: Test different navigation flows for better user engagement
