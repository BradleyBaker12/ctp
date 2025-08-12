# Deep Linking Testing Guide

## 🎯 **Quick Start Testing**

### **Method 1: Admin Panel Testing (Recommended for Development)**

1. **Access the Test Page**:

   ```
   Login as admin → Navigate to /adminNotificationTest
   ```

2. **Use the Enhanced Test Buttons**:

   - **Blue Button**: "Test New Offer → Offers Page"
   - **Green Button**: "Test New Vehicle → Vehicle Details"
   - **Orange Button**: "Test Inspection Booked → Offers Page"
   - **Purple Button**: "Test Sale Completion → Offers Page"

3. **Test Process**:
   - Click any test button
   - A notification will appear immediately
   - Tap the notification
   - Verify you're navigated to the correct page

---

## 📱 **Testing Different App States**

### **Foreground Testing**

```bash
1. Keep app open and visible
2. Click a test button in admin panel
3. Local notification appears at top
4. Tap notification → should navigate immediately
```

### **Background Testing**

```bash
1. Minimize the app (don't close it)
2. Send notification via admin panel or Firebase console
3. Notification appears in notification tray
4. Tap notification → app opens and navigates
```

### **Terminated State Testing**

```bash
1. Force close the app completely
2. Send notification via Firebase console
3. Tap notification → app launches and navigates after initialization
```

---

## 🔧 **Firebase Console Testing**

### **Setup**:

1. Go to Firebase Console → Your Project → Cloud Messaging
2. Click "Send your first message"
3. Use these test configurations:

### **Test 1: New Offer Notification**

```json
Title: "New Offer on Your Vehicle"
Body: "John Doe made an offer of R150,000"

Additional Options → Advanced Options → Custom Data:
{
  "notificationType": "new_offer",
  "vehicleId": "test_vehicle_123",
  "offerId": "test_offer_456",
  "dealerId": "dealer_id_here"
}
```

### **Test 2: New Vehicle Notification**

```json
Title: "New Vehicle Available"
Body: "Check out the new Mercedes Actros"

Custom Data:
{
  "notificationType": "new_vehicle",
  "vehicleId": "test_vehicle_123"
}
```

### **Test 3: Inspection Reminder**

```json
Title: "Inspection Scheduled"
Body: "Your inspection is tomorrow at 10 AM"

Custom Data:
{
  "notificationType": "inspection_booked",
  "vehicleId": "test_vehicle_123",
  "offerId": "test_offer_456"
}
```

---

## 🐛 **Debug Testing with Console Logs**

### **Enable Debug Logs**:

Open Chrome DevTools or device logs and watch for:

```bash
# When notification is received:
DEBUG: Handling notification tap with data: {notificationType: new_offer, ...}

# During navigation:
DEBUG: Navigation data - Type: new_offer, VehicleId: test_vehicle_123, OfferId: test_offer_456

# Specific navigation actions:
DEBUG: Navigating to vehicle: test_vehicle_123
DEBUG: Navigating to offer: test_offer_456
```

### **Error Debugging**:

```bash
# If navigation fails:
DEBUG: Error during navigation: [error_message]
DEBUG: Navigator context not available, storing for later

# If offer/vehicle not found:
DEBUG: Offer not found: test_offer_456
DEBUG: No authenticated user
```

---

## 🧪 **Real-World Testing Scenarios**

### **Scenario 1: Complete Offer Flow**

```bash
1. Transporter uploads vehicle
2. Admin approves vehicle
3. Dealer makes offer → Transporter gets "new_offer" notification
4. Tap notification → Should go to offers page
5. Transporter accepts offer → Dealer gets "offer_response" notification
6. Tap notification → Should go to offers page
```

### **Scenario 2: Inspection Flow**

```bash
1. Offer is accepted
2. Dealer schedules inspection → Transporter gets "inspection_booked"
3. Tap notification → Should go to offer details
4. Day of inspection → Both get "inspection_today_*" notifications
5. Tap notifications → Should go to relevant offer details
```

### **Scenario 3: Vehicle Discovery**

```bash
1. Admin pushes vehicle live
2. Dealers get "new_vehicle" notification
3. Tap notification → Should go to vehicle details page
4. Can then make offer from vehicle page
```

---

## ✅ **Expected Navigation Results**

| Notification Type   | Expected Navigation                        |
| ------------------- | ------------------------------------------ |
| `new_offer`         | → `/offers` (offers page)                  |
| `offer_response`    | → `/offers` (offers page)                  |
| `new_vehicle`       | → `/vehicle/{vehicleId}` (vehicle details) |
| `inspection_booked` | → `/offers` (offers page)                  |
| `collection_booked` | → `/offers` (offers page)                  |
| `vehicle_collected` | → `/offers` (offers page)                  |
| `sale_completion_*` | → `/offers` (offers page)                  |
| Unknown/Error       | → `/home` (home page)                      |

---

## 🚨 **Troubleshooting**

### **Navigation Not Working**:

1. Check console logs for error messages
2. Verify notification data contains required fields
3. Ensure user is authenticated
4. Check if app has proper navigation context

### **Notifications Not Appearing**:

1. Check device notification permissions
2. Verify FCM token is being generated
3. Test with local notification first
4. Check Firebase console for delivery status

### **Wrong Page Navigation**:

1. Verify notification `notificationType` field
2. Check if `vehicleId`/`offerId` values are correct
3. Ensure user has proper permissions for target page

---

## 📊 **Testing Checklist**

- [ ] Foreground notification tap → correct navigation
- [ ] Background notification tap → correct navigation
- [ ] Terminated app notification → correct navigation
- [ ] `new_offer` → offers page
- [ ] `new_vehicle` → vehicle details page
- [ ] `inspection_booked` → offers page
- [ ] `sale_completion_*` → offers page
- [ ] Unknown notification type → home page fallback
- [ ] No navigation context → pending notification handled
- [ ] Authentication required → login page redirect
- [ ] Console logs showing correct debug info

---

## 🔄 **Continuous Testing During Development**

1. **After Code Changes**: Test at least 2-3 notification types
2. **Before Deployment**: Run full test suite on both Android/iOS
3. **User Acceptance**: Have real users test common scenarios
4. **Performance**: Monitor navigation speed and app responsiveness

This testing approach ensures your deep linking works reliably across all user scenarios! 🚀
