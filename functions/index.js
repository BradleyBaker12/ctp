// Load environment variables from .env
require("dotenv").config();
const admin = require("firebase-admin");
const {
  onDocumentCreated,
  onDocumentUpdated,
} = require("firebase-functions/v2/firestore");
const { onSchedule } = require("firebase-functions/v2/scheduler");
const functions = require("firebase-functions");
const sgMail = require("@sendgrid/mail");
// Initialize SendGrid API key, preferring env var, then config(), with safety check
const sgKey =
  process.env.SENDGRID_API_KEY ||
  (functions.config().sendgrid && functions.config().sendgrid.key);
if (!sgKey) {
  console.warn(
    "Warning: No SendGrid API key found in process.env.SENDGRID_API_KEY or functions.config().sendgrid.key"
  );
} else {
  sgMail.setApiKey(sgKey);
}

// Import Places API functions
const placesApi = require("./src/places-api");

// Import HTTP trigger helper for v2 functions
const { onRequest, onCall } = require("firebase-functions/v2/https");

// Export all places API functions as HTTP triggers in europe-west3
exports.placesAutocomplete = onRequest(
  { region: "europe-west3" },
  placesApi.placesAutocomplete
);
exports.getPlaceDetails = onRequest(
  { region: "europe-west3" },
  placesApi.getPlaceDetails
);
// Callable function: OEM manager creates an OEM employee under their company.
// The new user is set to isVerified=false (admin approval required).
exports.createCompanyEmployee = onCall(
  { region: "us-central1" },
  async (request) => {
    try {
      const ctx = request.auth;
      if (!ctx || !ctx.uid) {
        throw new functions.https.HttpsError(
          "unauthenticated",
          "Authentication required"
        );
      }

      const {
        email,
        firstName,
        lastName,
        phoneNumber,
        companyId: reqCompanyId,
      } = request.data || {};
      if (!email || typeof email !== "string") {
        throw new functions.https.HttpsError(
          "invalid-argument",
          "Missing or invalid 'email'"
        );
      }

      // Fetch caller (manager) profile
      const managerDoc = await db.collection("users").doc(ctx.uid).get();
      if (!managerDoc.exists) {
        throw new functions.https.HttpsError(
          "failed-precondition",
          "Manager profile not found"
        );
      }
      const manager = managerDoc.data() || {};

      const callerRole = String(manager.userRole || "").toLowerCase();
      const isAdmin =
        callerRole === "admin" || callerRole === "sales representative";
      const isOemManager =
        callerRole === "oem" && manager.isOemManager === true;
      if (!isAdmin && !isOemManager) {
        throw new functions.https.HttpsError(
          "permission-denied",
          "Only admins or OEM managers can create company users"
        );
      }

      const companyId = isAdmin
        ? reqCompanyId || manager.companyId
        : manager.companyId;
      if (!companyId && !isAdmin) {
        throw new functions.https.HttpsError(
          "failed-precondition",
          "Manager is missing companyId"
        );
      }

      // Create the auth user (with a random password and send reset link)
      const randomPassword = Math.random().toString(36).slice(-12) + "Aa1!";
      const userRecord = await admin.auth().createUser({
        email,
        emailVerified: false,
        displayName: [firstName, lastName].filter(Boolean).join(" "),
        password: randomPassword,
        disabled: false,
        phoneNumber:
          phoneNumber && typeof phoneNumber === "string"
            ? phoneNumber
            : undefined,
      });

      const newUid = userRecord.uid;

      // Create Firestore profile with pending approval
      const profile = {
        email,
        firstName: firstName || "",
        lastName: lastName || "",
        phoneNumber: phoneNumber || "",
        userRole: "oem",
        isOemManager: false,
        isVerified: false, // admin approval pending
        accountStatus: "pending",
        managerId: isAdmin
          ? manager.managerId || manager.uid || ctx.uid
          : ctx.uid,
        companyId: isAdmin ? manager.companyId || companyId || null : companyId,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
      };
      await db.collection("users").doc(newUid).set(profile, { merge: true });

      // Send password reset link
      try {
        const resetLink = await admin.auth().generatePasswordResetLink(email);
        if (sgMail && resetLink) {
          await sgMail.send({
            from: "admin@ctpapp.co.za",
            to: email,
            subject: "You're invited to CTP Portal",
            html: `
            <p>Hello${firstName ? " " + firstName : ""},</p>
            <p>Your account has been created by ${
              isAdmin ? "an administrator" : "your company manager"
            }.</p>
            <p>Please set your password here:</p>
            <p><a href="${resetLink}">Set Password</a></p>
            <p>Once set, your account will remain pending until an admin approves it.</p>
          `,
          });
        }
      } catch (e) {
        console.warn("createCompanyEmployee: Failed to send reset link", e);
      }

      return { uid: newUid };
    } catch (err) {
      console.error("createCompanyEmployee error", err);
      if (err instanceof functions.https.HttpsError) throw err;
      throw new functions.https.HttpsError(
        "internal",
        String(err?.message || err)
      );
    }
  }
);

// Callable function: Elevate all existing OEM users to managers.
// Admin-only. Optionally backfills companyId when missing.
exports.elevateAllOemToManagers = onCall(
  { region: "us-central1" },
  async (request) => {
    try {
      const ctx = request.auth;
      if (!ctx || !ctx.uid) {
        throw new functions.https.HttpsError(
          "unauthenticated",
          "Authentication required"
        );
      }
      const callerDoc = await db.collection("users").doc(ctx.uid).get();
      const role = String(callerDoc.data()?.userRole || "").toLowerCase();
      if (!(role === "admin" || role === "sales representative")) {
        throw new functions.https.HttpsError(
          "permission-denied",
          "Only admins or sales representatives can run this migration"
        );
      }

      const snap = await db
        .collection("users")
        .where("userRole", "==", "oem")
        .get();
      let updated = 0;
      const batch = db.batch();
      snap.forEach((doc) => {
        const data = doc.data() || {};
        const updates = { isOemManager: true };
        if (!data.companyId) {
          updates.companyId = doc.id; // backfill with self uid as companyId
        }
        batch.set(doc.ref, updates, { merge: true });
        updated++;
      });
      if (updated > 0) {
        await batch.commit();
      }
      return { updated };
    } catch (err) {
      console.error("elevateAllOemToManagers error", err);
      if (err instanceof functions.https.HttpsError) throw err;
      throw new functions.https.HttpsError(
        "internal",
        String(err?.message || err)
      );
    }
  }
);

admin.initializeApp();
const db = admin.firestore();

const express = require("express");
const app = express();

// Notify transporter when a dealer makes an offer on their vehicle
// Scheduled: 2-hour pre-inspection reminders to dealer and transporter
exports.sendTwoHourPreInspectionReminders = onSchedule(
  {
    schedule: "*/15 * * * *", // Every 15 minutes
    timeZone: "Africa/Johannesburg",
    region: "us-central1",
  },
  async () => {
    console.log("[sendTwoHourPreInspectionReminders] Job start");
    try {
      const now = new Date();
      const nowMs = now.getTime();
      const twoHoursMs = 2 * 60 * 60 * 1000;
      const windowMs = 20 * 60 * 1000; // ±20 minutes window
      const targetStart = nowMs + twoHoursMs - windowMs;
      const targetEnd = nowMs + twoHoursMs + windowMs;

      // Build a search window from start of today to end of tomorrow
      const startOfToday = new Date(
        now.getFullYear(),
        now.getMonth(),
        now.getDate()
      );
      const endOfTomorrow = new Date(
        now.getFullYear(),
        now.getMonth(),
        now.getDate() + 1,
        23,
        59,
        59,
        999
      );

      const offersSnapshot = await db
        .collection("offers")
        .where("dealerSelectedInspectionDate", ">=", startOfToday)
        .where("dealerSelectedInspectionDate", "<=", endOfTomorrow)
        .get();

      if (offersSnapshot.empty) {
        console.log(
          "[sendTwoHourPreInspectionReminders] No offers with inspections in the window"
        );
        return;
      }

      let sent = 0;
      for (const offerDoc of offersSnapshot.docs) {
        const offer = offerDoc.data();
        const offerId = offerDoc.id;

        try {
          // Skip if missing required fields or already completed
          if (
            !offer.dealerSelectedInspectionDate ||
            !offer.dealerSelectedInspectionTime
          )
            continue;
          if (
            offer.inspectionStatus === "completed" ||
            offer.dealerInspectionComplete ||
            offer.transporterInspectionComplete
          )
            continue;

          // Compose a Date from date + time string (e.g., "08:00 AM")
          const dateVal = offer.dealerSelectedInspectionDate.toDate
            ? offer.dealerSelectedInspectionDate.toDate()
            : new Date(offer.dealerSelectedInspectionDate);

          const timeStr = String(offer.dealerSelectedInspectionTime);
          const timeMatch = timeStr.match(/^(\d{1,2}):(\d{2})\s*(AM|PM)$/i);
          if (!timeMatch) {
            // Try 24h fallback e.g. "13:30"
            const timeMatch24 = timeStr.match(/^(\d{1,2}):(\d{2})$/);
            if (!timeMatch24) continue;
            const h = parseInt(timeMatch24[1], 10);
            const m = parseInt(timeMatch24[2], 10);
            const scheduled = new Date(
              dateVal.getFullYear(),
              dateVal.getMonth(),
              dateVal.getDate(),
              h,
              m,
              0,
              0
            );
            const scheduledMs = scheduled.getTime();
            if (scheduledMs < targetStart || scheduledMs > targetEnd) continue;
            // Dedupe key
            const appointmentKey = `${dateVal
              .toISOString()
              .slice(0, 10)} ${timeStr}`;
            if (offer.lastPreInspectionReminderFor === appointmentKey) continue;
            await sendPreInspectionReminder(
              db,
              admin,
              sgMail,
              offer,
              offerId,
              scheduled,
              appointmentKey
            );
            sent++;
            continue;
          }

          let hour = parseInt(timeMatch[1], 10);
          const minute = parseInt(timeMatch[2], 10);
          const ampm = timeMatch[3].toUpperCase();
          if (ampm === "PM" && hour !== 12) hour += 12;
          if (ampm === "AM" && hour === 12) hour = 0;
          const scheduled = new Date(
            dateVal.getFullYear(),
            dateVal.getMonth(),
            dateVal.getDate(),
            hour,
            minute,
            0,
            0
          );
          const scheduledMs = scheduled.getTime();
          if (scheduledMs < targetStart || scheduledMs > targetEnd) continue;

          const appointmentKey = `${dateVal
            .toISOString()
            .slice(0, 10)} ${timeStr}`;
          if (offer.lastPreInspectionReminderFor === appointmentKey) continue;

          await sendPreInspectionReminder(
            db,
            admin,
            sgMail,
            offer,
            offerId,
            scheduled,
            appointmentKey
          );
          sent++;
        } catch (innerErr) {
          console.error(
            "[sendTwoHourPreInspectionReminders] Error per-offer",
            offerId,
            innerErr
          );
        }
      }

      console.log(
        `[sendTwoHourPreInspectionReminders] Done. Sent ${sent} reminders`
      );
    } catch (e) {
      console.error("[sendTwoHourPreInspectionReminders] Error", e);
    }
  }
);

async function sendPreInspectionReminder(
  db,
  adminLib,
  sg,
  offer,
  offerId,
  scheduledDate,
  appointmentKey
) {
  // Fetch parties
  const [dealerDoc, transporterDoc, vehicleDoc] = await Promise.all([
    db.collection("users").doc(offer.dealerId).get(),
    db.collection("users").doc(offer.transporterId).get(),
    db.collection("vehicles").doc(offer.vehicleId).get(),
  ]);

  const dealer = dealerDoc.exists ? dealerDoc.data() : {};
  const transporter = transporterDoc.exists ? transporterDoc.data() : {};
  const vehicle = vehicleDoc.exists ? vehicleDoc.data() : {};

  const vehicleName = `${
    vehicle.brands?.join(", ") || vehicle.brand || "Vehicle"
  } ${vehicle.makeModel || vehicle.model || ""} ${vehicle.year || ""}`.trim();

  const dateStr = scheduledDate.toLocaleDateString();
  const timeStr = offer.dealerSelectedInspectionTime;
  const location = offer.dealerSelectedInspectionLocation || "Location TBD";
  const offerLink = `https://ctpapp.co.za/offer/${offerId}`;

  // Push: dealer
  if (dealer?.fcmToken) {
    try {
      await adminLib.messaging().send({
        notification: {
          title: "🔔 Inspection in 2 hours",
          body: `Reminder: Your inspection for ${vehicleName} is at ${timeStr} today.`,
        },
        data: {
          notificationType: "inspection_2h_dealer",
          offerId,
          vehicleId: offer.vehicleId || "",
          inspectionDate: dateStr,
          inspectionTime: timeStr,
          inspectionLocation: location,
          timestamp: new Date().toISOString(),
        },
        token: dealer.fcmToken,
      });
    } catch (e) {
      console.error("[sendTwoHourPreInspectionReminders] Dealer push error", e);
    }
  }

  // Push: transporter
  if (transporter?.fcmToken) {
    try {
      await adminLib.messaging().send({
        notification: {
          title: "🔔 Inspection in 2 hours",
          body: `Reminder: Inspection for your ${vehicleName} is at ${timeStr} today.`,
        },
        data: {
          notificationType: "inspection_2h_transporter",
          offerId,
          vehicleId: offer.vehicleId || "",
          inspectionDate: dateStr,
          inspectionTime: timeStr,
          inspectionLocation: location,
          timestamp: new Date().toISOString(),
        },
        token: transporter.fcmToken,
      });
    } catch (e) {
      console.error(
        "[sendTwoHourPreInspectionReminders] Transporter push error",
        e
      );
    }
  }

  // Optional emails
  if (sg) {
    const dealerEmail = dealer?.email;
    const transporterEmail = transporter?.email;
    const subject = `🔔 2-hour Reminder: Inspection at ${timeStr} - ${vehicleName}`;
    const html = `
      <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto;">
        <h2 style="color:#2F7FFF;">Inspection in 2 hours</h2>
        <p>This is a friendly reminder of your upcoming inspection.</p>
        <div style="background:#f8f9fa;padding:16px;border-radius:8px;">
          <p><strong>Vehicle:</strong> ${vehicleName}</p>
          <p><strong>Date:</strong> ${dateStr}</p>
          <p><strong>Time:</strong> ${timeStr}</p>
          <p><strong>Location:</strong> ${location}</p>
        </div>
        <div style="margin:20px 0;text-align:center;">
          <a href="${offerLink}" style="background:#2F7FFF;color:#fff;padding:10px 16px;text-decoration:none;border-radius:4px;">View Details</a>
        </div>
        <p style="color:#666;font-size:12px;">You received this because an inspection is scheduled soon.</p>
      </div>`;
    try {
      if (dealerEmail) {
        await sg.send({
          from: "admin@ctpapp.co.za",
          to: dealerEmail,
          subject,
          html,
        });
      }
      if (transporterEmail) {
        await sg.send({
          from: "admin@ctpapp.co.za",
          to: transporterEmail,
          subject,
          html,
        });
      }
    } catch (e) {
      console.error("[sendTwoHourPreInspectionReminders] Email error", e);
    }
  }

  // Mark reminder sent for this appointment
  await db.collection("offers").doc(offerId).set(
    {
      lastPreInspectionReminderAt:
        adminLib.firestore.FieldValue.serverTimestamp(),
      lastPreInspectionReminderFor: appointmentKey,
    },
    { merge: true }
  );
}

// 3) Notify admins when transporter invoice uploaded
exports.notifyAdminsOnTransporterInvoiceUpload = onDocumentUpdated(
  {
    document: "offers/{offerId}",
    region: "us-central1",
  },
  async (event) => {
    const before = event.data.before.data();
    const after = event.data.after.data();
    if (!before || !after) return;

    const had = !!(
      before.transporterInvoice &&
      String(before.transporterInvoice).trim() !== ""
    );
    const has = !!(
      after.transporterInvoice && String(after.transporterInvoice).trim() !== ""
    );
    if (had || !has) return;

    const offerId = event.params.offerId;

    try {
      await db
        .collection("offers")
        .doc(offerId)
        .set({ offerStatus: "payment options" }, { merge: true });

      const adminUsersSnapshot = await db
        .collection("users")
        .where("userRole", "in", ["admin", "sales representative"])
        .get();

      for (const adminDoc of adminUsersSnapshot.docs) {
        const a = adminDoc.data();
        if (!a.fcmToken) continue;
        await admin.messaging().send({
          notification: {
            title: "Transporter Invoice Uploaded",
            body: "A transporter invoice has been uploaded. Review and generate the external invoice.",
          },
          data: {
            notificationType: "transporter_invoice_uploaded",
            offerId,
            vehicleId: after.vehicleId || "",
            timestamp: new Date().toISOString(),
          },
          token: a.fcmToken,
        });
      }

      if (sgMail) {
        const adminEmails = adminUsersSnapshot.docs
          .map((d) => d.data().email)
          .filter(Boolean);
        if (adminEmails.length) {
          await sgMail.send({
            from: "admin@ctpapp.co.za",
            to: adminEmails,
            subject: "Transporter Invoice Uploaded",
            html: `<p>A transporter invoice has been uploaded for offer ${offerId}. Please review and generate/send the buyer invoice.</p>`,
          });
        }
      }
    } catch (e) {
      console.error("[notifyAdminsOnTransporterInvoiceUpload] Error:", e);
    }
  }
);

// Trigger: After dealer confirms collection, notify admins to release payment to transporter
exports.notifyAdminsToReleasePaymentOnCollectionConfirmation =
  onDocumentUpdated(
    { document: "offers/{offerId}", region: "us-central1" },
    async (event) => {
      const before = event.data.before.data();
      const after = event.data.after.data();
      if (!before || !after) return;

      const beforeStatus = (before.offerStatus || "").toLowerCase();
      const afterStatus = (after.offerStatus || "").toLowerCase();

      const collectionJustConfirmed =
        (!before.collectionConfirmed && !!after.collectionConfirmed) ||
        (beforeStatus !== "collected" && afterStatus === "collected");

      if (!collectionJustConfirmed) return;

      // Dedupe
      if (after.releasePaymentPromptAt) return;

      const offerId = event.params.offerId;
      try {
        // Fetch parties and vehicle
        const [dealerDoc, transporterDoc, vehicleDoc] = await Promise.all([
          db.collection("users").doc(after.dealerId).get(),
          db.collection("users").doc(after.transporterId).get(),
          db.collection("vehicles").doc(after.vehicleId).get(),
        ]);
        const dealer = dealerDoc.exists ? dealerDoc.data() : {};
        const transporter = transporterDoc.exists ? transporterDoc.data() : {};
        const vehicle = vehicleDoc.exists ? vehicleDoc.data() : {};
        const dealerName =
          `${dealer.firstName || ""} ${dealer.lastName || ""}`.trim() ||
          dealer.companyName ||
          "Dealer";
        const transporterName =
          `${transporter.firstName || ""} ${
            transporter.lastName || ""
          }`.trim() ||
          transporter.companyName ||
          "Transporter";
        const vehicleName = `${
          vehicle.brands?.join(", ") || vehicle.brand || "Vehicle"
        } ${vehicle.makeModel || vehicle.model || ""} ${
          vehicle.year || ""
        }`.trim();
        const offerLink = `https://ctpapp.co.za/offer/${offerId}`;

        const adminUsersSnapshot = await db
          .collection("users")
          .where("userRole", "in", ["admin", "sales representative"])
          .get();

        // Push notifications
        for (const adminDoc of adminUsersSnapshot.docs) {
          const a = adminDoc.data();
          if (!a?.fcmToken) continue;
          try {
            await admin.messaging().send({
              notification: {
                title: "💸 Release Payment to Transporter",
                body: `Dealer ${dealerName} confirmed collection of ${vehicleName}. Please release payout to ${transporterName}.`,
              },
              data: {
                notificationType: "release_payment_prompt",
                offerId,
                vehicleId: after.vehicleId || "",
                dealerId: after.dealerId || "",
                transporterId: after.transporterId || "",
                timestamp: new Date().toISOString(),
              },
              token: a.fcmToken,
            });
          } catch (pushErr) {
            console.error(
              "[notifyAdminsToReleasePaymentOnCollectionConfirmation] Push error",
              pushErr
            );
          }
        }

        // Email
        if (sgMail) {
          const adminEmails = adminUsersSnapshot.docs
            .map((d) => d.data().email)
            .filter(Boolean);
          if (adminEmails.length) {
            try {
              await sgMail.send({
                from: "admin@ctpapp.co.za",
                to: adminEmails,
                subject: `💸 Action Required: Release Payment - ${vehicleName}`,
                html: `
                <div style="font-family: Arial, sans-serif; max-width: 640px; margin: 0 auto;">
                  <h2 style="color:#28a745;">Collection Confirmed</h2>
                  <p>Dealer <strong>${dealerName}</strong> has confirmed collection of <strong>${vehicleName}</strong>.</p>
                  <p>Please release the payout to <strong>${transporterName}</strong> in your admin panel.</p>
                  <div style="margin:20px 0;text-align:center;">
                    <a href="${offerLink}" style="background:#28a745;color:#fff;padding:10px 16px;text-decoration:none;border-radius:4px;">Open Offer</a>
                  </div>
                  <p style="color:#666;font-size:12px;">You are receiving this because you are listed as an admin/sales representative.</p>
                </div>`,
              });
            } catch (emailErr) {
              console.error(
                "[notifyAdminsToReleasePaymentOnCollectionConfirmation] Email error",
                emailErr
              );
            }
          }
        }

        // Mark prompt sent
        await db.collection("offers").doc(offerId).set(
          {
            releasePaymentPromptAt:
              admin.firestore.FieldValue.serverTimestamp(),
          },
          { merge: true }
        );
      } catch (e) {
        console.error(
          "[notifyAdminsToReleasePaymentOnCollectionConfirmation] Error",
          e
        );
      }
    }
  );

// Immediate: when an offer is accepted and no transporter invoice exists, ask transporter to upload invoice
exports.notifyTransporterToUploadInvoiceOnAcceptance = onDocumentUpdated(
  { document: "offers/{offerId}", region: "us-central1" },
  async (event) => {
    const before = event.data.before.data();
    const after = event.data.after.data();
    if (!before || !after) return;

    // Only run when offer transitions to accepted
    const beforeStatus = (before.offerStatus || "").toLowerCase();
    const afterStatus = (after.offerStatus || "").toLowerCase();
    if (beforeStatus === afterStatus || afterStatus !== "accepted") return;

    // If invoice already exists, skip
    const hasInvoice = !!(
      after.transporterInvoice && String(after.transporterInvoice).trim() !== ""
    );
    if (hasInvoice) return;

    try {
      const vehicleDoc = await db
        .collection("vehicles")
        .doc(after.vehicleId)
        .get();
      if (!vehicleDoc.exists) return;
      const transporterId = vehicleDoc.data().userId;
      if (!transporterId) return;
      const transporterDoc = await db
        .collection("users")
        .doc(transporterId)
        .get();
      if (!transporterDoc.exists) return;
      const t = transporterDoc.data();
      if (!t.fcmToken) return;

      await admin.messaging().send({
        notification: {
          title: "Upload Your Invoice",
          body: "Please upload your inspection/transport invoice to proceed with the sale.",
        },
        data: {
          notificationType: "transporter_invoice_request",
          offerId: event.params.offerId,
          vehicleId: after.vehicleId || "",
          timestamp: new Date().toISOString(),
        },
        token: t.fcmToken,
      });
    } catch (e) {
      console.error("[notifyTransporterToUploadInvoiceOnAcceptance] Error:", e);
    }
  }
);

// 5) Notify dealer when external invoice uploaded/available
exports.notifyDealerOnExternalInvoiceAvailable = onDocumentUpdated(
  {
    document: "offers/{offerId}",
    region: "us-central1",
  },
  async (event) => {
    const before = event.data.before.data();
    const after = event.data.after.data();
    if (!before || !after) return;

    const had = !!(
      before.externalInvoice && String(before.externalInvoice).trim() !== ""
    );
    const has = !!(
      after.externalInvoice && String(after.externalInvoice).trim() !== ""
    );
    // Be permissive: consider externalInvoiceUrl too
    const hadUrl = !!(
      before.externalInvoiceUrl &&
      String(before.externalInvoiceUrl).trim() !== ""
    );
    const hasUrl = !!(
      after.externalInvoiceUrl && String(after.externalInvoiceUrl).trim() !== ""
    );

    if (had || hadUrl || !(has || hasUrl)) return;

    const offerId = event.params.offerId;
    try {
      await db
        .collection("offers")
        .doc(offerId)
        .set({ offerStatus: "payment pending" }, { merge: true });

      const dealerDoc = await db.collection("users").doc(after.dealerId).get();
      const dealer = dealerDoc.exists ? dealerDoc.data() : {};
      if (dealer?.fcmToken) {
        await admin.messaging().send({
          notification: {
            title: "Invoice Ready",
            body: "Your invoice is ready. Please complete payment.",
          },
          data: {
            notificationType: "invoice_ready",
            offerId,
            vehicleId: after.vehicleId || "",
            timestamp: new Date().toISOString(),
          },
          token: dealer.fcmToken,
        });
      }
      if (sgMail && dealer?.email) {
        await sgMail.send({
          from: "admin@ctpapp.co.za",
          to: dealer.email,
          subject: "Invoice Ready",
          html: `<p>Your invoice is ready for offer ${offerId}. Please complete payment to proceed to collection.</p>`,
        });
      }
    } catch (e) {
      console.error("[notifyDealerOnExternalInvoiceAvailable] Error:", e);
    }
  }
);

// 8/9) Remind admins of today’s collections at 07:00 SAST
exports.sendTodayCollectionReminders = onSchedule(
  {
    schedule: "0 7 * * *",
    timeZone: "Africa/Johannesburg",
    region: "us-central1",
  },
  async () => {
    const today = new Date();
    const start = new Date(
      today.getFullYear(),
      today.getMonth(),
      today.getDate()
    );
    const end = new Date(
      today.getFullYear(),
      today.getMonth(),
      today.getDate() + 1
    );

    try {
      const offersSnap = await db
        .collection("offers")
        .where("dealerSelectedCollectionDate", ">=", start)
        .where("dealerSelectedCollectionDate", "<", end)
        .get();

      if (offersSnap.empty) return;

      const admins = await db
        .collection("users")
        .where("userRole", "in", ["admin", "sales representative"])
        .get();

      for (const doc of offersSnap.docs) {
        const o = doc.data();
        const offerId = doc.id;
        for (const a of admins.docs) {
          const adminData = a.data();
          if (!adminData.fcmToken) continue;
          await admin.messaging().send({
            notification: {
              title: "Collections Today",
              body: "There is a collection scheduled today that may need oversight.",
            },
            data: {
              notificationType: "collection_today_admin",
              offerId,
              vehicleId: o.vehicleId || "",
              timestamp: new Date().toISOString(),
            },
            token: adminData.fcmToken,
          });
        }
      }
    } catch (e) {
      console.error("[sendTodayCollectionReminders] Error:", e);
    }
  }
);

// 10/11) Notify transporter when payout marked as paid
exports.notifyTransporterOnPayoutPaid = onDocumentUpdated(
  { document: "offers/{offerId}", region: "us-central1" },
  async (event) => {
    const before = event.data.before.data();
    const after = event.data.after.data();
    if (!before || !after) return;

    const had = (before.transporterPayoutStatus || "").toLowerCase();
    const has = (after.transporterPayoutStatus || "").toLowerCase();
    if (had === has || has !== "paid") return;

    try {
      const vehicleDoc = await db
        .collection("vehicles")
        .doc(after.vehicleId)
        .get();
      if (!vehicleDoc.exists) return;
      const transporterId = vehicleDoc.data().userId;
      if (!transporterId) return;
      const transporterDoc = await db
        .collection("users")
        .doc(transporterId)
        .get();
      const t = transporterDoc.exists ? transporterDoc.data() : {};
      if (!t?.fcmToken) return;
      await admin.messaging().send({
        notification: {
          title: "Payout Completed",
          body: "Your transporter payout has been made.",
        },
        data: {
          notificationType: "transporter_payout_paid",
          offerId: event.params.offerId,
          vehicleId: after.vehicleId || "",
          timestamp: new Date().toISOString(),
        },
        token: t.fcmToken,
      });
    } catch (e) {
      console.error("[notifyTransporterOnPayoutPaid] Error:", e);
    }
  }
);
exports.notifyTransporterOnNewOffer = onDocumentCreated(
  {
    document: "offers/{offerId}",
    region: "us-central1",
  },
  async (event) => {
    console.log(
      "[notifyTransporterOnNewOffer] Triggered for offerId:",
      event.params.offerId
    );

    const snap = event.data;
    if (!snap) {
      console.log("[notifyTransporterOnNewOffer] No snapshot data");
      return;
    }

    const offerData = snap.data();
    const offerId = event.params.offerId;

    console.log("[notifyTransporterOnNewOffer] Offer data:", offerData);

    try {
      // Get vehicle details to find the transporter
      const vehicleDoc = await db
        .collection("vehicles")
        .doc(offerData.vehicleId)
        .get();

      if (!vehicleDoc.exists) {
        console.log(
          "[notifyTransporterOnNewOffer] Vehicle not found:",
          offerData.vehicleId
        );
        return;
      }

      const vehicleData = vehicleDoc.data();
      const transporterId = vehicleData.userId; // Vehicle owner (transporter)

      if (!transporterId) {
        console.log(
          "[notifyTransporterOnNewOffer] No transporter ID found on vehicle"
        );
        return;
      }

      // Get transporter details
      const transporterDoc = await db
        .collection("users")
        .doc(transporterId)
        .get();

      if (!transporterDoc.exists) {
        console.log(
          "[notifyTransporterOnNewOffer] Transporter not found:",
          transporterId
        );
        return;
      }

      const transporterData = transporterDoc.data();

      if (!transporterData.fcmToken) {
        console.log(
          "[notifyTransporterOnNewOffer] Transporter has no FCM token:",
          transporterId
        );
        return;
      }

      // Intentionally not fetching dealer details for transporter-facing notification to avoid exposing dealer identity

      // Format the offer amount
      const formattedAmount = new Intl.NumberFormat("en-ZA", {
        style: "currency",
        currency: "ZAR",
        minimumFractionDigits: 0,
      }).format(offerData.offerAmount);

      // Create vehicle description
      const vehicleName = `${
        vehicleData.brands?.join(", ") || vehicleData.brand || "Vehicle"
      } ${vehicleData.makeModel || vehicleData.model || ""} ${
        vehicleData.year || ""
      }`.trim();

      // Send push notification to transporter
      const message = {
        notification: {
          title: "New Offer on Your Vehicle",
          body: `You have received a new offer of ${formattedAmount} for your vehicle, ${vehicleName}.`,
        },
        data: {
          vehicleId: offerData.vehicleId,
          offerId: offerId,
          dealerId: offerData.dealerId,
          offerAmount: offerData.offerAmount.toString(),
          notificationType: "new_offer",
          timestamp: new Date().toISOString(),
        },
        token: transporterData.fcmToken,
      };

      await admin.messaging().send(message);
      console.log(
        `[notifyTransporterOnNewOffer] Notification sent to transporter ${transporterId} for offer ${offerId}`
      );
    } catch (error) {
      console.error("[notifyTransporterOnNewOffer] Error:", error);
    }
  }
);

// 2) Daily reminder for transporter to upload invoice if missing
exports.sendTransporterInvoiceReminders = onSchedule(
  {
    schedule: "0 9 * * *",
    timeZone: "Africa/Johannesburg",
    region: "us-central1",
  },
  async () => {
    try {
      const offersSnap = await db
        .collection("offers")
        .where("offerStatus", "in", [
          "accepted",
          "payment options",
          "payment pending",
        ]) // workflow stages before payment
        .get();

      if (offersSnap.empty) return;

      for (const doc of offersSnap.docs) {
        const o = doc.data();
        const missing = !(
          o.transporterInvoice && String(o.transporterInvoice).trim() !== ""
        );
        if (!missing) continue;

        // Find transporter via vehicle
        const vehicleDoc = await db
          .collection("vehicles")
          .doc(o.vehicleId)
          .get();
        if (!vehicleDoc.exists) continue;
        const transporterId = vehicleDoc.data().userId;
        if (!transporterId) continue;
        const transporterDoc = await db
          .collection("users")
          .doc(transporterId)
          .get();
        if (!transporterDoc.exists) continue;
        const t = transporterDoc.data();
        if (!t.fcmToken) continue;

        await admin.messaging().send({
          notification: {
            title: "Invoice Needed",
            body: "Please upload your inspection/transport invoice to proceed.",
          },
          data: {
            notificationType: "transporter_invoice_reminder",
            offerId: doc.id,
            vehicleId: o.vehicleId || "",
            timestamp: new Date().toISOString(),
          },
          token: t.fcmToken,
        });
      }
    } catch (e) {
      console.error("[sendTransporterInvoiceReminders] Error:", e);
    }
  }
);

// Notify transporter when their offer status changes (accepted, rejected, etc.)
exports.notifyTransporterOnOfferStatusChange = onDocumentUpdated(
  {
    document: "offers/{offerId}",
    region: "us-central1",
  },
  async (event) => {
    console.log(
      "[notifyTransporterOnOfferStatusChange] Triggered for offerId:",
      event.params.offerId
    );

    const before = event.data.before.data();
    const after = event.data.after.data();
    const offerId = event.params.offerId;

    if (!before || !after) {
      console.log(
        "[notifyTransporterOnOfferStatusChange] No before/after data"
      );
      return;
    }

    // Check if status changed
    const beforeStatus = before.offerStatus?.toLowerCase() || "";
    const afterStatus = after.offerStatus?.toLowerCase() || "";

    // Do not process if the offer is collected or status is locked
    if (
      after.statusLocked === true ||
      afterStatus === "collected" ||
      after.transactionComplete === true
    ) {
      console.log(
        "[notifyTransporterOnOfferStatusChange] Offer is locked/collected, skipping notification"
      );
      return;
    }

    if (beforeStatus === afterStatus) {
      console.log(
        "[notifyTransporterOnOfferStatusChange] No status change detected"
      );
      return;
    }

    console.log(
      `[notifyTransporterOnOfferStatusChange] Status changed from ${beforeStatus} to ${afterStatus}`
    );

    try {
      // Get vehicle details to find the transporter
      const vehicleDoc = await db
        .collection("vehicles")
        .doc(after.vehicleId)
        .get();

      if (!vehicleDoc.exists) {
        console.log(
          "[notifyTransporterOnOfferStatusChange] Vehicle not found:",
          after.vehicleId
        );
        return;
      }

      const vehicleData = vehicleDoc.data();
      const transporterId = vehicleData.userId; // Vehicle owner (transporter)

      if (!transporterId) {
        console.log(
          "[notifyTransporterOnOfferStatusChange] No transporter ID found on vehicle"
        );
        return;
      }

      // Get transporter details
      const transporterDoc = await db
        .collection("users")
        .doc(transporterId)
        .get();

      if (!transporterDoc.exists) {
        console.log(
          "[notifyTransporterOnOfferStatusChange] Transporter not found:",
          transporterId
        );
        return;
      }

      const transporterData = transporterDoc.data();

      if (!transporterData.fcmToken) {
        console.log(
          "[notifyTransporterOnOfferStatusChange] Transporter has no FCM token:",
          transporterId
        );
        return;
      }

      // Intentionally not fetching dealer details for transporter-facing notification to avoid exposing dealer identity

      // Format the offer amount
      const formattedAmount = new Intl.NumberFormat("en-ZA", {
        style: "currency",
        currency: "ZAR",
        minimumFractionDigits: 0,
      }).format(after.offerAmount);

      // Create vehicle description
      const vehicleName = `${
        vehicleData.brands?.join(", ") || vehicleData.brand || "Vehicle"
      } ${vehicleData.makeModel || vehicleData.model || ""} ${
        vehicleData.year || ""
      }`.trim();

      // Create notification based on status
      let title = "";
      let body = "";

      switch (afterStatus) {
        case "accepted":
          title = "Offer Accepted! 🎉";
          body = `Congratulations! You've accepted an offer of ${formattedAmount} for your ${vehicleName}.`;
          break;
        case "rejected":
          title = "Offer Declined";
          body = `You've declined an offer of ${formattedAmount} for your ${vehicleName}.`;
          break;
        case "pending":
          title = "Offer Updated";
          body = `An offer of ${formattedAmount} for your ${vehicleName} is now pending review.`;
          break;
        case "expired":
          title = "Offer Expired";
          body = `An offer of ${formattedAmount} for your ${vehicleName} has expired.`;
          break;
        default:
          title = "Offer Status Updated";
          body = `Your offer for ${vehicleName} has been updated.`;
      }

      // Send push notification to transporter
      const message = {
        notification: {
          title: title,
          body: body,
        },
        data: {
          vehicleId: after.vehicleId,
          offerId: offerId,
          dealerId: after.dealerId,
          offerAmount: after.offerAmount.toString(),
          offerStatus: afterStatus,
          notificationType: "offer_status_change",
          timestamp: new Date().toISOString(),
        },
        token: transporterData.fcmToken,
      };

      await admin.messaging().send(message);
      console.log(
        `[notifyTransporterOnOfferStatusChange] Notification sent to transporter ${transporterId} for offer status change: ${afterStatus}`
      );
    } catch (error) {
      console.error("[notifyTransporterOnOfferStatusChange] Error:", error);
    }
  }
);

// Notify dealer when transporter responds to their offer (accepts/rejects)
exports.notifyDealerOnOfferResponse = onDocumentUpdated(
  {
    document: "offers/{offerId}",
    region: "us-central1",
  },
  async (event) => {
    console.log(
      "[notifyDealerOnOfferResponse] Triggered for offerId:",
      event.params.offerId
    );

    const before = event.data.before.data();
    const after = event.data.after.data();
    const offerId = event.params.offerId;

    if (!before || !after) {
      console.log("[notifyDealerOnOfferResponse] No before/after data");
      return;
    }

    // Check if status changed to accepted or rejected (transporter responded)
    const beforeStatus = before.offerStatus?.toLowerCase() || "";
    const afterStatus = after.offerStatus?.toLowerCase() || "";

    // Do not process if the offer is collected or status is locked
    if (
      after.statusLocked === true ||
      afterStatus === "collected" ||
      after.transactionComplete === true
    ) {
      console.log(
        "[notifyDealerOnOfferResponse] Offer is locked/collected, skipping notification"
      );
      return;
    }

    if (
      beforeStatus === afterStatus ||
      (afterStatus !== "accepted" && afterStatus !== "rejected")
    ) {
      console.log(
        "[notifyDealerOnOfferResponse] No relevant status change for dealer notification"
      );
      return;
    }

    console.log(
      `[notifyDealerOnOfferResponse] Offer ${afterStatus} by transporter`
    );

    try {
      // Get dealer details
      const dealerDoc = await db.collection("users").doc(after.dealerId).get();

      if (!dealerDoc.exists) {
        console.log(
          "[notifyDealerOnOfferResponse] Dealer not found:",
          after.dealerId
        );
        return;
      }

      const dealerData = dealerDoc.data();

      if (!dealerData.fcmToken) {
        console.log(
          "[notifyDealerOnOfferResponse] Dealer has no FCM token:",
          after.dealerId
        );
        return;
      }

      // Get vehicle details
      const vehicleDoc = await db
        .collection("vehicles")
        .doc(after.vehicleId)
        .get();

      if (!vehicleDoc.exists) {
        console.log(
          "[notifyDealerOnOfferResponse] Vehicle not found:",
          after.vehicleId
        );
        return;
      }

      const vehicleData = vehicleDoc.data();

      // Get transporter details for personalized message
      const transporterDoc = await db
        .collection("users")
        .doc(vehicleData.userId)
        .get();

      let transporterName = "The transporter";
      if (transporterDoc.exists) {
        const transporterData = transporterDoc.data();
        transporterName =
          `${transporterData.firstName || ""} ${
            transporterData.lastName || ""
          }`.trim() ||
          transporterData.companyName ||
          "The transporter";
      }

      // Format the offer amount
      const formattedAmount = new Intl.NumberFormat("en-ZA", {
        style: "currency",
        currency: "ZAR",
        minimumFractionDigits: 0,
      }).format(after.offerAmount);

      // Create vehicle description
      const vehicleName = `${
        vehicleData.brands?.join(", ") || vehicleData.brand || "Vehicle"
      } ${vehicleData.makeModel || vehicleData.model || ""} ${
        vehicleData.year || ""
      }`.trim();

      // Create notification based on response
      let title = "";
      let body = "";

      if (afterStatus === "accepted") {
        title = "Offer Accepted! 🎉";
        body = `Great news! ${transporterName} has accepted your offer of ${formattedAmount} for the ${vehicleName}.`;
      } else if (afterStatus === "rejected") {
        title = "Offer Declined";
        body = `${transporterName} has declined your offer of ${formattedAmount} for the ${vehicleName}.`;
      }

      // Send push notification to dealer
      const message = {
        notification: {
          title: title,
          body: body,
        },
        data: {
          vehicleId: after.vehicleId,
          offerId: offerId,
          transporterId: vehicleData.userId,
          offerAmount: after.offerAmount.toString(),
          offerStatus: afterStatus,
          notificationType: "offer_response",
          timestamp: new Date().toISOString(),
        },
        token: dealerData.fcmToken,
      };

      await admin.messaging().send(message);
      console.log(
        `[notifyDealerOnOfferResponse] Notification sent to dealer ${after.dealerId} for offer response: ${afterStatus}`
      );

      // Notify admins when an offer is accepted
      if (afterStatus === "accepted") {
        try {
          // Get all admin users
          const adminUsersSnapshot = await db
            .collection("users")
            .where("userRole", "in", ["admin", "sales representative"])
            .get();

          if (!adminUsersSnapshot.empty) {
            for (const adminDoc of adminUsersSnapshot.docs) {
              const adminData = adminDoc.data();

              if (!adminData.fcmToken) {
                console.log(
                  `[notifyDealerOnOfferResponse] Admin ${adminDoc.id} has no FCM token`
                );
                continue;
              }

              // Get dealer name for admin notification
              let dealerCompanyName = "Unknown Dealer";
              if (dealerData.companyName) {
                dealerCompanyName = dealerData.companyName;
              } else if (dealerData.firstName || dealerData.lastName) {
                dealerCompanyName = `${dealerData.firstName || ""} ${
                  dealerData.lastName || ""
                }`.trim();
              }

              const adminMessage = {
                notification: {
                  title: "Offer Accepted 💰",
                  body: `${dealerCompanyName} and ${transporterName} agreed on ${formattedAmount} for ${vehicleName}.`,
                },
                data: {
                  vehicleId: after.vehicleId,
                  offerId: offerId,
                  transporterId: vehicleData.userId,
                  dealerId: after.dealerId,
                  offerAmount: after.offerAmount.toString(),
                  offerStatus: afterStatus,
                  notificationType: "offer_accepted_admin",
                  timestamp: new Date().toISOString(),
                },
                token: adminData.fcmToken,
              };

              await admin.messaging().send(adminMessage);
              console.log(
                `[notifyDealerOnOfferResponse] Admin notification sent to ${adminDoc.id} for accepted offer`
              );
            }
          }
        } catch (adminError) {
          console.error(
            "[notifyDealerOnOfferResponse] Error notifying admins:",
            adminError
          );
        }
      }
    } catch (error) {
      console.error("[notifyDealerOnOfferResponse] Error:", error);
    }
  }
);

// Notify both transporter and dealer when a sale is completed
exports.notifyPartiesOnSaleCompletion = onDocumentUpdated(
  {
    document: "offers/{offerId}",
    region: "us-central1",
  },
  async (event) => {
    console.log(
      "[notifyPartiesOnSaleCompletion] Triggered for offerId:",
      event.params.offerId
    );

    const before = event.data.before.data();
    const after = event.data.after.data();
    const offerId = event.params.offerId;

    if (!before || !after) {
      console.log("[notifyPartiesOnSaleCompletion] No before/after data");
      return;
    }

    // Check if status changed to completed/sold/collected
    const beforeStatus = before.offerStatus?.toLowerCase() || "";
    const afterStatus = after.offerStatus?.toLowerCase() || "";

    if (
      beforeStatus === afterStatus ||
      (afterStatus !== "completed" &&
        afterStatus !== "sold" &&
        afterStatus !== "collected")
    ) {
      console.log(
        "[notifyPartiesOnSaleCompletion] No sale completion status change detected"
      );
      return;
    }

    console.log(
      `[notifyPartiesOnSaleCompletion] Sale completed for offer ${offerId}`
    );

    try {
      // Get vehicle details
      const vehicleDoc = await db
        .collection("vehicles")
        .doc(after.vehicleId)
        .get();

      if (!vehicleDoc.exists) {
        console.log(
          "[notifyPartiesOnSaleCompletion] Vehicle not found:",
          after.vehicleId
        );
        return;
      }

      const vehicleData = vehicleDoc.data();

      // Get dealer details
      const dealerDoc = await db.collection("users").doc(after.dealerId).get();

      if (!dealerDoc.exists) {
        console.log(
          "[notifyPartiesOnSaleCompletion] Dealer not found:",
          after.dealerId
        );
        return;
      }

      const dealerData = dealerDoc.data();

      // Get transporter details
      const transporterDoc = await db
        .collection("users")
        .doc(vehicleData.userId)
        .get();

      if (!transporterDoc.exists) {
        console.log(
          "[notifyPartiesOnSaleCompletion] Transporter not found:",
          vehicleData.userId
        );
        return;
      }

      const transporterData = transporterDoc.data();

      // Format the sale amount
      const formattedAmount = new Intl.NumberFormat("en-ZA", {
        style: "currency",
        currency: "ZAR",
        minimumFractionDigits: 0,
      }).format(after.offerAmount);

      // Create vehicle description
      const vehicleName = `${
        vehicleData.brands?.join(", ") || vehicleData.brand || "Vehicle"
      } ${vehicleData.makeModel || vehicleData.model || ""} ${
        vehicleData.year || ""
      }`.trim();

      // Get names for personalization
      const dealerName =
        `${dealerData.firstName || ""} ${dealerData.lastName || ""}`.trim() ||
        dealerData.companyName ||
        "the dealer";

      const transporterName =
        `${transporterData.firstName || ""} ${
          transporterData.lastName || ""
        }`.trim() ||
        transporterData.companyName ||
        "the transporter";

      // Notify the transporter (seller)
      if (transporterData.fcmToken) {
        try {
          const transporterMessage = {
            notification: {
              title: "🎉 Congratulations on Your Sale!",
              body: `Your ${vehicleName} has been sold for ${formattedAmount}. Well done on completing the deal!`,
            },
            data: {
              vehicleId: after.vehicleId,
              offerId: offerId,
              dealerId: after.dealerId,
              offerAmount: after.offerAmount.toString(),
              offerStatus: afterStatus,
              notificationType: "sale_completion_transporter",
              timestamp: new Date().toISOString(),
            },
            token: transporterData.fcmToken,
          };

          await admin.messaging().send(transporterMessage);
          console.log(
            `[notifyPartiesOnSaleCompletion] Sale completion notification sent to transporter ${vehicleData.userId}`
          );
        } catch (transporterError) {
          console.error(
            "[notifyPartiesOnSaleCompletion] Error notifying transporter:",
            transporterError
          );
        }
      } else {
        console.log(
          `[notifyPartiesOnSaleCompletion] Transporter ${vehicleData.userId} has no FCM token`
        );
      }

      // Notify the dealer (buyer)
      if (dealerData.fcmToken) {
        try {
          const dealerMessage = {
            notification: {
              title: "🎉 Congratulations on Your Purchase!",
              body: `You have successfully purchased the ${vehicleName} from ${transporterName} for ${formattedAmount}. Enjoy your new vehicle!`,
            },
            data: {
              vehicleId: after.vehicleId,
              offerId: offerId,
              transporterId: vehicleData.userId,
              offerAmount: after.offerAmount.toString(),
              offerStatus: afterStatus,
              notificationType: "sale_completion_dealer",
              timestamp: new Date().toISOString(),
            },
            token: dealerData.fcmToken,
          };

          await admin.messaging().send(dealerMessage);
          console.log(
            `[notifyPartiesOnSaleCompletion] Sale completion notification sent to dealer ${after.dealerId}`
          );
        } catch (dealerError) {
          console.error(
            "[notifyPartiesOnSaleCompletion] Error notifying dealer:",
            dealerError
          );
        }
      } else {
        console.log(
          `[notifyPartiesOnSaleCompletion] Dealer ${after.dealerId} has no FCM token`
        );
      }

      // Send email notifications if available
      const transporterEmail = transporterData.email;
      const dealerEmail = dealerData.email;

      // Send email to transporter
      if (transporterEmail && sgMail) {
        try {
          await sgMail.send({
            from: "admin@ctpapp.co.za",
            to: transporterEmail,
            subject: "🎉 Congratulations! Your Vehicle Has Been Sold",
            html: `
              <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto;">
                <h2 style="color: #2F7FFF;">Congratulations on Your Successful Sale! 🎉</h2>
                <p>Dear ${transporterName},</p>
                <p>We're thrilled to inform you that your <strong>${vehicleName}</strong> has been successfully sold!</p>
                
                <div style="background-color: #f8f9fa; padding: 20px; border-radius: 8px; margin: 20px 0;">
                  <h3 style="margin-top: 0; color: #333;">Sale Details:</h3>
                  <p><strong>Vehicle:</strong> ${vehicleName}</p>
                  <p><strong>Sale Price:</strong> ${formattedAmount}</p>
                  <p><strong>Sale Date:</strong> ${new Date().toLocaleDateString()}</p>
                </div>
                
                <p>Thank you for using Commercial Trader Portal for your vehicle sale. We hope you had a great experience with our platform.</p>
                <p>We look forward to helping you with future vehicle transactions!</p>
                
                <p>Best regards,<br>
                The Commercial Trader Portal Team</p>
              </div>
            `,
          });
          console.log(
            `[notifyPartiesOnSaleCompletion] Sale completion email sent to transporter`
          );
        } catch (emailError) {
          console.error(
            "[notifyPartiesOnSaleCompletion] Error sending email to transporter:",
            emailError
          );
        }
      }

      // Send email to dealer
      if (dealerEmail && sgMail) {
        try {
          await sgMail.send({
            from: "admin@ctpapp.co.za",
            to: dealerEmail,
            subject: "🎉 Congratulations! Your Vehicle Purchase is Complete",
            html: `
              <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto;">
                <h2 style="color: #2F7FFF;">Congratulations on Your Successful Purchase! 🎉</h2>
                <p>Dear ${dealerName},</p>
                <p>We're excited to confirm that your purchase of the <strong>${vehicleName}</strong> has been completed!</p>
                
                <div style="background-color: #f8f9fa; padding: 20px; border-radius: 8px; margin: 20px 0;">
                  <h3 style="margin-top: 0; color: #333;">Purchase Details:</h3>
                  <p><strong>Vehicle:</strong> ${vehicleName}</p>
                  <p><strong>Purchase Price:</strong> ${formattedAmount}</p>
                  <p><strong>Purchase Date:</strong> ${new Date().toLocaleDateString()}</p>
                </div>
                
                <p>Thank you for choosing Commercial Trader Portal for your vehicle purchase. We hope you enjoy your new vehicle!</p>
                <p>We look forward to serving you again in the future.</p>
                
                <p>Best regards,<br>
                The Commercial Trader Portal Team</p>
              </div>
            `,
          });
          console.log(
            `[notifyPartiesOnSaleCompletion] Sale completion email sent to dealer`
          );
        } catch (emailError) {
          console.error(
            "[notifyPartiesOnSaleCompletion] Error sending email to dealer:",
            emailError
          );
        }
      }

      // Update vehicle status to sold if not already done
      try {
        await db.collection("vehicles").doc(after.vehicleId).update({
          vehicleStatus: "sold",
          soldDate: admin.firestore.FieldValue.serverTimestamp(),
          soldPrice: after.offerAmount,
        });
        console.log(
          `[notifyPartiesOnSaleCompletion] Vehicle ${after.vehicleId} marked as sold`
        );
      } catch (updateError) {
        console.error(
          "[notifyPartiesOnSaleCompletion] Error updating vehicle status:",
          updateError
        );
      }
    } catch (error) {
      console.error("[notifyPartiesOnSaleCompletion] Error:", error);
    }
  }
);

// Notify admins when live vehicle information is updated
exports.notifyAdminsOnLiveVehicleUpdate = onDocumentUpdated(
  {
    document: "vehicles/{vehicleId}",
    region: "us-central1",
  },
  async (event) => {
    console.log(
      "[notifyAdminsOnLiveVehicleUpdate] Triggered for vehicleId:",
      event.params.vehicleId
    );

    // Disabled: Do not send notifications when a live vehicle is edited.
    // Rationale: Users were receiving notifications on every edit of a live vehicle.
    // Status-change notifications (e.g., to "live" or "pending") are handled elsewhere.
    console.log(
      "[notifyAdminsOnLiveVehicleUpdate] Disabled – suppressing notifications for live vehicle edits"
    );
    return;

    const before = event.data.before.data();
    const after = event.data.after.data();
    const vehicleId = event.params.vehicleId;

    if (!before || !after) {
      console.log("[notifyAdminsOnLiveVehicleUpdate] No before/after data");
      return;
    }

    // Check if vehicle was or is live
    const beforeStatus = before.vehicleStatus?.toLowerCase() || "";
    const afterStatus = after.vehicleStatus?.toLowerCase() || "";

    const wasLive = beforeStatus === "live";
    const isLive = afterStatus === "live";

    if (!wasLive && !isLive) {
      console.log(
        "[notifyAdminsOnLiveVehicleUpdate] Vehicle was never live, skipping notification"
      );
      return;
    }

    // Define fields to monitor for changes
    const monitoredFields = [
      "sellingPrice",
      "expectedSellingPrice",
      "mainImageUrl",
      "photos",
      "makeModel",
      "year",
      "mileage",
      "transmissionType",
      "suspensionType",
      "config",
      "application",
      "brands",
      "variant",
      "additionalFeatures",
      "damagesDescription",
      "hydraulics",
      "warranty",
      "warrantyDetails",
    ];

    // Check if any monitored fields have changed
    let changedFields = [];
    let significantChanges = [];

    for (const field of monitoredFields) {
      const beforeValue = JSON.stringify(before[field] || "");
      const afterValue = JSON.stringify(after[field] || "");

      if (beforeValue !== afterValue) {
        changedFields.push(field);

        // Track significant changes for the notification
        if (field === "sellingPrice" || field === "expectedSellingPrice") {
          const beforePrice = before[field] || "";
          const afterPrice = after[field] || "";
          significantChanges.push(
            `Price changed from R${beforePrice} to R${afterPrice}`
          );
        } else if (field === "mainImageUrl") {
          significantChanges.push("Main image updated");
        } else if (field === "photos") {
          const beforeCount = (before[field] || []).length;
          const afterCount = (after[field] || []).length;
          significantChanges.push(
            `Photos updated (${beforeCount} → ${afterCount} images)`
          );
        } else if (field === "makeModel") {
          significantChanges.push(
            `Make/Model changed from "${before[field]}" to "${after[field]}"`
          );
        } else if (field === "mileage") {
          significantChanges.push(
            `Mileage updated from ${before[field]} to ${after[field]}`
          );
        } else {
          significantChanges.push(`${field} updated`);
        }
      }
    }

    // If no monitored fields changed, don't notify
    if (changedFields.length === 0) {
      console.log(
        "[notifyAdminsOnLiveVehicleUpdate] No significant changes detected"
      );
      return;
    }

    console.log(
      `[notifyAdminsOnLiveVehicleUpdate] Detected changes in: ${changedFields.join(
        ", "
      )}`
    );

    try {
      // Get vehicle owner details for context
      const transporterDoc = await db
        .collection("users")
        .doc(after.userId)
        .get();

      let transporterName = "Unknown Transporter";
      let transporterEmail = null;

      if (transporterDoc.exists) {
        const transporterData = transporterDoc.data();
        transporterName =
          `${transporterData.firstName || ""} ${
            transporterData.lastName || ""
          }`.trim() ||
          transporterData.companyName ||
          "Unknown Transporter";
        transporterEmail = transporterData.email;
      }

      // Create vehicle description
      const vehicleName = `${
        after.brands?.join(", ") || after.brand || "Vehicle"
      } ${after.makeModel || after.model || ""} ${after.year || ""}`.trim();

      // Get all admin users
      const adminUsersSnapshot = await db
        .collection("users")
        .where("userRole", "in", ["admin", "sales representative"])
        .get();

      if (adminUsersSnapshot.empty) {
        console.log("[notifyAdminsOnLiveVehicleUpdate] No admin users found");
        return;
      }

      // Prepare notification content
      const changesText =
        significantChanges.length > 3
          ? `${significantChanges.slice(0, 3).join(", ")} and ${
              significantChanges.length - 3
            } more changes`
          : significantChanges.join(", ");

      // Send push notifications to admins
      for (const adminDoc of adminUsersSnapshot.docs) {
        const adminData = adminDoc.data();

        if (!adminData.fcmToken) {
          console.log(
            `[notifyAdminsOnLiveVehicleUpdate] Admin ${adminDoc.id} has no FCM token`
          );
          continue;
        }

        try {
          const message = {
            notification: {
              title: "📝 Live Vehicle Updated",
              body: `${transporterName} updated their ${vehicleName}. Changes: ${changesText}`,
            },
            data: {
              vehicleId: vehicleId,
              transporterId: after.userId,
              notificationType: "live_vehicle_update",
              changedFields: JSON.stringify(changedFields),
              vehicleStatus: afterStatus,
              timestamp: new Date().toISOString(),
            },
            token: adminData.fcmToken,
          };

          await admin.messaging().send(message);
          console.log(
            `[notifyAdminsOnLiveVehicleUpdate] Notification sent to admin ${adminDoc.id}`
          );
        } catch (adminError) {
          console.error(
            `[notifyAdminsOnLiveVehicleUpdate] Error sending notification to admin ${adminDoc.id}:`,
            adminError
          );
        }
      }

      // Send email notifications to admins
      const adminEmails = adminUsersSnapshot.docs
        .map((doc) => doc.data().email)
        .filter((email) => !!email);

      if (adminEmails.length > 0 && sgMail) {
        try {
          const currentPrice =
            after.sellingPrice || after.expectedSellingPrice || "N/A";
          const vehicleLink = `https://ctpapp.co.za/vehicle/${vehicleId}`;

          await sgMail.send({
            from: "admin@ctpapp.co.za",
            to: adminEmails,
            subject: `🔄 Live Vehicle Updated - ${vehicleName}`,
            html: `
              <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto;">
                <h2 style="color: #2F7FFF;">Live Vehicle Listing Updated 📝</h2>
                <p>A live vehicle listing has been updated and may require your review.</p>
                
                <div style="background-color: #f8f9fa; padding: 20px; border-radius: 8px; margin: 20px 0;">
                  <h3 style="margin-top: 0; color: #333;">Vehicle Details:</h3>
                  <p><strong>Vehicle:</strong> ${vehicleName}</p>
                  <p><strong>Current Price:</strong> R${currentPrice}</p>
                  <p><strong>Reference:</strong> ${
                    after.referenceNumber || vehicleId
                  }</p>
                  <p><strong>Updated by:</strong> ${transporterName}</p>
                  <p><strong>Status:</strong> ${afterStatus.toUpperCase()}</p>
                </div>
                
                <div style="background-color: #fff3cd; padding: 15px; border-radius: 8px; margin: 20px 0; border-left: 4px solid #ffc107;">
                  <h4 style="margin-top: 0; color: #856404;">Changes Made:</h4>
                  <ul style="margin: 10px 0; padding-left: 20px;">
                    ${significantChanges
                      .map((change) => `<li>${change}</li>`)
                      .join("")}
                  </ul>
                </div>
                
                <div style="text-align: center; margin: 30px 0;">
                  <a href="${vehicleLink}" 
                     style="background-color: #2F7FFF; color: white; padding: 12px 24px; text-decoration: none; border-radius: 5px; display: inline-block;">
                    Review Vehicle Listing
                  </a>
                </div>
                
                <p style="color: #666; font-size: 14px;">
                  Please review these changes to ensure they comply with platform standards and approve if necessary.
                </p>
                
                <p>Best regards,<br>
                Commercial Trader Portal System</p>
              </div>
            `,
          });

          console.log(
            `[notifyAdminsOnLiveVehicleUpdate] Email notification sent to ${adminEmails.length} admins`
          );
        } catch (emailError) {
          console.error(
            "[notifyAdminsOnLiveVehicleUpdate] Error sending email notifications:",
            emailError
          );
        }
      }
    } catch (error) {
      console.error("[notifyAdminsOnLiveVehicleUpdate] Error:", error);
    }
  }
);

// New function to notify admins when a new user is created
exports.notifyAdminsOnNewUser = onDocumentCreated(
  {
    document: "users/{userId}",
    region: "us-central1",
  },
  async (event) => {
    const snap = event.data;
    if (!snap) {
      console.log("No data associated with the event");
      return;
    }

    const userData = snap.data();
    const userId = event.params.userId;

    console.log(
      `New ${userData.userRole} registered: ${userData.firstName} ${userData.lastName}`
    );

    try {
      // Get all admin users
      const adminUsersSnapshot = await db
        .collection("users")
        .where("userRole", "in", ["admin", "sales representative"])
        .get();

      if (adminUsersSnapshot.empty) {
        console.log("No admin users found to notify");
        return;
      }

      const companyName = userData.companyName || "N/A";
      const userFullName =
        `${userData.firstName || ""} ${userData.lastName || ""}`.trim() ||
        "New user";

      // Send notification to each admin using admin.messaging().send(...)
      for (const adminDoc of adminUsersSnapshot.docs) {
        const adminData = adminDoc.data();

        if (!adminData.fcmToken) {
          console.log(`Admin ${adminDoc.id} has no FCM token`);
          continue;
        }

        const message = {
          notification: {
            title: `New ${userData.userRole} Registration`,
            body: `${userFullName} has registered as a ${userData.userRole}.`,
          },
          data: {
            userId: userId,
            notificationType: "new_user_registration",
            userRole: userData.userRole,
            timestamp: new Date().toISOString(),
          },
          token: adminData.fcmToken,
        };

        try {
          await admin.messaging().send(message);
          console.log(`Notification sent to admin ${adminDoc.id}`);
        } catch (error) {
          console.error(
            `Error sending notification to admin ${adminDoc.id}:`,
            error
          );
        }
      }

      console.log("Admin notifications process completed");
    } catch (error) {
      console.error("Error in notifyAdminsOnNewUser function:", error);
    }
  }
);

// Function to notify admins when a user completes registration (updates their profile)
exports.notifyAdminsOnUserRegistrationComplete = onDocumentUpdated(
  {
    document: "users/{userId}",
    region: "us-central1",
  },
  async (event) => {
    const before = event.data.before.data();
    const after = event.data.after.data();
    const userId = event.params.userId;

    if (!before || !after) {
      console.log("No before/after data for user registration update");
      return;
    }

    // Check if this is a registration completion (key fields were added)
    const isRegistrationComplete =
      (after.userRole === "transporter" || after.userRole === "dealer") &&
      after.companyName &&
      after.registrationNumber &&
      after.vatNumber &&
      (!before.companyName || !before.registrationNumber || !before.vatNumber);

    if (!isRegistrationComplete) {
      return; // Not a registration completion, skip
    }

    console.log(
      `${after.userRole} registration completed: ${after.firstName} ${after.lastName} from ${after.companyName}`
    );

    try {
      // Get all admin users
      const adminUsersSnapshot = await db
        .collection("users")
        .where("userRole", "in", ["admin", "sales representative"])
        .get();

      if (adminUsersSnapshot.empty) {
        console.log("No admin users found to notify");
        return;
      }

      const companyName = after.companyName || "N/A";
      const userFullName =
        `${after.firstName || ""} ${after.lastName || ""}`.trim() || "New user";

      // Send notification to each admin
      for (const adminDoc of adminUsersSnapshot.docs) {
        const adminData = adminDoc.data();

        if (!adminData.fcmToken) {
          console.log(`Admin ${adminDoc.id} has no FCM token`);
          continue;
        }

        const message = {
          notification: {
            title: `${after.userRole} Registration Completed`,
            body: `${userFullName} from ${companyName} has completed their ${after.userRole} registration and is awaiting approval.`,
          },
          data: {
            userId: userId,
            notificationType: "registration_completed",
            userRole: after.userRole,
            timestamp: new Date().toISOString(),
          },
          token: adminData.fcmToken,
        };

        try {
          await admin.messaging().send(message);
          console.log(
            `Registration completion notification sent to admin ${adminDoc.id}`
          );
        } catch (error) {
          console.error(
            `Error sending registration completion notification to admin ${adminDoc.id}:`,
            error
          );
        }
      }

      // Email notifications disabled - only using push notifications for now
      console.log("Email notifications skipped - only push notifications sent");

      console.log("Registration completion notifications process completed");
    } catch (error) {
      console.error(
        "Error in notifyAdminsOnUserRegistrationComplete function:",
        error
      );
    }
  }
);

// Notify dealers and admins when a vehicle is created or updated (live or pending)
exports.notifyDealersAndAdminsOnVehicleChange = onDocumentCreated(
  {
    document: "vehicles/{vehicleId}",
    region: "us-central1",
  },
  async (event) => {
    console.log(
      "[notifyDealersAndAdminsOnVehicleChange] Triggered for vehicleId:",
      event.params.vehicleId
    );
    const snap = event.data;
    if (!snap) {
      console.log("[notifyDealersAndAdminsOnVehicleChange] No snapshot data");
      return;
    }
    const vehicleData = snap.data();
    const vehicleId = event.params.vehicleId;
    console.log(
      "[notifyDealersAndAdminsOnVehicleChange] vehicleData:",
      vehicleData
    );

    // Notify dealers if live
    if (
      vehicleData.vehicleStatus &&
      vehicleData.vehicleStatus.toLowerCase() === "live"
    ) {
      try {
        // Get the brand and model correctly from the vehicle data
        const brand =
          vehicleData.brands?.length > 0 ? vehicleData.brands[0] : "Vehicle";
        const makeModel = vehicleData.makeModel || "";
        const year = vehicleData.year || "";

        const vehicleDescription = `${brand} ${makeModel} ${year}`.trim();

        const message = {
          notification: {
            title: "New Truck Available",
            body: `A ${vehicleDescription} is now available.`,
          },
          data: {
            vehicleId: vehicleId,
            notificationType: "new_vehicle",
            vehicleType: vehicleData.vehicleType || "truck",
            timestamp: new Date().toISOString(),
          },
          topic: "newVehicles",
        };
        console.log(
          "[notifyDealersAndAdminsOnVehicleChange] Sending FCM topic message:",
          message
        );
        await admin.messaging().send(message);
        console.log(
          "Notification sent to all dealers subscribed to newVehicles topic"
        );
      } catch (error) {
        console.error("Error sending new vehicle notification:", error);
      }
    }

    // Notify admins if pending
    if (
      vehicleData.vehicleStatus &&
      vehicleData.vehicleStatus.toLowerCase() === "pending"
    ) {
      try {
        // Send push notification to all admins
        const adminUsersSnapshot = await db
          .collection("users")
          .where("userRole", "in", ["admin", "sales representative"])
          .get();
        console.log(
          `[notifyDealersAndAdminsOnVehicleChange] Found ${adminUsersSnapshot.size} admin users`
        );
        for (const adminDoc of adminUsersSnapshot.docs) {
          const adminData = adminDoc.data();
          if (!adminData.fcmToken) {
            console.log(
              `[notifyDealersAndAdminsOnVehicleChange] Admin ${adminDoc.id} has no FCM token`
            );
            continue;
          }
          const message = {
            notification: {
              title: "Vehicle Pending Approval",
              body:
                "A vehicle (" +
                (vehicleData.brand || "") +
                " " +
                (vehicleData.model || "") +
                ") is pending admin approval.",
              // clickAction: "FLUTTER_NOTIFICATION_CLICK", // REMOVED for FCM v2 compatibility
            },
            data: {
              vehicleId: vehicleId,
              notificationType: "vehicle_pending_approval",
              timestamp: new Date().toISOString(),
            },
            token: adminData.fcmToken,
          };
          console.log(
            `[notifyDealersAndAdminsOnVehicleChange] Sending FCM to admin ${adminDoc.id}:`,
            message
          );
          try {
            await admin.messaging().send(message);
            console.log(
              `[notifyDealersAndAdminsOnVehicleChange] Notification sent to admin ${adminDoc.id}`
            );
          } catch (err) {
            console.error(
              "Error sending pending approval notification to admin " +
                adminDoc.id +
                ":",
              err
            );
          }
        }
        // Send email to all admin users via SendGrid
        const adminEmailSnapshot = await db
          .collection("users")
          .where("userRole", "in", ["admin", "sales representative"])
          .get();
        const adminEmails = adminEmailSnapshot.docs
          .map((doc) => doc.data().email)
          .filter((email) => !!email);
        if (adminEmails.length > 0) {
          const today = new Date().toLocaleDateString();
          // Fetch user’s name and company for email template
          const transporterDoc = await db
            .collection("users")
            .doc(vehicleData.userId)
            .get();
          let transporterName = "N/A";
          if (transporterDoc.exists) {
            const data = transporterDoc.data();
            transporterName = `${data.firstName || ""} ${
              data.lastName || ""
            }`.trim();
            if (data.companyName) {
              transporterName += ` from ${data.companyName}`;
            }
          }
          // Use SendGrid dynamic template for pending approval
          const emailMsg = {
            to: adminEmails, // send to all admin email addresses
            from: "admin@ctpapp.co.za",
            templateId: process.env.SENDGRID_TEMPLATE_ID.trim(),
            dynamic_template_data: {
              // pull brand from the first element of your brands array (or fallback)
              brand:
                vehicleData.brands?.[0] ||
                vehicleData.modelDetails?.manufacturer ||
                "N/A",

              // model lives under modelDetails.model or makeModel
              model:
                vehicleData.modelDetails?.model ||
                vehicleData.makeModel ||
                "N/A",

              // you already have variant at top level
              variant: vehicleData.variant || "N/A",

              // year is either nested or top-level
              year: vehicleData.modelDetails?.year || vehicleData.year || "N/A",

              // transporter full name for template
              transporter: transporterName,

              date: today,

              vehicleLink: `https://ctpapp.co.za/vehicle/${vehicleId}`,
              content: `A new vehicle (${
                vehicleData.brands?.[0] ||
                vehicleData.modelDetails?.manufacturer ||
                "N/A"
              } ${
                vehicleData.modelDetails?.model ||
                vehicleData.makeModel ||
                "N/A"
              }, ${
                vehicleData.modelDetails?.year || vehicleData.year || "N/A"
              }) is pending approval.`,
              // THIS WAS MISSING — must match {{imageUrl}}
              imageUrl: vehicleData.mainImageUrl || "",
            },
          };
          console.log(
            "[notifyDealersAndAdminsOnVehicleChange] Sending SendGrid dynamic template email"
          );
          await sgMail.send(emailMsg);
          console.log(
            "[notifyDealersAndAdminsOnVehicleChange] SendGrid dynamic template email sent"
          );
        } else {
          console.log(
            "[notifyDealersAndAdminsOnVehicleChange] No admin emails found for SendGrid"
          );
        }
      } catch (error) {
        console.error(
          "Error in notifyDealersAndAdminsOnVehicleChange function (pending):",
          error
        );
      }
    }
  }
);

exports.notifyDealersAndAdminsOnVehicleChangeUpdate = onDocumentUpdated(
  {
    document: "vehicles/{vehicleId}",
    region: "us-central1",
  },
  async (event) => {
    console.log(
      "[notifyDealersAndAdminsOnVehicleChangeUpdate] Triggered for vehicleId:",
      event.params.vehicleId
    );
    const before = event.data.before.data();
    const after = event.data.after.data();
    const vehicleId = event.params.vehicleId;
    if (!before || !after) {
      console.log(
        "[notifyDealersAndAdminsOnVehicleChangeUpdate] No before/after data"
      );
      return;
    }
    console.log(
      "[notifyDealersAndAdminsOnVehicleChangeUpdate] before:",
      before
    );
    console.log("[notifyDealersAndAdminsOnVehicleChangeUpdate] after:", after);
    // Notify dealers if status changed to live
    if (
      before.vehicleStatus !== "live" &&
      after.vehicleStatus &&
      after.vehicleStatus.toLowerCase() === "live"
    ) {
      try {
        // Get the brand and model correctly from the vehicle data
        const brand = after.brands?.length > 0 ? after.brands[0] : "Vehicle";
        const makeModel = after.makeModel || "";
        const year = after.year || "";

        const vehicleDescription = `${brand} ${makeModel} ${year}`.trim();

        const message = {
          notification: {
            title: "New Truck Available",
            body: `A ${vehicleDescription} is now available.`,
          },
          data: {
            vehicleId: vehicleId,
            notificationType: "new_vehicle",
            vehicleType: after.vehicleType || "truck",
            timestamp: new Date().toISOString(),
          },
          topic: "newVehicles",
        };
        console.log(
          "[notifyDealersAndAdminsOnVehicleChangeUpdate] Sending FCM topic message:",
          message
        );
        await admin.messaging().send(message);
        console.log(
          "[UPDATE] Notification sent to all dealers subscribed to newVehicles topic"
        );
      } catch (error) {
        console.error(
          "[UPDATE] Error sending new vehicle notification:",
          error
        );
      }
    }
    // Notify admins if status changed to pending
    if (
      before.vehicleStatus !== "pending" &&
      after.vehicleStatus &&
      after.vehicleStatus.toLowerCase() === "pending"
    ) {
      try {
        const adminUsersSnapshot = await db
          .collection("users")
          .where("userRole", "in", ["admin", "sales representative"])
          .get();
        console.log(
          `[notifyDealersAndAdminsOnVehicleChangeUpdate] Found ${adminUsersSnapshot.size} admin users`
        );
        for (const adminDoc of adminUsersSnapshot.docs) {
          const adminData = adminDoc.data();
          if (!adminData.fcmToken) {
            console.log(
              `[notifyDealersAndAdminsOnVehicleChangeUpdate] Admin ${adminDoc.id} has no FCM token`
            );
            continue;
          }
          const message = {
            notification: {
              title: "Vehicle Pending Approval",
              body:
                "A vehicle " +
                (after.brands?.[0] || after.modelDetails?.manufacturer || "") +
                " " +
                (after.makeModel || after.modelDetails?.model || "") +
                " is pending admin approval.",
              // clickAction removed for FCM v2 compatibility
            },
            data: {
              vehicleId: vehicleId,
              notificationType: "vehicle_pending_approval",
              timestamp: new Date().toISOString(),
            },
            token: adminData.fcmToken,
          };
          console.log(
            `[notifyDealersAndAdminsOnVehicleChangeUpdate] Sending FCM to admin ${adminDoc.id}:`,
            message
          );
          try {
            await admin.messaging().send(message);
            console.log(
              `[notifyDealersAndAdminsOnVehicleChangeUpdate] Notification sent to admin ${adminDoc.id}`
            );
          } catch (err) {
            console.error(
              "[UPDATE] Error sending pending approval notification to admin " +
                adminDoc.id +
                ":",
              err
            );
          }
        }
        // Send email to all admin users via SendGrid
        const adminEmailSnapshot2 = await db
          .collection("users")
          .where("userRole", "in", ["admin", "sales representative"])
          .get();
        const adminEmails2 = adminEmailSnapshot2.docs
          .map((doc) => doc.data().email)
          .filter((email) => !!email);
        if (adminEmails2.length > 0) {
          const today = new Date().toLocaleDateString();
          // Safely fetch user’s name and company for email template update
          let transporterName = "N/A";
          if (after.userId) {
            const docRef = db.collection("users").doc(after.userId);
            const transporterDoc = await docRef.get();
            if (transporterDoc.exists) {
              const data = transporterDoc.data();
              transporterName =
                `${data.firstName || ""} ${data.lastName || ""}`.trim() ||
                "N/A";
              if (data.companyName) {
                transporterName += ` from ${data.companyName}`;
              }
            }
          }
          // Use SendGrid dynamic template for pending approval update
          const emailMsg2 = {
            to: adminEmails2, // send update emails to all admin addresses
            from: "admin@ctpapp.co.za",
            templateId: process.env.SENDGRID_TEMPLATE_ID.trim(), // updated for v2 compatibility
            dynamic_template_data: {
              brand:
                Array.isArray(after.brands) && after.brands.length > 0
                  ? after.brands[0]
                  : "N/A",
              model: after.makeModel || "N/A",
              variant: after.variant || "N/A",
              year: after.year || "N/A",
              transporter: transporterName,
              date: today,
              vehicleLink: `https://ctpapp.co.za/vehicle/${vehicleId}`,
              content: `A new vehicle (${
                Array.isArray(after.brands) && after.brands.length > 0
                  ? after.brands[0]
                  : "N/A"
              } ${after.makeModel || "N/A"}, ${
                after.year || "N/A"
              }) is pending approval.`,
              imageUrl: after.mainImageUrl || "", // renamed to match {{imageUrl}} in template
            },
          };
          console.log(
            "[notifyDealersAndAdminsOnVehicleChangeUpdate] Sending SendGrid dynamic template email"
          );
          await sgMail.send(emailMsg2);
          console.log(
            "[notifyDealersAndAdminsOnVehicleChangeUpdate] SendGrid dynamic template email sent"
          );
        } else {
          console.log(
            "[notifyDealersAndAdminsOnVehicleChangeUpdate] No admin emails found for SendGrid"
          );
        }
      } catch (error) {
        if (
          error.response &&
          error.response.body &&
          error.response.body.errors
        ) {
          console.error(
            "[UPDATE] SendGrid payload errors:",
            error.response.body.errors
          );
        } else {
          console.error(
            "[UPDATE] Unexpected error in notifyDealersAndAdminsOnVehicleChangeUpdate:",
            error
          );
        }
      }
    }
  }
);

// Direct notification function (callable from client for testing)
exports.sendDirectNotification = require("firebase-functions/v2/https").onCall(
  {
    region: "us-central1",
  },
  async (request) => {
    const { userId, title, body, data = {} } = request.data;

    if (!userId || !title || !body) {
      throw new Error(
        "Missing required parameters: userId, title, and body are required"
      );
    }

    try {
      // Get user's FCM token
      const userDoc = await db.collection("users").doc(userId).get();

      if (!userDoc.exists) {
        throw new Error("User not found");
      }

      const userData = userDoc.data();
      if (!userData.fcmToken) {
        throw new Error("User has no FCM token registered");
      }

      // Send notification
      const message = {
        notification: {
          title: title,
          body: body,
        },
        data: {
          ...data,
          timestamp: new Date().toISOString(),
        },
        token: userData.fcmToken,
      };

      await admin.messaging().send(message);
      return { success: true, message: "Notification sent successfully" };
    } catch (error) {
      console.error("Error sending direct notification:", error);
      throw new Error(`Failed to send notification: ${error.message}`);
    }
  }
);

// Additional specific notification for new vehicles
exports.sendNewVehicleNotification =
  require("firebase-functions/v2/https").onCall(
    {
      region: "us-central1",
    },
    async (request) => {
      const { vehicleId } = request.data;

      if (!vehicleId) {
        throw new Error("Missing required parameter: vehicleId");
      }

      try {
        // Get vehicle data
        const vehicleDoc = await db.collection("vehicles").doc(vehicleId).get();

        if (!vehicleDoc.exists) {
          throw new Error("Vehicle not found");
        }

        const vehicleData = vehicleDoc.data();

        // Get the brand and model correctly from the vehicle data
        const brand =
          vehicleData.brands?.length > 0 ? vehicleData.brands[0] : "Vehicle";
        const makeModel = vehicleData.makeModel || "";
        const year = vehicleData.year || "";

        const vehicleDescription = `${brand} ${makeModel} ${year}`.trim();

        // Send notification to all dealers through the topic
        const message = {
          notification: {
            title: "New Truck Available",
            body: `A ${vehicleDescription} is now available.`,
          },
          data: {
            vehicleId: vehicleId,
            notificationType: "new_vehicle",
            vehicleType: vehicleData.vehicleType || "truck",
            timestamp: new Date().toISOString(),
          },
          topic: "newVehicles",
        };

        await admin.messaging().send(message);
        return {
          success: true,
          message: "New vehicle notification sent to all dealers",
        };
      } catch (error) {
        console.error("Error sending new vehicle notification:", error);
        throw new Error(`Failed to send notification: ${error.message}`);
      }
    }
  );

// Special test function that doesn't require App Check
exports.sendDirectNotificationNoAppCheck =
  require("firebase-functions/v2/https").onCall(
    {
      region: "us-central1",
      enforceAppCheck: false, // Explicitly disable App Check for this function
    },
    async (request) => {
      const { userId, title, body, dataPayload = {} } = request.data;

      if (!userId || !title || !body) {
        throw new Error(
          "Missing required parameters: userId, title, and body are required"
        );
      }

      try {
        console.log(`Attempting to send test notification to user ${userId}`);

        // Get user's FCM token
        const userDoc = await db.collection("users").doc(userId).get();

        if (!userDoc.exists) {
          throw new Error("User not found");
        }

        const userData = userDoc.data();
        if (!userData.fcmToken) {
          throw new Error("User has no FCM token registered");
        }

        console.log(
          `Found FCM token for user: ${userData.fcmToken.substring(0, 20)}...`
        );

        // Send notification
        const message = {
          notification: {
            title: title,
            body: body,
          },
          data: {
            ...dataPayload,
            timestamp: new Date().toISOString(),
            isTestNotification: "true",
          },
          token: userData.fcmToken,
        };

        await admin.messaging().send(message);
        console.log("Test notification sent successfully");

        return {
          success: true,
          message: "Test notification sent successfully",
          timestamp: new Date().toISOString(),
        };
      } catch (error) {
        console.error("Error sending test notification:", error);
        throw new Error(`Failed to send test notification: ${error.message}`);
      }
    }
  );

// Dynamic SSR for vehicle link previews
app.get("/vehicle/:id", async (req, res) => {
  try {
    const snap = await db.collection("vehicles").doc(req.params.id).get();
    if (!snap.exists) return res.status(404).send("Vehicle not found");
    const v = snap.data();
    const title = `${v.manokeModel} • R${v.expectedSellingPrice}`;
    const desc = `${v.year} • ${v.mileage} km • ${
      v.transmission
    } • Accidents: ${v.accidentFree ? "None" : "Yes"}`;
    const img = v.mainImageUrl;
    const url = `https://ctpapp.co.za/vehicle/${req.params.id}`;
    res.set("Cache-Control", "public, max-age=300");
    return res.send(`<!doctype html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <title>${title}</title>
  <meta property="og:title" content="${title}" />
  <meta property="og:description" content="${desc}" />
  <meta property="og:image" content="${img}" />
  <meta property="og:url" content="${url}" />
  <meta name="twitter:card" content="summary_large_image" />
  <script defer src="/main.dart.js"></script>
</head>
<body></body>
</html>`);
  } catch (err) {
    console.error(err);
    res.status(500).send("Internal error");
  }
});

// Export Express app for hosting /vehicle/* SSR
exports.app = onRequest({ region: "us-central1" }, app);

// Test SendGrid integration endpoint
exports.testSendGridIntegration = onRequest(
  { region: "us-central1" },
  async (req, res) => {
    try {
      await sgMail.send({
        to: "bradley@reagency.co.za",
        from: "admin@ctpapp.co.za",
        subject: "🚀 SendGrid Integration OK",
        text: "If you see this, SendGrid is live in your Functions!",
      });
      console.log("SendGrid test email sent");
      res.send("✅ Sent");
    } catch (e) {
      console.error("SendGrid test failed:", e);
      res.status(500).send(`❌ Error: ${e.message}`);
    }
  }
);

// Email notification on vehicle approval
exports.onVehicleApproved = onDocumentUpdated(
  {
    document: "vehicles/{vehicleId}",
    region: "us-central1",
  },
  async (event) => {
    const before = event.data.before.data();
    const after = event.data.after.data();
    const context = event; // for param access

    // Capture and normalize status values with trimming
    const rawBeforeStatus = before.vehicleStatus || before.status || "";
    const rawAfterStatus = after.vehicleStatus || after.status || "";
    console.log(
      `[onVehicleApproved] Raw statuses for vehicle ${context.params.vehicleId}: before.vehicleStatus="${rawBeforeStatus}", before.status="${before.status}", after.vehicleStatus="${rawAfterStatus}", after.status="${after.status}"`
    );
    const beforeStatus = rawBeforeStatus.toLowerCase().trim();
    const afterStatus = rawAfterStatus.toLowerCase().trim();
    console.log(
      `[onVehicleApproved] Condition check for vehicle ${context.params.vehicleId}: ` +
        `beforeStatus!=="approved"=${beforeStatus !== "approved"}, ` +
        `afterStatus==="approved"=${afterStatus === "approved"}, ` +
        `beforeStatus!=="live"=${beforeStatus !== "live"}, ` +
        `afterStatus==="live"=${afterStatus === "live"}`
    );
    if (
      (beforeStatus !== "approved" && afterStatus === "approved") ||
      (beforeStatus !== "live" && afterStatus === "live")
    ) {
      console.log(
        `[onVehicleApproved] Triggered for vehicle ${context.params.vehicleId}, status changed from ${beforeStatus} to ${afterStatus}`
      );
      // 1. Fetch transporter email from users collection using userId
      let transporterEmail = null;
      let transporterName = "";
      if (after.userId) {
        try {
          const transporterDoc = await db
            .collection("users")
            .doc(after.userId)
            .get();
          if (transporterDoc.exists) {
            const transporterData = transporterDoc.data();
            transporterEmail = transporterData.email || null;
            transporterName = `${transporterData.firstName || ""} ${
              transporterData.lastName || ""
            }`.trim();
          } else {
            console.warn(
              "Transporter user not found for userId:",
              after.userId
            );
          }
        } catch (err) {
          console.error(
            "Error fetching transporter user for vehicle",
            context.params.vehicleId,
            err
          );
        }
      } else {
        console.warn(
          "No userId found on vehicle for transporter lookup",
          context.params.vehicleId
        );
      }
      const make = after.make || after.brands?.[0] || "";
      const model =
        after.model || after.makeModel || after.modelDetails?.model || "";
      const year = after.year || after.modelDetails?.year || "";
      const variant = after.variant || "";
      const vehicleLink = `https://ctpapp.co.za/vehicle/${context.params.vehicleId}`;
      const imageUrl = after.mainImageUrl || "";

      // Send dynamic template email to transporter (test: only send to bradley@reagency.co.za)
      if (transporterEmail) {
        try {
          await sgMail.send({
            from: "admin@ctpapp.co.za",
            to: "bradley@reagency.co.za", // TEST: force all transporter emails to Bradley
            templateId: process.env.SENDGRID_TRANSPORTER_TEMPLATE_ID.trim(),
            dynamic_template_data: {
              make,
              model,
              year,
              variant,
              transporter: transporterName,
              vehicleLink,
              imageUrl,
            },
          });
        } catch (err) {
          console.error("Error sending approval email to transporter:", err);
        }
      } else {
        console.warn(
          "No transporter email found for vehicle",
          context.params.vehicleId
        );
      }

      // 2. Notify all dealers with dynamic template (test: only send to bradley@reagency.co.za)
      try {
        await sgMail.send({
          from: "admin@ctpapp.co.za",
          to: "bradley@reagency.co.za", // TEST: force all dealer emails to Bradley
          templateId: process.env.SENDGRID_DEALER_TEMPLATE_ID.trim(),
          dynamic_template_data: {
            make,
            model,
            year,
            variant,
            vehicleLink,
            imageUrl,
          },
        });
      } catch (err) {
        console.error("Error sending new vehicle email to dealers:", err);
      }

      // Send push notification to transporter (using their actual FCM token)
      if (transporterEmail) {
        try {
          // Fetch transporter FCM token
          let transporterFcmToken = null;
          if (after.userId) {
            const transporterDoc = await db
              .collection("users")
              .doc(after.userId)
              .get();
            if (transporterDoc.exists) {
              const transporterData = transporterDoc.data();
              transporterFcmToken = transporterData.fcmToken || null;
            }
          }
          if (transporterFcmToken) {
            await admin.messaging().send({
              notification: {
                title: "Your vehicle has been approved!",
                body: `Congratulations! Your vehicle ${make} ${model} is now live on the platform.`,
              },
              token: transporterFcmToken,
            });
          } else {
            console.warn("No FCM token found for transporter", after.userId);
          }
        } catch (err) {
          console.error("Error sending push notification to transporter:", err);
        }
      }

      // Send push notification to all dealers (using their FCM tokens)
      try {
        // Fetch all dealer FCM tokens
        const dealersSnapshot = await db
          .collection("users")
          .where("userRole", "==", "dealer")
          .get();
        const dealerFcmTokens = dealersSnapshot.docs
          .map((doc) => doc.data().fcmToken)
          .filter((token) => !!token);
        if (dealerFcmTokens.length > 0) {
          // FCM allows up to 500 tokens per sendMulticast
          const batchSize = 500;
          for (let i = 0; i < dealerFcmTokens.length; i += batchSize) {
            const batchTokens = dealerFcmTokens.slice(i, i + batchSize);
            await admin.messaging().sendMulticast({
              notification: {
                title: "New Vehicles Listed!",
                body: "There are new vehicles that have been listed. Come check it out!",
              },
              tokens: batchTokens,
            });
          }
        } else {
          console.warn("No dealer FCM tokens found for push notification");
        }
      } catch (err) {
        console.error("Error sending push notification to dealers:", err);
      }
    }
    return null;
  }
);

// Notify admins when a dealer or transporter completes registration (i.e., phone number is set)
exports.notifyAdminsOnUserPhoneAdded = onDocumentUpdated(
  {
    document: "users/{userId}",
    region: "us-central1",
  },
  async (event) => {
    const before = event.data.before.data();
    const after = event.data.after.data();
    const userId = event.params.userId;
    if (!before || !after) return;

    // Only trigger for dealer or transporter
    const userRole = after.userRole;
    if (userRole !== "dealer" && userRole !== "transporter") return;

    // Only trigger if phoneNumber was previously missing and is now set
    const beforePhone = before.phoneNumber || before.phone || null;
    const afterPhone = after.phoneNumber || after.phone || null;
    // Required fields for registration completion
    const requiredFields = [
      "companyName",
      "firstName",
      "lastName",
      "addressLine1",
      "city",
      "state",
      "postalCode",
      "country",
      "phoneNumber",
    ];
    // Check if all required fields are present and non-empty in 'after'
    const registrationComplete = requiredFields.every(
      (field) => after[field] && String(after[field]).trim() !== ""
    );
    if (!beforePhone && afterPhone && registrationComplete) {
      // Send push notification to all admins
      try {
        const adminUsersSnapshot = await db
          .collection("users")
          .where("userRole", "in", ["admin", "sales representative"])
          .get();
        const adminFcmTokens = adminUsersSnapshot.docs
          .map((doc) => doc.data().fcmToken)
          .filter((token) => !!token);
        if (adminFcmTokens.length === 0) {
          console.warn(
            "No admin FCM tokens found for registration notification"
          );
        } else {
          for (const token of adminFcmTokens) {
            try {
              await admin.messaging().send({
                notification: {
                  title: `New ${userRole} Registration Completed`,
                  body: `A ${userRole} has completed registration. Phone: ${afterPhone}`,
                },
                token: token,
              });
              console.log(`Notification sent to admin FCM token ${token}`);
            } catch (pushErr) {
              console.error(
                "Error sending push notification to admin:",
                pushErr
              );
            }
          }
        }
      } catch (err) {
        console.error("Error fetching admin users for push notification:", err);
      }
      return;
    }

    // Fetch admin emails
    /*
    const adminSnapshot = await db
      .collection("users")
      .where("userRole", "in", ["admin", "sales representative"])
      .get();
    const adminEmails = adminSnapshot.docs
      .map((doc) => doc.data().email)
      .filter((email) => !!email);
    if (adminEmails.length === 0) {
      console.warn("No admin emails found for registration notification");
      return;
    }
    // Compose email
    const name = `${after.firstName || ""} ${after.lastName || ""}`.trim();
    const company = after.companyName || after.tradingName || "";
    const email = after.email || "";
    const role = userRole.charAt(0).toUpperCase() + userRole.slice(1);
    try {
      await sgMail.send({
        from: "admin@ctpapp.co.za",
        to: adminEmails,
        subject: `New ${role} Registration Completed`,
        text: `${role} ${name} (${email}) from ${company} has completed registration. Phone: ${afterPhone}`,
        html: `<p><b>${role} Registration Completed</b></p><p>Name: ${name}<br>Email: ${email}<br>Company: ${company}<br>Phone: ${afterPhone}</p>`,
      });
      console.log(
        `Admin notified of new ${role} registration for userId ${userId}`
      );
    } catch (err) {
      console.error("Error sending admin registration notification:", err);
    }
    */
  }
);

// Scheduled function to remind users about uploading required documents
exports.sendDocumentUploadReminders = onSchedule(
  {
    schedule: "0 9 */2 * *", // Every 2 days at 9 AM
    timeZone: "Africa/Johannesburg",
    region: "us-central1",
  },
  async (event) => {
    console.log("[sendDocumentUploadReminders] Starting document reminder job");

    try {
      // Get all dealers and transporters
      const usersSnapshot = await db
        .collection("users")
        .where("userRole", "in", ["dealer", "transporter"])
        .get();

      if (usersSnapshot.empty) {
        console.log(
          "[sendDocumentUploadReminders] No dealers or transporters found"
        );
        return;
      }

      let reminderCount = 0;

      for (const userDoc of usersSnapshot.docs) {
        const userData = userDoc.data();
        const userId = userDoc.id;
        const userRole = userData.userRole;

        // Skip if user doesn't have FCM token
        if (!userData.fcmToken) {
          console.log(
            `[sendDocumentUploadReminders] User ${userId} has no FCM token`
          );
          continue;
        }

        // Check if user has completed basic registration
        const hasBasicInfo =
          userData.companyName &&
          userData.registrationNumber &&
          userData.vatNumber &&
          userData.firstName &&
          userData.lastName;

        if (!hasBasicInfo) {
          console.log(
            `[sendDocumentUploadReminders] User ${userId} hasn't completed basic registration`
          );
          continue;
        }

        // Check required documents based on user role
        let missingDocuments = [];

        if (userRole === "dealer") {
          // Required documents for dealers
          if (
            !userData.cipcCertificateUrl ||
            userData.cipcCertificateUrl.trim() === ""
          ) {
            missingDocuments.push("CIPC Certificate");
          }
          if (!userData.brncUrl || userData.brncUrl.trim() === "") {
            missingDocuments.push("Business Registration Certificate");
          }
          if (
            !userData.bankConfirmationUrl ||
            userData.bankConfirmationUrl.trim() === ""
          ) {
            missingDocuments.push("Bank Confirmation Letter");
          }
          if (!userData.proxyUrl || userData.proxyUrl.trim() === "") {
            missingDocuments.push("Proxy/Authorization Letter");
          }
        } else if (userRole === "transporter") {
          // Required documents for transporters
          if (
            !userData.cipcCertificateUrl ||
            userData.cipcCertificateUrl.trim() === ""
          ) {
            missingDocuments.push("CIPC Certificate");
          }
          if (!userData.brncUrl || userData.brncUrl.trim() === "") {
            missingDocuments.push("Business Registration Certificate");
          }
          if (
            !userData.bankConfirmationUrl ||
            userData.bankConfirmationUrl.trim() === ""
          ) {
            missingDocuments.push("Bank Confirmation Letter");
          }
          // Tax certificate for transporters
          if (
            !userData.taxCertificateUrl ||
            userData.taxCertificateUrl.trim() === ""
          ) {
            missingDocuments.push("Tax Clearance Certificate");
          }
        }

        // Skip if user has all required documents
        if (missingDocuments.length === 0) {
          continue;
        }

        // Check if user was already reminded recently (within last 2 days)
        const lastReminderField = `lastDocumentReminder`;
        const lastReminder = userData[lastReminderField];
        const twoDaysAgo = new Date(Date.now() - 2 * 24 * 60 * 60 * 1000);

        if (lastReminder && lastReminder.toDate() > twoDaysAgo) {
          console.log(
            `[sendDocumentUploadReminders] User ${userId} was reminded recently, skipping`
          );
          continue;
        }

        try {
          // Create personalized message
          const userName =
            `${userData.firstName || ""} ${userData.lastName || ""}`.trim() ||
            userData.companyName ||
            "there";
          const documentList =
            missingDocuments.length === 1
              ? missingDocuments[0]
              : missingDocuments.slice(0, -1).join(", ") +
                " and " +
                missingDocuments[missingDocuments.length - 1];

          const message = {
            notification: {
              title: "📄 Document Upload Reminder",
              body: `Hi ${userName}! You still need to upload: ${documentList}. Complete your profile to start making deals.`,
            },
            data: {
              notificationType: "document_reminder",
              userRole: userRole,
              missingDocuments: JSON.stringify(missingDocuments),
              timestamp: new Date().toISOString(),
            },
            token: userData.fcmToken,
          };

          await admin.messaging().send(message);
          console.log(
            `[sendDocumentUploadReminders] Reminder sent to ${userRole} ${userId}`
          );

          // Update the last reminder timestamp
          await db
            .collection("users")
            .doc(userId)
            .update({
              [lastReminderField]: admin.firestore.FieldValue.serverTimestamp(),
            });

          reminderCount++;
        } catch (messageError) {
          console.error(
            `[sendDocumentUploadReminders] Error sending reminder to user ${userId}:`,
            messageError
          );
        }
      }

      console.log(
        `[sendDocumentUploadReminders] Job completed. Sent ${reminderCount} reminders.`
      );
    } catch (error) {
      console.error(
        "[sendDocumentUploadReminders] Error in scheduled job:",
        error
      );
    }
  }
);

// Notify transporter, dealer, and admins when an inspection is booked
exports.notifyPartiesOnInspectionBooked = onDocumentUpdated(
  {
    document: "offers/{offerId}",
    region: "us-central1",
  },
  async (event) => {
    console.log(
      "[notifyPartiesOnInspectionBooked] Triggered for offerId:",
      event.params.offerId
    );

    const before = event.data.before.data();
    const after = event.data.after.data();
    const offerId = event.params.offerId;

    if (!before || !after) {
      console.log("[notifyPartiesOnInspectionBooked] No before/after data");
      return;
    }

    // Check if inspection details were just added/updated
    const beforeHasInspection = !!(
      before.dealerSelectedInspectionDate &&
      before.dealerSelectedInspectionTime &&
      before.dealerSelectedInspectionLocation
    );

    const afterHasInspection = !!(
      after.dealerSelectedInspectionDate &&
      after.dealerSelectedInspectionTime &&
      after.dealerSelectedInspectionLocation
    );

    // Only notify if inspection was just booked (not already there)
    if (beforeHasInspection || !afterHasInspection) {
      console.log(
        "[notifyPartiesOnInspectionBooked] Inspection not newly booked, skipping"
      );
      return;
    }

    console.log(
      "[notifyPartiesOnInspectionBooked] New inspection booking detected"
    );

    try {
      // Get dealer details
      const dealerDoc = await db.collection("users").doc(after.dealerId).get();
      const dealerData = dealerDoc.exists ? dealerDoc.data() : {};
      const dealerName =
        `${dealerData.firstName || ""} ${dealerData.lastName || ""}`.trim() ||
        dealerData.companyName ||
        "Dealer";
      const dealerEmail = dealerData.email;

      // Get transporter details
      const transporterDoc = await db
        .collection("users")
        .doc(after.transporterId)
        .get();
      const transporterData = transporterDoc.exists
        ? transporterDoc.data()
        : {};
      const transporterName =
        `${transporterData.firstName || ""} ${
          transporterData.lastName || ""
        }`.trim() ||
        transporterData.companyName ||
        "Transporter";
      const transporterEmail = transporterData.email;

      // Get vehicle details
      const vehicleDoc = await db
        .collection("vehicles")
        .doc(after.vehicleId)
        .get();
      const vehicleData = vehicleDoc.exists ? vehicleDoc.data() : {};
      const vehicleName = `${
        vehicleData.brands?.join(", ") || vehicleData.brand || "Vehicle"
      } ${vehicleData.makeModel || vehicleData.model || ""} ${
        vehicleData.year || ""
      }`.trim();

      // Format inspection details
      const inspectionDate = after.dealerSelectedInspectionDate.toDate
        ? after.dealerSelectedInspectionDate.toDate().toLocaleDateString()
        : new Date(after.dealerSelectedInspectionDate).toLocaleDateString();
      const inspectionTime = after.dealerSelectedInspectionTime;
      const inspectionLocation = after.dealerSelectedInspectionLocation;

      // Notify transporter (vehicle owner)
      if (transporterData.fcmToken) {
        try {
          const transporterMessage = {
            notification: {
              title: "📅 Inspection Booked",
              body: `An inspection for your ${vehicleName} has been scheduled on ${inspectionDate} at ${inspectionTime}`,
            },
            data: {
              offerId: offerId,
              vehicleId: after.vehicleId,
              dealerId: after.dealerId,
              notificationType: "inspection_booked",
              inspectionDate: inspectionDate,
              inspectionTime: inspectionTime,
              inspectionLocation: inspectionLocation,
              timestamp: new Date().toISOString(),
            },
            token: transporterData.fcmToken,
          };

          await admin.messaging().send(transporterMessage);
          console.log(
            `[notifyPartiesOnInspectionBooked] Notification sent to transporter ${after.transporterId}`
          );
        } catch (transporterError) {
          console.error(
            `[notifyPartiesOnInspectionBooked] Error sending notification to transporter:`,
            transporterError
          );
        }
      }

      // Notify dealer (confirmation) - do not include transporter names
      if (dealerData.fcmToken) {
        try {
          const dealerMessage = {
            notification: {
              title: "✅ Inspection Confirmed",
              body: `Your inspection for ${vehicleName} has been scheduled for ${inspectionDate} at ${inspectionTime}`,
            },
            data: {
              offerId: offerId,
              vehicleId: after.vehicleId,
              transporterId: after.transporterId,
              notificationType: "inspection_booked_confirmation",
              inspectionDate: inspectionDate,
              inspectionTime: inspectionTime,
              inspectionLocation: inspectionLocation,
              timestamp: new Date().toISOString(),
            },
            token: dealerData.fcmToken,
          };

          await admin.messaging().send(dealerMessage);
          console.log(
            `[notifyPartiesOnInspectionBooked] Confirmation sent to dealer ${after.dealerId}`
          );
        } catch (dealerError) {
          console.error(
            `[notifyPartiesOnInspectionBooked] Error sending confirmation to dealer:`,
            dealerError
          );
        }
      }

      // Get all admin users for notifications
      const adminUsersSnapshot = await db
        .collection("users")
        .where("userRole", "in", ["admin", "sales representative"])
        .get();

      // Notify admins
      if (!adminUsersSnapshot.empty) {
        for (const adminDoc of adminUsersSnapshot.docs) {
          const adminData = adminDoc.data();

          if (!adminData.fcmToken) {
            console.log(
              `[notifyPartiesOnInspectionBooked] Admin ${adminDoc.id} has no FCM token`
            );
            continue;
          }

          try {
            const adminMessage = {
              notification: {
                title: "📋 Inspection Scheduled",
                body: `${dealerName} (buyer) scheduled inspection for ${transporterName}'s (seller) ${vehicleName} on ${inspectionDate}`,
              },
              data: {
                offerId: offerId,
                vehicleId: after.vehicleId,
                dealerId: after.dealerId,
                transporterId: after.transporterId,
                notificationType: "inspection_booked_admin",
                inspectionDate: inspectionDate,
                inspectionTime: inspectionTime,
                inspectionLocation: inspectionLocation,
                timestamp: new Date().toISOString(),
              },
              token: adminData.fcmToken,
            };

            await admin.messaging().send(adminMessage);
            console.log(
              `[notifyPartiesOnInspectionBooked] Notification sent to admin ${adminDoc.id}`
            );
          } catch (adminError) {
            console.error(
              `[notifyPartiesOnInspectionBooked] Error sending notification to admin ${adminDoc.id}:`,
              adminError
            );
          }
        }
      }

      // Send email notifications if SendGrid is available
      if (sgMail) {
        const offerLink = `https://ctpapp.co.za/offer/${offerId}`;

        // Email to transporter
        if (transporterEmail) {
          try {
            await sgMail.send({
              from: "admin@ctpapp.co.za",
              to: transporterEmail,
              subject: `📅 Inspection Scheduled - ${vehicleName}`,
              html: `
                <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto;">
                  <h2 style="color: #2F7FFF;">Inspection Scheduled for Your Vehicle 📅</h2>
                  <p>Great news! A buyer has scheduled an inspection for your vehicle.</p>
                  
                  <div style="background-color: #f8f9fa; padding: 20px; border-radius: 8px; margin: 20px 0;">
                    <h3 style="margin-top: 0; color: #333;">Inspection Details:</h3>
                    <p><strong>Vehicle:</strong> ${vehicleName}</p>
                    <p><strong>Date:</strong> ${inspectionDate}</p>
                    <p><strong>Time:</strong> ${inspectionTime}</p>
                    <p><strong>Location:</strong> ${inspectionLocation}</p>
                  </div>
                  
                  <div style="background-color: #d1ecf1; padding: 15px; border-radius: 8px; margin: 20px 0; border-left: 4px solid #17a2b8;">
                    <h4 style="margin-top: 0; color: #0c5460;">What's Next?</h4>
                    <p style="margin: 5px 0;">• Ensure your vehicle is ready for inspection</p>
                    <p style="margin: 5px 0;">• Be available at the scheduled time</p>
                    <p style="margin: 5px 0;">• Prepare any relevant documentation</p>
                  </div>
                  
                  <div style="text-align: center; margin: 30px 0;">
                    <a href="${offerLink}" 
                       style="background-color: #2F7FFF; color: white; padding: 12px 24px; text-decoration: none; border-radius: 5px; display: inline-block;">
                      View Offer Details
                    </a>
                  </div>
                  
                  <p>Best regards,<br>
                  Commercial Trader Portal Team</p>
                </div>
              `,
            });

            console.log(
              `[notifyPartiesOnInspectionBooked] Email sent to transporter ${transporterEmail}`
            );
          } catch (emailError) {
            console.error(
              "[notifyPartiesOnInspectionBooked] Error sending email to transporter:",
              emailError
            );
          }
        }

        // Email to dealer (confirmation) - do not include transporter names
        if (dealerEmail) {
          try {
            await sgMail.send({
              from: "admin@ctpapp.co.za",
              to: dealerEmail,
              subject: `✅ Inspection Confirmed - ${vehicleName}`,
              html: `
                <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto;">
                  <h2 style="color: #28a745;">Inspection Booking Confirmed ✅</h2>
          <p>Your inspection has been successfully scheduled. Here are the details:</p>
                  
                  <div style="background-color: #f8f9fa; padding: 20px; border-radius: 8px; margin: 20px 0;">
                    <h3 style="margin-top: 0; color: #333;">Inspection Details:</h3>
                    <p><strong>Vehicle:</strong> ${vehicleName}</p>
                    <p><strong>Date:</strong> ${inspectionDate}</p>
                    <p><strong>Time:</strong> ${inspectionTime}</p>
                    <p><strong>Location:</strong> ${inspectionLocation}</p>
                  </div>
                  
                  <div style="background-color: #d4edda; padding: 15px; border-radius: 8px; margin: 20px 0; border-left: 4px solid #28a745;">
                    <h4 style="margin-top: 0; color: #155724;">Preparation Tips:</h4>
                    <p style="margin: 5px 0;">• Arrive on time for your scheduled inspection</p>
                    <p style="margin: 5px 0;">• Bring necessary identification and documentation</p>
                    <p style="margin: 5px 0;">• Prepare a list of questions about the vehicle</p>
                    <p style="margin: 5px 0;">• Consider bringing a mechanic if needed</p>
                  </div>
                  
                  <div style="text-align: center; margin: 30px 0;">
                    <a href="${offerLink}" 
                       style="background-color: #28a745; color: white; padding: 12px 24px; text-decoration: none; border-radius: 5px; display: inline-block;">
                      View Offer Details
                    </a>
                  </div>
                  
                  <p>Best regards,<br>
                  Commercial Trader Portal Team</p>
                </div>
              `,
            });

            console.log(
              `[notifyPartiesOnInspectionBooked] Confirmation email sent to dealer ${dealerEmail}`
            );
          } catch (emailError) {
            console.error(
              "[notifyPartiesOnInspectionBooked] Error sending confirmation email to dealer:",
              emailError
            );
          }
        }

        // Email to admins
        const adminEmails = adminUsersSnapshot.docs
          .map((doc) => doc.data().email)
          .filter((email) => !!email);

        if (adminEmails.length > 0) {
          try {
            await sgMail.send({
              from: "admin@ctpapp.co.za",
              to: adminEmails,
              subject: `📋 New Inspection Scheduled - ${vehicleName}`,
              html: `
                <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto;">
                  <h2 style="color: #2F7FFF;">New Vehicle Inspection Scheduled 📋</h2>
                  <p>A buyer has scheduled an inspection for a vehicle on the platform.</p>
                  
                  <div style="background-color: #f8f9fa; padding: 20px; border-radius: 8px; margin: 20px 0;">
                    <h3 style="margin-top: 0; color: #333;">Inspection Details:</h3>
                    <p><strong>Vehicle:</strong> ${vehicleName}</p>
                    <p><strong>Buyer:</strong> ${dealerName}</p>
                    <p><strong>Seller:</strong> ${transporterName}</p>
                    <p><strong>Date:</strong> ${inspectionDate}</p>
                    <p><strong>Time:</strong> ${inspectionTime}</p>
                    <p><strong>Location:</strong> ${inspectionLocation}</p>
                    <p><strong>Offer Amount:</strong> R${
                      after.offerAmount || "TBD"
                    }</p>
                  </div>
                  
                  <div style="text-align: center; margin: 30px 0;">
                    <a href="${offerLink}" 
                       style="background-color: #2F7FFF; color: white; padding: 12px 24px; text-decoration: none; border-radius: 5px; display: inline-block;">
                      View Offer Details
                    </a>
                  </div>
                  
                  <p style="color: #666; font-size: 14px;">
                    This is for your information and tracking purposes. No action is required unless there are issues.
                  </p>
                  
                  <p>Best regards,<br>
                  Commercial Trader Portal System</p>
                </div>
              `,
            });

            console.log(
              `[notifyPartiesOnInspectionBooked] Email notification sent to ${adminEmails.length} admins`
            );
          } catch (emailError) {
            console.error(
              "[notifyPartiesOnInspectionBooked] Error sending email to admins:",
              emailError
            );
          }
        }
      }
    } catch (error) {
      console.error("[notifyPartiesOnInspectionBooked] Error:", error);
    }
  }
);

// Notify transporter, dealer, and admins when inspection results are uploaded
exports.notifyPartiesOnInspectionResultsUploaded = onDocumentUpdated(
  {
    document: "offers/{offerId}",
    region: "us-central1",
  },
  async (event) => {
    console.log(
      "[notifyPartiesOnInspectionResultsUploaded] Triggered for offerId:",
      event.params.offerId
    );

    const before = event.data.before.data();
    const after = event.data.after.data();
    const offerId = event.params.offerId;

    if (!before || !after) {
      console.log(
        "[notifyPartiesOnInspectionResultsUploaded] No before/after data"
      );
      return;
    }

    // Check if inspection results were just uploaded or completion flags toggled
    // This could be inspection images, inspection notes, or inspection status
    const beforeHasResults = !!(
      before.inspectionImages ||
      before.inspectionNotes ||
      before.inspectionReport ||
      before.inspectionStatus === "completed"
    );

    const afterHasResults = !!(
      after.inspectionImages ||
      after.inspectionNotes ||
      after.inspectionReport ||
      after.inspectionStatus === "completed"
    );

    // Check if new inspection content was added
    const newImagesAdded =
      (!before.inspectionImages || before.inspectionImages.length === 0) &&
      after.inspectionImages &&
      after.inspectionImages.length > 0;

    const newNotesAdded =
      (!before.inspectionNotes || before.inspectionNotes.trim() === "") &&
      after.inspectionNotes &&
      after.inspectionNotes.trim() !== "";

    const newReportAdded = !before.inspectionReport && after.inspectionReport;

    const statusChanged =
      before.inspectionStatus !== "completed" &&
      after.inspectionStatus === "completed";

    // Also consider boolean flags used by the app
    const dealerCompletedChanged =
      before.dealerInspectionComplete !== true &&
      after.dealerInspectionComplete === true;
    const transporterCompletedChanged =
      before.transporterInspectionComplete !== true &&
      after.transporterInspectionComplete === true;

    // Only notify if new inspection results were added
    if (
      !newImagesAdded &&
      !newNotesAdded &&
      !newReportAdded &&
      !statusChanged &&
      !dealerCompletedChanged &&
      !transporterCompletedChanged
    ) {
      console.log(
        "[notifyPartiesOnInspectionResultsUploaded] No new inspection results detected, skipping"
      );
      return;
    }

    console.log(
      "[notifyPartiesOnInspectionResultsUploaded] New inspection results detected"
    );

    try {
      // Get dealer details
      const dealerDoc = await db.collection("users").doc(after.dealerId).get();
      const dealerData = dealerDoc.exists ? dealerDoc.data() : {};
      const dealerName =
        `${dealerData.firstName || ""} ${dealerData.lastName || ""}`.trim() ||
        dealerData.companyName ||
        "Dealer";
      const dealerEmail = dealerData.email;

      // Get transporter details
      const transporterDoc = await db
        .collection("users")
        .doc(after.transporterId)
        .get();
      const transporterData = transporterDoc.exists
        ? transporterDoc.data()
        : {};
      const transporterName =
        `${transporterData.firstName || ""} ${
          transporterData.lastName || ""
        }`.trim() ||
        transporterData.companyName ||
        "Transporter";
      const transporterEmail = transporterData.email;

      // Get vehicle details
      const vehicleDoc = await db
        .collection("vehicles")
        .doc(after.vehicleId)
        .get();
      const vehicleData = vehicleDoc.exists ? vehicleDoc.data() : {};
      const vehicleName = `${
        vehicleData.brands?.join(", ") || vehicleData.brand || "Vehicle"
      } ${vehicleData.makeModel || vehicleData.model || ""} ${
        vehicleData.year || ""
      }`.trim();

      // Create result summary
      let resultSummary = [];
      if (newImagesAdded) {
        resultSummary.push(
          `${after.inspectionImages.length} inspection images`
        );
      }
      if (newNotesAdded) {
        resultSummary.push("inspection notes");
      }
      if (newReportAdded) {
        resultSummary.push("inspection report");
      }
      if (statusChanged) {
        resultSummary.push("inspection completed");
      }

      const resultText = resultSummary.join(", ");

      // Notify transporter (vehicle owner)
      if (transporterData.fcmToken) {
        try {
          const transporterMessage = {
            notification: {
              title: "📋 Inspection Results Available",
              body: `Inspection results for your ${vehicleName} have been uploaded. ${resultText}`,
            },
            data: {
              offerId: offerId,
              vehicleId: after.vehicleId,
              dealerId: after.dealerId,
              notificationType: "inspection_results_uploaded",
              resultSummary: resultText,
              hasImages: String(!!after.inspectionImages?.length),
              hasNotes: String(!!after.inspectionNotes),
              hasReport: String(!!after.inspectionReport),
              timestamp: new Date().toISOString(),
            },
            token: transporterData.fcmToken,
          };

          await admin.messaging().send(transporterMessage);
          console.log(
            `[notifyPartiesOnInspectionResultsUploaded] Notification sent to transporter ${after.transporterId}`
          );
        } catch (transporterError) {
          console.error(
            `[notifyPartiesOnInspectionResultsUploaded] Error sending notification to transporter:`,
            transporterError
          );
        }
      }

      // Notify dealer (confirmation) - do not include transporter names
      if (dealerData.fcmToken) {
        try {
          const dealerMessage = {
            notification: {
              title: "✅ Inspection Results Uploaded",
              body: `Your inspection results for ${vehicleName} have been successfully uploaded and shared with the seller`,
            },
            data: {
              offerId: offerId,
              vehicleId: after.vehicleId,
              transporterId: after.transporterId,
              notificationType: "inspection_results_uploaded_confirmation",
              resultSummary: resultText,
              timestamp: new Date().toISOString(),
            },
            token: dealerData.fcmToken,
          };

          await admin.messaging().send(dealerMessage);
          console.log(
            `[notifyPartiesOnInspectionResultsUploaded] Confirmation sent to dealer ${after.dealerId}`
          );
        } catch (dealerError) {
          console.error(
            `[notifyPartiesOnInspectionResultsUploaded] Error sending confirmation to dealer:`,
            dealerError
          );
        }
      }

      // Get all admin users for notifications
      const adminUsersSnapshot = await db
        .collection("users")
        .where("userRole", "in", ["admin", "sales representative"])
        .get();

      // Notify admins
      if (!adminUsersSnapshot.empty) {
        for (const adminDoc of adminUsersSnapshot.docs) {
          const adminData = adminDoc.data();

          if (!adminData.fcmToken) {
            console.log(
              `[notifyPartiesOnInspectionResultsUploaded] Admin ${adminDoc.id} has no FCM token`
            );
            continue;
          }

          try {
            const adminMessage = {
              notification: {
                title: "📊 Inspection Results Uploaded",
                body: `${dealerName} (buyer) uploaded inspection results for ${transporterName}'s (seller) ${vehicleName}`,
              },
              data: {
                offerId: offerId,
                vehicleId: after.vehicleId,
                dealerId: after.dealerId,
                transporterId: after.transporterId,
                notificationType: "inspection_results_uploaded_admin",
                resultSummary: resultText,
                timestamp: new Date().toISOString(),
              },
              token: adminData.fcmToken,
            };

            await admin.messaging().send(adminMessage);
            console.log(
              `[notifyPartiesOnInspectionResultsUploaded] Notification sent to admin ${adminDoc.id}`
            );
          } catch (adminError) {
            console.error(
              `[notifyPartiesOnInspectionResultsUploaded] Error sending notification to admin ${adminDoc.id}:`,
              adminError
            );
          }
        }
      }

      // Send email notifications if SendGrid is available
      if (sgMail) {
        const offerLink = `https://ctpapp.co.za/offer/${offerId}`;

        // Email to transporter
        if (transporterEmail) {
          try {
            await sgMail.send({
              from: "admin@ctpapp.co.za",
              to: transporterEmail,
              subject: `📋 Inspection Results Available - ${vehicleName}`,
              html: `
                <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto;">
                  <h2 style="color: #2F7FFF;">Inspection Results Available 📋</h2>
                  <p>Great news! The inspection results for your vehicle are now available.</p>
                  
                  <div style="background-color: #f8f9fa; padding: 20px; border-radius: 8px; margin: 20px 0;">
                    <h3 style="margin-top: 0; color: #333;">Inspection Details:</h3>
                    <p><strong>Vehicle:</strong> ${vehicleName}</p>
                    <p><strong>Results include:</strong> ${resultText}</p>
                    ${
                      after.inspectionImages?.length
                        ? `<p><strong>Images:</strong> ${after.inspectionImages.length} photos attached</p>`
                        : ""
                    }
                  </div>
                  
                  <div style="background-color: #d1ecf1; padding: 15px; border-radius: 8px; margin: 20px 0; border-left: 4px solid #17a2b8;">
                    <h4 style="margin-top: 0; color: #0c5460;">What's Next?</h4>
                    <p style="margin: 5px 0;">• Review the inspection results carefully</p>
                    <p style="margin: 5px 0;">• Check all uploaded images and notes</p>
                    <p style="margin: 5px 0;">• Contact the dealer if you have questions</p>
                    <p style="margin: 5px 0;">• Proceed with the transaction if satisfied</p>
                  </div>
                  
                  <div style="text-align: center; margin: 30px 0;">
                    <a href="${offerLink}" 
                       style="background-color: #2F7FFF; color: white; padding: 12px 24px; text-decoration: none; border-radius: 5px; display: inline-block;">
                      View Inspection Results
                    </a>
                  </div>
                  
                  <p>Best regards,<br>
                  Commercial Trader Portal Team</p>
                </div>
              `,
            });

            console.log(
              `[notifyPartiesOnInspectionResultsUploaded] Email sent to transporter ${transporterEmail}`
            );
          } catch (emailError) {
            console.error(
              "[notifyPartiesOnInspectionResultsUploaded] Error sending email to transporter:",
              emailError
            );
          }
        }

        // Email to dealer (confirmation)
        if (dealerEmail) {
          try {
            await sgMail.send({
              from: "admin@ctpapp.co.za",
              to: dealerEmail,
              subject: `✅ Inspection Results Shared - ${vehicleName}`,
              html: `
                <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto;">
                  <h2 style="color: #28a745;">Inspection Results Successfully Shared ✅</h2>
                  <p>Your inspection results have been successfully uploaded and shared with the transporter.</p>
                  
                  <div style="background-color: #f8f9fa; padding: 20px; border-radius: 8px; margin: 20px 0;">
                    <h3 style="margin-top: 0; color: #333;">Upload Summary:</h3>
                    <p><strong>Vehicle:</strong> ${vehicleName}</p>
                    <p><strong>Shared with:</strong> ${transporterName}</p>
                    <p><strong>Results shared:</strong> ${resultText}</p>
                    ${
                      after.inspectionImages?.length
                        ? `<p><strong>Images uploaded:</strong> ${after.inspectionImages.length} photos</p>`
                        : ""
                    }
                    <p><strong>Upload time:</strong> ${new Date().toLocaleString()}</p>
                  </div>
                  
                  <div style="background-color: #d4edda; padding: 15px; border-radius: 8px; margin: 20px 0; border-left: 4px solid #28a745;">
                    <h4 style="margin-top: 0; color: #155724;">Next Steps:</h4>
                    <p style="margin: 5px 0;">• The transporter has been notified of the results</p>
                    <p style="margin: 5px 0;">• They will review and contact you if needed</p>
                    <p style="margin: 5px 0;">• You can track the offer status in your dashboard</p>
                    <p style="margin: 5px 0;">• Be available for any follow-up questions</p>
                  </div>
                  
                  <div style="text-align: center; margin: 30px 0;">
                    <a href="${offerLink}" 
                       style="background-color: #28a745; color: white; padding: 12px 24px; text-decoration: none; border-radius: 5px; display: inline-block;">
                      View Offer Status
                    </a>
                  </div>
                  
                  <p>Best regards,<br>
                  Commercial Trader Portal Team</p>
                </div>
              `,
            });

            console.log(
              `[notifyPartiesOnInspectionResultsUploaded] Confirmation email sent to dealer ${dealerEmail}`
            );
          } catch (emailError) {
            console.error(
              "[notifyPartiesOnInspectionResultsUploaded] Error sending confirmation email to dealer:",
              emailError
            );
          }
        }

        // Email to admins
        const adminEmails = adminUsersSnapshot.docs
          .map((doc) => doc.data().email)
          .filter((email) => !!email);

        if (adminEmails.length > 0) {
          try {
            await sgMail.send({
              from: "admin@ctpapp.co.za",
              to: adminEmails,
              subject: `📊 Inspection Results Uploaded - ${vehicleName}`,
              html: `
                <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto;">
                  <h2 style="color: #2F7FFF;">New Inspection Results Uploaded 📊</h2>
                    <p>A buyer has uploaded inspection results for a vehicle transaction.</p>
                  
                  <div style="background-color: #f8f9fa; padding: 20px; border-radius: 8px; margin: 20px 0;">
                    <h3 style="margin-top: 0; color: #333;">Inspection Summary:</h3>
                    <p><strong>Vehicle:</strong> ${vehicleName}</p>
                    <p><strong>Buyer:</strong> ${dealerName}</p>
                    <p><strong>Seller:</strong> ${transporterName}</p>
                    <p><strong>Results uploaded:</strong> ${resultText}</p>
                    <p><strong>Offer Amount:</strong> R${
                      after.offerAmount || "TBD"
                    }</p>
                    ${
                      after.inspectionImages?.length
                        ? `<p><strong>Images:</strong> ${after.inspectionImages.length} photos uploaded</p>`
                        : ""
                    }
                  </div>
                  
                  <div style="background-color: #fff3cd; padding: 15px; border-radius: 8px; margin: 20px 0; border-left: 4px solid #ffc107;">
                    <h4 style="margin-top: 0; color: #856404;">For Your Information:</h4>
                    <p style="margin: 5px 0;">• Both parties have been notified of the results</p>
                    <p style="margin: 5px 0;">• Transaction is progressing normally</p>
                    <p style="margin: 5px 0;">• Monitor for any reported issues</p>
                  </div>
                  
                  <div style="text-align: center; margin: 30px 0;">
                    <a href="${offerLink}" 
                       style="background-color: #2F7FFF; color: white; padding: 12px 24px; text-decoration: none; border-radius: 5px; display: inline-block;">
                      View Offer Details
                    </a>
                  </div>
                  
                  <p style="color: #666; font-size: 14px;">
                    This is for your information and tracking purposes. No action is required unless there are issues.
                  </p>
                  
                  <p>Best regards,<br>
                  Commercial Trader Portal System</p>
                </div>
              `,
            });

            console.log(
              `[notifyPartiesOnInspectionResultsUploaded] Email notification sent to ${adminEmails.length} admins`
            );
          } catch (emailError) {
            console.error(
              "[notifyPartiesOnInspectionResultsUploaded] Error sending email to admins:",
              emailError
            );
          }
        }
      }
    } catch (error) {
      console.error("[notifyPartiesOnInspectionResultsUploaded] Error:", error);
    }
  }
);

// Scheduled function to send invoice payment reminders
exports.sendInvoicePaymentReminders = onSchedule(
  {
    schedule: "0 10 * * *", // Daily at 10 AM
    timeZone: "Africa/Johannesburg",
    region: "us-central1",
  },
  async (event) => {
    console.log("[sendInvoicePaymentReminders] Starting invoice reminder job");

    try {
      // Get all offers with payment pending status or payment options status
      const offersSnapshot = await db
        .collection("offers")
        .where("offerStatus", "in", [
          "payment pending",
          "payment options",
          "paid",
        ])
        .get();

      if (offersSnapshot.empty) {
        console.log(
          "[sendInvoicePaymentReminders] No payment-related offers found"
        );
        return;
      }

      let reminderCount = 0;
      const currentTime = new Date();

      for (const offerDoc of offersSnapshot.docs) {
        const offerData = offerDoc.data();
        const offerId = offerDoc.id;
        const offerStatus = offerData.offerStatus?.toLowerCase() || "";

        // Skip if offer is locked, collected, or transaction is complete
        if (
          offerData.statusLocked === true ||
          offerData.transactionComplete === true ||
          offerStatus === "collected" ||
          offerStatus === "completed" ||
          offerStatus === "sold"
        ) {
          continue;
        }

        // Skip if payment is already completed/approved
        if (
          offerData.paymentStatus === "approved" ||
          offerData.paymentStatus === "accepted" ||
          offerStatus === "paid"
        ) {
          continue;
        }

        // Check if offer was created more than 24 hours ago for first reminder
        const offerCreatedAt = offerData.createdAt?.toDate();
        if (!offerCreatedAt) continue;

        const hoursSinceCreation =
          (currentTime - offerCreatedAt) / (1000 * 60 * 60);

        // Only send reminders for offers older than 24 hours
        if (hoursSinceCreation < 24) continue;

        // Check when the last reminder was sent
        const lastReminderField = "lastInvoiceReminder";
        const lastReminder = offerData[lastReminderField];
        const oneDayAgo = new Date(Date.now() - 24 * 60 * 60 * 1000);

        // Skip if reminder was sent within the last 24 hours
        if (lastReminder && lastReminder.toDate() > oneDayAgo) {
          continue;
        }

        // Calculate days overdue
        const daysOverdue = Math.floor(hoursSinceCreation / 24);

        try {
          // Get dealer details (the one who needs to pay)
          const dealerDoc = await db
            .collection("users")
            .doc(offerData.dealerId)
            .get();
          const dealerData = dealerDoc.exists ? dealerDoc.data() : {};
          const dealerName =
            `${dealerData.firstName || ""} ${
              dealerData.lastName || ""
            }`.trim() ||
            dealerData.companyName ||
            "Dealer";
          const dealerEmail = dealerData.email;

          // Get transporter details
          const transporterDoc = await db
            .collection("users")
            .doc(offerData.transporterId)
            .get();
          const transporterData = transporterDoc.exists
            ? transporterDoc.data()
            : {};
          const transporterName =
            `${transporterData.firstName || ""} ${
              transporterData.lastName || ""
            }`.trim() ||
            transporterData.companyName ||
            "Transporter";
          const transporterEmail = transporterData.email;

          // Get vehicle details
          const vehicleDoc = await db
            .collection("vehicles")
            .doc(offerData.vehicleId)
            .get();
          const vehicleData = vehicleDoc.exists ? vehicleDoc.data() : {};
          const vehicleName = `${
            vehicleData.brands?.join(", ") || vehicleData.brand || "Vehicle"
          } ${vehicleData.makeModel || vehicleData.model || ""} ${
            vehicleData.year || ""
          }`.trim();

          const offerAmount = offerData.offerAmount || 0;

          // Determine reminder urgency based on days overdue
          let urgencyLevel = "normal";
          let reminderTitle = "💰 Payment Reminder";
          if (daysOverdue >= 3) {
            urgencyLevel = "urgent";
            reminderTitle = "⚠️ Urgent Payment Required";
          } else if (daysOverdue >= 2) {
            urgencyLevel = "high";
            reminderTitle = "🔔 Payment Overdue";
          }

          // Notify dealer (primary payer)
          if (dealerData.fcmToken) {
            try {
              const dealerMessage = {
                notification: {
                  title: reminderTitle,
                  body: `Payment for ${vehicleName} (R${offerAmount}) is ${daysOverdue} day(s) overdue. Please complete payment to avoid cancellation.`,
                },
                data: {
                  offerId: offerId,
                  vehicleId: offerData.vehicleId,
                  transporterId: offerData.transporterId,
                  notificationType: "invoice_payment_reminder",
                  urgencyLevel: urgencyLevel,
                  daysOverdue: String(daysOverdue),
                  offerAmount: String(offerAmount),
                  timestamp: new Date().toISOString(),
                },
                token: dealerData.fcmToken,
              };

              await admin.messaging().send(dealerMessage);
              console.log(
                `[sendInvoicePaymentReminders] Reminder sent to dealer ${offerData.dealerId}`
              );
            } catch (dealerError) {
              console.error(
                `[sendInvoicePaymentReminders] Error sending reminder to dealer:`,
                dealerError
              );
            }
          }

          // Notify transporter (for awareness)
          if (transporterData.fcmToken) {
            try {
              const transporterMessage = {
                notification: {
                  title: "📋 Payment Status Update",
                  body: `Payment for your ${vehicleName} is ${daysOverdue} day(s) overdue. We're following up with the buyer.`,
                },
                data: {
                  offerId: offerId,
                  vehicleId: offerData.vehicleId,
                  dealerId: offerData.dealerId,
                  notificationType: "invoice_payment_reminder_transporter",
                  daysOverdue: String(daysOverdue),
                  timestamp: new Date().toISOString(),
                },
                token: transporterData.fcmToken,
              };

              await admin.messaging().send(transporterMessage);
              console.log(
                `[sendInvoicePaymentReminders] Status update sent to transporter ${offerData.transporterId}`
              );
            } catch (transporterError) {
              console.error(
                `[sendInvoicePaymentReminders] Error sending status to transporter:`,
                transporterError
              );
            }
          }

          // Notify admins for tracking
          const adminUsersSnapshot = await db
            .collection("users")
            .where("userRole", "in", ["admin", "sales representative"])
            .get();

          for (const adminDoc of adminUsersSnapshot.docs) {
            const adminData = adminDoc.data();
            if (!adminData.fcmToken) continue;

            try {
              const adminMessage = {
                notification: {
                  title: "💳 Payment Overdue Alert",
                  body: `${dealerName} (buyer) payment for ${transporterName}'s (seller) ${vehicleName} is ${daysOverdue} day(s) overdue (R${offerAmount})`,
                },
                data: {
                  offerId: offerId,
                  vehicleId: offerData.vehicleId,
                  dealerId: offerData.dealerId,
                  transporterId: offerData.transporterId,
                  notificationType: "invoice_payment_reminder_admin",
                  urgencyLevel: urgencyLevel,
                  daysOverdue: String(daysOverdue),
                  offerAmount: String(offerAmount),
                  timestamp: new Date().toISOString(),
                },
                token: adminData.fcmToken,
              };

              await admin.messaging().send(adminMessage);
            } catch (adminError) {
              console.error(
                `[sendInvoicePaymentReminders] Error sending admin notification:`,
                adminError
              );
            }
          }

          // Send email notifications if SendGrid is available
          if (sgMail) {
            const offerLink = `https://ctpapp.co.za/offer/${offerId}`;

            // Email to dealer (primary reminder)
            if (dealerEmail) {
              try {
                const urgencyColor =
                  urgencyLevel === "urgent"
                    ? "#dc3545"
                    : urgencyLevel === "high"
                    ? "#fd7e14"
                    : "#ffc107";
                const urgencyText =
                  urgencyLevel === "urgent"
                    ? "URGENT"
                    : urgencyLevel === "high"
                    ? "OVERDUE"
                    : "REMINDER";

                await sgMail.send({
                  from: "admin@ctpapp.co.za",
                  to: dealerEmail,
                  subject: `${reminderTitle} - ${vehicleName} Payment Required`,
                  html: `
                    <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto;">
                      <div style="background-color: ${urgencyColor}; color: white; padding: 15px; text-align: center; border-radius: 8px 8px 0 0;">
                        <h2 style="margin: 0; font-size: 24px;">${urgencyText}: Payment Required</h2>
                      </div>
                      
                      <div style="padding: 20px; border: 1px solid #ddd; border-top: none; border-radius: 0 0 8px 8px;">
                        <p>Dear ${dealerName},</p>
                        <p>This is a reminder that your payment for the following vehicle purchase is now <strong>${daysOverdue} day(s) overdue</strong>.</p>
                        
                        <div style="background-color: #f8f9fa; padding: 20px; border-radius: 8px; margin: 20px 0;">
                          <h3 style="margin-top: 0; color: #333;">Purchase Details:</h3>
                          <p><strong>Vehicle:</strong> ${vehicleName}</p>
                          <p><strong>Amount Due:</strong> R${offerAmount.toLocaleString()}</p>
                          <p><strong>Days Overdue:</strong> ${daysOverdue} day(s)</p>
                          <p><strong>Offer ID:</strong> ${offerId}</p>
                        </div>
                        
                        <div style="background-color: #fff3cd; padding: 15px; border-radius: 8px; margin: 20px 0; border-left: 4px solid #ffc107;">
                          <h4 style="margin-top: 0; color: #856404;">⚠️ Important Notice:</h4>
                          <p style="margin: 5px 0;">• Payment must be completed within 3 days of offer acceptance</p>
                          <p style="margin: 5px 0;">• Failure to pay may result in offer cancellation</p>
                          <p style="margin: 5px 0;">• Other dealers will be able to make offers if payment is not received</p>
                          <p style="margin: 5px 0;">• Contact us immediately if you're experiencing payment difficulties</p>
                        </div>
                        
                        <div style="text-align: center; margin: 30px 0;">
                          <a href="${offerLink}" 
                             style="background-color: #28a745; color: white; padding: 15px 30px; text-decoration: none; border-radius: 5px; display: inline-block; font-weight: bold;">
                            Complete Payment Now
                          </a>
                        </div>
                        
                        <p>If you have already made payment, please upload your proof of payment in the system or contact our support team.</p>
                        
                        <p>Best regards,<br>
                        Commercial Trader Portal Team<br>
                        <a href="mailto:admin@ctpapp.co.za">admin@ctpapp.co.za</a></p>
                      </div>
                    </div>
                  `,
                });

                console.log(
                  `[sendInvoicePaymentReminders] Email reminder sent to dealer ${dealerEmail}`
                );
              } catch (emailError) {
                console.error(
                  "[sendInvoicePaymentReminders] Error sending email to dealer:",
                  emailError
                );
              }
            }

            // Email to transporter (status update)
            if (transporterEmail) {
              try {
                await sgMail.send({
                  from: "admin@ctpapp.co.za",
                  to: transporterEmail,
                  subject: `Payment Status Update - ${vehicleName}`,
                  html: `
                    <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto;">
                      <h2 style="color: #2F7FFF;">Payment Status Update 📋</h2>
                      <p>Dear ${transporterName},</p>
                      <p>We wanted to update you on the payment status for your vehicle sale.</p>
                      
                      <div style="background-color: #f8f9fa; padding: 20px; border-radius: 8px; margin: 20px 0;">
                        <h3 style="margin-top: 0; color: #333;">Sale Details:</h3>
                        <p><strong>Vehicle:</strong> ${vehicleName}</p>
                        <p><strong>Sale Amount:</strong> R${offerAmount.toLocaleString()}</p>
                        <p><strong>Payment Status:</strong> ${daysOverdue} day(s) overdue</p>
                      </div>
                      
                      <div style="background-color: #d1ecf1; padding: 15px; border-radius: 8px; margin: 20px 0; border-left: 4px solid #17a2b8;">
                        <h4 style="margin-top: 0; color: #0c5460;">What We're Doing:</h4>
                        <p style="margin: 5px 0;">• We've sent a payment reminder to the dealer</p>
                        <p style="margin: 5px 0;">• We're actively following up on the payment</p>
                        <p style="margin: 5px 0;">• You'll be notified once payment is received</p>
                        <p style="margin: 5px 0;">• If payment isn't received within policy timeframes, the offer will be cancelled</p>
                      </div>
                      
                      <div style="text-align: center; margin: 30px 0;">
                        <a href="${offerLink}" 
                           style="background-color: #2F7FFF; color: white; padding: 12px 24px; text-decoration: none; border-radius: 5px; display: inline-block;">
                          View Offer Status
                        </a>
                      </div>
                      
                      <p>Thank you for your patience. We'll keep you updated on any developments.</p>
                      
                      <p>Best regards,<br>
                      Commercial Trader Portal Team</p>
                    </div>
                  `,
                });

                console.log(
                  `[sendInvoicePaymentReminders] Status email sent to transporter ${transporterEmail}`
                );
              } catch (emailError) {
                console.error(
                  "[sendInvoicePaymentReminders] Error sending email to transporter:",
                  emailError
                );
              }
            }

            // Email to admins (summary)
            const adminEmails = adminUsersSnapshot.docs
              .map((doc) => doc.data().email)
              .filter((email) => !!email);

            if (adminEmails.length > 0) {
              try {
                await sgMail.send({
                  from: "admin@ctpapp.co.za",
                  to: adminEmails,
                  subject: `💳 Payment Overdue Alert - ${vehicleName}`,
                  html: `
                    <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto;">
                      <h2 style="color: #dc3545;">Payment Overdue Alert 💳</h2>
                      <p>A payment is now ${daysOverdue} day(s) overdue and may require intervention.</p>
                      
                      <div style="background-color: #f8f9fa; padding: 20px; border-radius: 8px; margin: 20px 0;">
                        <h3 style="margin-top: 0; color: #333;">Transaction Details:</h3>
                        <p><strong>Vehicle:</strong> ${vehicleName}</p>
                        <p><strong>Dealer (Buyer):</strong> ${dealerName}</p>
                        <p><strong>Transporter (Seller):</strong> ${transporterName}</p>
                        <p><strong>Amount:</strong> R${offerAmount.toLocaleString()}</p>
                        <p><strong>Days Overdue:</strong> ${daysOverdue}</p>
                        <p><strong>Urgency Level:</strong> ${urgencyLevel.toUpperCase()}</p>
                      </div>
                      
                      <div style="background-color: #f8d7da; padding: 15px; border-radius: 8px; margin: 20px 0; border-left: 4px solid #dc3545;">
                        <h4 style="margin-top: 0; color: #721c24;">Action Required:</h4>
                        <p style="margin: 5px 0;">• Contact the dealer to follow up on payment</p>
                        <p style="margin: 5px 0;">• Verify if proof of payment has been uploaded</p>
                        <p style="margin: 5px 0;">• Consider offer cancellation if payment policy is violated</p>
                        <p style="margin: 5px 0;">• Update both parties on resolution</p>
                      </div>
                      
                      <div style="text-align: center; margin: 30px 0;">
                        <a href="${offerLink}" 
                           style="background-color: #dc3545; color: white; padding: 12px 24px; text-decoration: none; border-radius: 5px; display: inline-block;">
                          Review Offer Details
                        </a>
                      </div>
                      
                      <p style="color: #666; font-size: 14px;">
                        This alert was automatically generated based on payment policy timeframes.
                      </p>
                      
                      <p>Commercial Trader Portal System</p>
                    </div>
                  `,
                });

                console.log(
                  `[sendInvoicePaymentReminders] Admin alert sent to ${adminEmails.length} admins`
                );
              } catch (emailError) {
                console.error(
                  "[sendInvoicePaymentReminders] Error sending admin alert:",
                  emailError
                );
              }
            }
          }

          // Update the last reminder timestamp
          await db
            .collection("offers")
            .doc(offerId)
            .update({
              [lastReminderField]: admin.firestore.FieldValue.serverTimestamp(),
            });

          reminderCount++;
        } catch (offerError) {
          console.error(
            `[sendInvoicePaymentReminders] Error processing offer ${offerId}:`,
            offerError
          );
        }
      }

      console.log(
        `[sendInvoicePaymentReminders] Job completed. Sent ${reminderCount} payment reminders.`
      );
    } catch (error) {
      console.error(
        "[sendInvoicePaymentReminders] Error in scheduled job:",
        error
      );
    }
  }
);

// Notify transporter when truck is ready for collection (payment approved + collection details set)
exports.notifyTransporterOnTruckReadyForCollection = onDocumentUpdated(
  {
    document: "offers/{offerId}",
    region: "us-central1",
  },
  async (event) => {
    console.log(
      "[notifyTransporterOnTruckReadyForCollection] Triggered for offerId:",
      event.params.offerId
    );

    const before = event.data.before.data();
    const after = event.data.after.data();
    const offerId = event.params.offerId;

    if (!before || !after) {
      console.log(
        "[notifyTransporterOnTruckReadyForCollection] No before/after data"
      );
      return;
    }

    // Check if truck is now ready for collection
    // Requirements: Payment approved + collection details set
    const paymentApproved =
      after.paymentStatus === "approved" ||
      after.paymentStatus === "accepted" ||
      after.offerStatus === "paid";
    const hasCollectionDetails = !!(
      after.dealerSelectedCollectionDate &&
      after.dealerSelectedCollectionTime &&
      after.dealerSelectedCollectionLocation
    );

    // Check if this is a new state (wasn't ready before but is ready now)
    const wasPaymentApproved =
      before.paymentStatus === "approved" ||
      before.paymentStatus === "accepted" ||
      before.offerStatus === "paid";
    const hadCollectionDetails = !!(
      before.dealerSelectedCollectionDate &&
      before.dealerSelectedCollectionTime &&
      before.dealerSelectedCollectionLocation
    );

    const wasReady = wasPaymentApproved && hadCollectionDetails;
    const isNowReady = paymentApproved && hasCollectionDetails;

    // Only notify if truck just became ready for collection
    if (wasReady || !isNowReady) {
      console.log(
        "[notifyTransporterOnTruckReadyForCollection] Truck not newly ready for collection, skipping",
        { wasReady, isNowReady, paymentApproved, hasCollectionDetails }
      );
      return;
    }

    console.log(
      "[notifyTransporterOnTruckReadyForCollection] Truck is now ready for collection!"
    );

    try {
      // Get transporter details (the one who needs to collect)
      const transporterDoc = await db
        .collection("users")
        .doc(after.transporterId)
        .get();
      const transporterData = transporterDoc.exists
        ? transporterDoc.data()
        : {};
      const transporterName =
        `${transporterData.firstName || ""} ${
          transporterData.lastName || ""
        }`.trim() ||
        transporterData.companyName ||
        "Transporter";
      const transporterEmail = transporterData.email;

      // Get dealer details
      const dealerDoc = await db.collection("users").doc(after.dealerId).get();
      const dealerData = dealerDoc.exists ? dealerDoc.data() : {};
      const dealerName =
        `${dealerData.firstName || ""} ${dealerData.lastName || ""}`.trim() ||
        dealerData.companyName ||
        "Dealer";

      // Get vehicle details
      const vehicleDoc = await db
        .collection("vehicles")
        .doc(after.vehicleId)
        .get();
      const vehicleData = vehicleDoc.exists ? vehicleDoc.data() : {};
      const vehicleName = `${
        vehicleData.brands?.join(", ") || vehicleData.brand || "Vehicle"
      } ${vehicleData.makeModel || vehicleData.model || ""} ${
        vehicleData.year || ""
      }`.trim();

      // Format collection details
      const collectionDate = after.dealerSelectedCollectionDate.toDate
        ? after.dealerSelectedCollectionDate.toDate().toLocaleDateString()
        : new Date(after.dealerSelectedCollectionDate).toLocaleDateString();
      const collectionTime = after.dealerSelectedCollectionTime;
      const collectionLocation = after.dealerSelectedCollectionLocation;
      const offerAmount = after.offerAmount || 0;

      // Notify transporter (primary notification)
      if (transporterData.fcmToken) {
        try {
          const transporterMessage = {
            notification: {
              title: "🚛 Truck Ready for Collection!",
              body: `Great news! Your ${vehicleName} is ready for collection. Payment confirmed. Collection on ${collectionDate} at ${collectionTime}`,
            },
            data: {
              offerId: offerId,
              vehicleId: after.vehicleId,
              dealerId: after.dealerId,
              notificationType: "truck_ready_for_collection",
              collectionDate: collectionDate,
              collectionTime: collectionTime,
              collectionLocation: collectionLocation,
              offerAmount: String(offerAmount),
              timestamp: new Date().toISOString(),
            },
            token: transporterData.fcmToken,
          };

          await admin.messaging().send(transporterMessage);
          console.log(
            `[notifyTransporterOnTruckReadyForCollection] Notification sent to transporter ${after.transporterId}`
          );
        } catch (transporterError) {
          console.error(
            `[notifyTransporterOnTruckReadyForCollection] Error sending notification to transporter:`,
            transporterError
          );
        }
      }

      // Also notify admins for tracking
      const adminUsersSnapshot = await db
        .collection("users")
        .where("userRole", "in", ["admin", "sales representative"])
        .get();

      for (const adminDoc of adminUsersSnapshot.docs) {
        const adminData = adminDoc.data();
        if (!adminData.fcmToken) continue;

        try {
          const adminMessage = {
            notification: {
              title: "🚚 Collection Ready",
              body: `${transporterName}'s (seller) ${vehicleName} is ready for collection by ${dealerName} (buyer). Payment confirmed, collection scheduled.`,
            },
            data: {
              offerId: offerId,
              vehicleId: after.vehicleId,
              dealerId: after.dealerId,
              transporterId: after.transporterId,
              notificationType: "truck_ready_for_collection_admin",
              collectionDate: collectionDate,
              collectionTime: collectionTime,
              timestamp: new Date().toISOString(),
            },
            token: adminData.fcmToken,
          };

          await admin.messaging().send(adminMessage);
        } catch (adminError) {
          console.error(
            `[notifyTransporterOnTruckReadyForCollection] Error sending admin notification:`,
            adminError
          );
        }
      }

      // Send email notification if SendGrid is available
      if (sgMail && transporterEmail) {
        try {
          const offerLink = `https://ctpapp.co.za/offer/${offerId}`;

          await sgMail.send({
            from: "admin@ctpapp.co.za",
            to: transporterEmail,
            subject: `🚛 Your Vehicle is Ready for Collection - ${vehicleName}`,
            html: `
              <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto;">
                <div style="background-color: #28a745; color: white; padding: 20px; text-align: center; border-radius: 8px 8px 0 0;">
                  <h2 style="margin: 0; font-size: 28px;">🚛 Ready for Collection!</h2>
                </div>
                
                <div style="padding: 30px; border: 1px solid #ddd; border-top: none; border-radius: 0 0 8px 8px;">
                  <p style="font-size: 18px; color: #28a745; font-weight: bold;">Excellent news, ${transporterName}!</p>
                  <p style="font-size: 16px;">Your vehicle sale has been completed and your truck is now ready for collection.</p>
                  
                  <div style="background-color: #f8f9fa; padding: 25px; border-radius: 8px; margin: 25px 0;">
                    <h3 style="margin-top: 0; color: #333; border-bottom: 2px solid #28a745; padding-bottom: 10px;">Collection Details:</h3>
                    <div style="display: grid; gap: 10px;">
                      <p style="margin: 8px 0;"><strong>🚛 Vehicle:</strong> ${vehicleName}</p>
                      <p style="margin: 8px 0;"><strong>💰 Sale Amount:</strong> R${offerAmount.toLocaleString()}</p>
                      <p style="margin: 8px 0;"><strong>📅 Collection Date:</strong> ${collectionDate}</p>
                      <p style="margin: 8px 0;"><strong>🕐 Collection Time:</strong> ${collectionTime}</p>
                      <p style="margin: 8px 0;"><strong>📍 Collection Location:</strong> ${collectionLocation}</p>
                    </div>
                  </div>
                  
                  <div style="background-color: #d4edda; padding: 20px; border-radius: 8px; margin: 25px 0; border-left: 4px solid #28a745;">
                    <h4 style="margin-top: 0; color: #155724;">✅ Payment Confirmed</h4>
                    <p style="margin: 5px 0; color: #155724;">The buyer's payment has been approved and processed. You can now proceed with confidence to collect your vehicle.</p>
                  </div>
                  
                  <div style="background-color: #fff3cd; padding: 20px; border-radius: 8px; margin: 25px 0; border-left: 4px solid #ffc107;">
                    <h4 style="margin-top: 0; color: #856404;">📋 Collection Checklist:</h4>
                    <ul style="margin: 10px 0; padding-left: 20px; color: #856404;">
                      <li>Arrive at the specified time and location</li>
                      <li>Bring valid identification and vehicle documentation</li>
                      <li>Ensure the vehicle is in the agreed condition</li>
                      <li>Complete any final paperwork with the buyer</li>
                      <li>Hand over keys and vehicle to the new owner</li>
                    </ul>
                  </div>
                  
                  <div style="text-align: center; margin: 35px 0;">
                    <a href="${offerLink}" 
                       style="background-color: #28a745; color: white; padding: 15px 30px; text-decoration: none; border-radius: 5px; display: inline-block; font-weight: bold; font-size: 16px;">
                      View Collection Details
                    </a>
                  </div>
                  
                  <div style="background-color: #f8f9fa; padding: 15px; border-radius: 8px; text-align: center;">
                    <p style="margin: 0; color: #666; font-size: 14px;">
                      <strong>Need help?</strong> Contact our support team at 
                      <a href="mailto:admin@ctpapp.co.za" style="color: #28a745;">admin@ctpapp.co.za</a>
                    </p>
                  </div>
                  
                  <p style="margin-top: 30px;">Congratulations on your successful sale!</p>
                  
                  <p>Best regards,<br>
                  Commercial Trader Portal Team</p>
                </div>
              </div>
            `,
          });

          console.log(
            `[notifyTransporterOnTruckReadyForCollection] Email sent to transporter ${transporterEmail}`
          );
        } catch (emailError) {
          console.error(
            "[notifyTransporterOnTruckReadyForCollection] Error sending email:",
            emailError
          );
        }
      }

      // Send email to admins for tracking
      if (sgMail) {
        const adminEmails = adminUsersSnapshot.docs
          .map((doc) => doc.data().email)
          .filter((email) => !!email);

        if (adminEmails.length > 0) {
          try {
            const offerLink = `https://ctpapp.co.za/offer/${offerId}`;

            await sgMail.send({
              from: "admin@ctpapp.co.za",
              to: adminEmails,
              subject: `🚚 Vehicle Ready for Collection - ${vehicleName}`,
              html: `
                <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto;">
                  <h2 style="color: #28a745;">Vehicle Ready for Collection 🚚</h2>
                  <p>A vehicle transaction has been completed and is ready for collection.</p>
                  
                  <div style="background-color: #f8f9fa; padding: 20px; border-radius: 8px; margin: 20px 0;">
                    <h3 style="margin-top: 0; color: #333;">Transaction Summary:</h3>
                    <p><strong>Vehicle:</strong> ${vehicleName}</p>
                    <p><strong>Seller (Transporter):</strong> ${transporterName}</p>
                    <p><strong>Buyer (Dealer):</strong> ${dealerName}</p>
                    <p><strong>Sale Amount:</strong> R${offerAmount.toLocaleString()}</p>
                    <p><strong>Collection Date:</strong> ${collectionDate}</p>
                    <p><strong>Collection Time:</strong> ${collectionTime}</p>
                    <p><strong>Collection Location:</strong> ${collectionLocation}</p>
                  </div>
                  
                  <div style="background-color: #d4edda; padding: 15px; border-radius: 8px; margin: 20px 0; border-left: 4px solid #28a745;">
                    <h4 style="margin-top: 0; color: #155724;">Status: Ready for Collection</h4>
                    <p style="margin: 5px 0;">✅ Payment has been approved and processed</p>
                    <p style="margin: 5px 0;">✅ Collection details have been confirmed</p>
                    <p style="margin: 5px 0;">✅ Transporter has been notified</p>
                  </div>
                  
                  <div style="text-align: center; margin: 30px 0;">
                    <a href="${offerLink}" 
                       style="background-color: #28a745; color: white; padding: 12px 24px; text-decoration: none; border-radius: 5px; display: inline-block;">
                      View Transaction Details
                    </a>
                  </div>
                  
                  <p style="color: #666; font-size: 14px;">
                    This notification is for your tracking and oversight. The transaction is proceeding normally.
                  </p>
                  
                  <p>Commercial Trader Portal System</p>
                </div>
              `,
            });

            console.log(
              `[notifyTransporterOnTruckReadyForCollection] Admin email sent to ${adminEmails.length} admins`
            );
          } catch (emailError) {
            console.error(
              "[notifyTransporterOnTruckReadyForCollection] Error sending admin email:",
              emailError
            );
          }
        }
      }
    } catch (error) {
      console.error(
        "[notifyTransporterOnTruckReadyForCollection] Error:",
        error
      );
    }
  }
);

// Notify transporter, dealer, and admins when collection is booked
exports.notifyPartiesOnCollectionBooked = onDocumentUpdated(
  {
    document: "offers/{offerId}",
    region: "us-central1",
  },
  async (event) => {
    console.log(
      "[notifyPartiesOnCollectionBooked] Triggered for offerId:",
      event.params.offerId
    );

    const before = event.data.before.data();
    const after = event.data.after.data();
    const offerId = event.params.offerId;

    if (!before || !after) {
      console.log("[notifyPartiesOnCollectionBooked] No before/after data");
      return;
    }

    // Check if collection details were just added/updated
    const beforeHasCollection = !!(
      before.dealerSelectedCollectionDate &&
      before.dealerSelectedCollectionTime &&
      before.dealerSelectedCollectionLocation
    );

    const afterHasCollection = !!(
      after.dealerSelectedCollectionDate &&
      after.dealerSelectedCollectionTime &&
      after.dealerSelectedCollectionLocation
    );

    // Only notify if collection was just booked (not already there)
    if (beforeHasCollection || !afterHasCollection) {
      console.log(
        "[notifyPartiesOnCollectionBooked] Collection not newly booked, skipping"
      );
      return;
    }

    console.log(
      "[notifyPartiesOnCollectionBooked] New collection booking detected"
    );

    try {
      // Get dealer details
      const dealerDoc = await db.collection("users").doc(after.dealerId).get();
      const dealerData = dealerDoc.exists ? dealerDoc.data() : {};
      const dealerName =
        `${dealerData.firstName || ""} ${dealerData.lastName || ""}`.trim() ||
        dealerData.companyName ||
        "Dealer";
      const dealerEmail = dealerData.email;

      // Get transporter details
      const transporterDoc = await db
        .collection("users")
        .doc(after.transporterId)
        .get();
      const transporterData = transporterDoc.exists
        ? transporterDoc.data()
        : {};
      const transporterName =
        `${transporterData.firstName || ""} ${
          transporterData.lastName || ""
        }`.trim() ||
        transporterData.companyName ||
        "Transporter";
      const transporterEmail = transporterData.email;

      // Get vehicle details
      const vehicleDoc = await db
        .collection("vehicles")
        .doc(after.vehicleId)
        .get();
      const vehicleData = vehicleDoc.exists ? vehicleDoc.data() : {};
      const vehicleName = `${
        vehicleData.brands?.join(", ") || vehicleData.brand || "Vehicle"
      } ${vehicleData.makeModel || vehicleData.model || ""} ${
        vehicleData.year || ""
      }`.trim();

      // Format collection details
      const collectionDate = after.dealerSelectedCollectionDate.toDate
        ? after.dealerSelectedCollectionDate.toDate().toLocaleDateString()
        : new Date(after.dealerSelectedCollectionDate).toLocaleDateString();
      const collectionTime = after.dealerSelectedCollectionTime;
      const collectionLocation = after.dealerSelectedCollectionLocation;
      const offerAmount = after.offerAmount || 0;

      // Notify transporter (vehicle owner)
      if (transporterData.fcmToken) {
        try {
          const transporterMessage = {
            notification: {
              title: "📅 Collection Scheduled",
              body: `A collection appointment for your ${vehicleName} has been scheduled on ${collectionDate} at ${collectionTime}`,
            },
            data: {
              offerId: offerId,
              vehicleId: after.vehicleId,
              dealerId: after.dealerId,
              notificationType: "collection_booked",
              collectionDate: collectionDate,
              collectionTime: collectionTime,
              collectionLocation: collectionLocation,
              timestamp: new Date().toISOString(),
            },
            token: transporterData.fcmToken,
          };

          await admin.messaging().send(transporterMessage);
          console.log(
            `[notifyPartiesOnCollectionBooked] Notification sent to transporter ${after.transporterId}`
          );
        } catch (transporterError) {
          console.error(
            `[notifyPartiesOnCollectionBooked] Error sending notification to transporter:`,
            transporterError
          );
        }
      }

      // Notify dealer (confirmation)
      if (dealerData.fcmToken) {
        try {
          const dealerMessage = {
            notification: {
              title: "✅ Collection Confirmed",
              body: `Your collection appointment for ${vehicleName} has been scheduled for ${collectionDate} at ${collectionTime}`,
            },
            data: {
              offerId: offerId,
              vehicleId: after.vehicleId,
              transporterId: after.transporterId,
              notificationType: "collection_booked_confirmation",
              collectionDate: collectionDate,
              collectionTime: collectionTime,
              collectionLocation: collectionLocation,
              timestamp: new Date().toISOString(),
            },
            token: dealerData.fcmToken,
          };

          await admin.messaging().send(dealerMessage);
          console.log(
            `[notifyPartiesOnCollectionBooked] Confirmation sent to dealer ${after.dealerId}`
          );
        } catch (dealerError) {
          console.error(
            `[notifyPartiesOnCollectionBooked] Error sending confirmation to dealer:`,
            dealerError
          );
        }
      }

      // Get all admin users for notifications
      const adminUsersSnapshot = await db
        .collection("users")
        .where("userRole", "in", ["admin", "sales representative"])
        .get();

      // Notify admins
      if (!adminUsersSnapshot.empty) {
        for (const adminDoc of adminUsersSnapshot.docs) {
          const adminData = adminDoc.data();

          if (!adminData.fcmToken) {
            console.log(
              `[notifyPartiesOnCollectionBooked] Admin ${adminDoc.id} has no FCM token`
            );
            continue;
          }

          try {
            const adminMessage = {
              notification: {
                title: "📋 Collection Scheduled",
                body: `${dealerName} (buyer) scheduled collection for ${transporterName}'s (seller) ${vehicleName} on ${collectionDate}`,
              },
              data: {
                offerId: offerId,
                vehicleId: after.vehicleId,
                dealerId: after.dealerId,
                transporterId: after.transporterId,
                notificationType: "collection_booked_admin",
                collectionDate: collectionDate,
                collectionTime: collectionTime,
                collectionLocation: collectionLocation,
                timestamp: new Date().toISOString(),
              },
              token: adminData.fcmToken,
            };

            await admin.messaging().send(adminMessage);
            console.log(
              `[notifyPartiesOnCollectionBooked] Notification sent to admin ${adminDoc.id}`
            );
          } catch (adminError) {
            console.error(
              `[notifyPartiesOnCollectionBooked] Error sending notification to admin ${adminDoc.id}:`,
              adminError
            );
          }
        }
      }

      // Send email notifications if SendGrid is available
      if (sgMail) {
        const offerLink = `https://ctpapp.co.za/offer/${offerId}`;

        // Email to transporter
        if (transporterEmail) {
          try {
            await sgMail.send({
              from: "admin@ctpapp.co.za",
              to: transporterEmail,
              subject: `📅 Collection Scheduled - ${vehicleName}`,
              html: `
                <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto;">
                  <h2 style="color: #2F7FFF;">Collection Appointment Scheduled 📅</h2>
                  <p>Great news! A collection appointment has been scheduled for your vehicle.</p>
                  
                  <div style="background-color: #f8f9fa; padding: 20px; border-radius: 8px; margin: 20px 0;">
                    <h3 style="margin-top: 0; color: #333;">Collection Details:</h3>
                    <p><strong>Vehicle:</strong> ${vehicleName}</p>
                    <p><strong>Sale Amount:</strong> R${offerAmount.toLocaleString()}</p>
                    <p><strong>Collection Date:</strong> ${collectionDate}</p>
                    <p><strong>Collection Time:</strong> ${collectionTime}</p>
                    <p><strong>Collection Location:</strong> ${collectionLocation}</p>
                  </div>
                  
                  <div style="background-color: #d1ecf1; padding: 15px; border-radius: 8px; margin: 20px 0; border-left: 4px solid #17a2b8;">
                    <h4 style="margin-top: 0; color: #0c5460;">What's Next?</h4>
                    <p style="margin: 5px 0;">• Ensure your vehicle is ready for collection</p>
                    <p style="margin: 5px 0;">• Prepare all necessary documentation</p>
                    <p style="margin: 5px 0;">• Be available at the scheduled time and location</p>
                    <p style="margin: 5px 0;">• Complete the handover process with the buyer</p>
                  </div>
                  
                  <div style="background-color: #fff3cd; padding: 15px; border-radius: 8px; margin: 20px 0; border-left: 4px solid #ffc107;">
                    <h4 style="margin-top: 0; color: #856404;">💰 Payment Status</h4>
                    <p style="margin: 5px 0;">Collection can only proceed once payment has been confirmed and approved. You'll be notified when payment is complete and your vehicle is ready for collection.</p>
                  </div>
                  
                  <div style="text-align: center; margin: 30px 0;">
                    <a href="${offerLink}" 
                       style="background-color: #2F7FFF; color: white; padding: 12px 24px; text-decoration: none; border-radius: 5px; display: inline-block;">
                      View Collection Details
                    </a>
                  </div>
                  
                  <p>Best regards,<br>
                  Commercial Trader Portal Team</p>
                </div>
              `,
            });

            console.log(
              `[notifyPartiesOnCollectionBooked] Email sent to transporter ${transporterEmail}`
            );
          } catch (emailError) {
            console.error(
              "[notifyPartiesOnCollectionBooked] Error sending email to transporter:",
              emailError
            );
          }
        }

        // Email to dealer (confirmation)
        if (dealerEmail) {
          try {
            await sgMail.send({
              from: "admin@ctpapp.co.za",
              to: dealerEmail,
              subject: `✅ Collection Appointment Confirmed - ${vehicleName}`,
              html: `
                <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto;">
                  <h2 style="color: #28a745;">Collection Appointment Confirmed ✅</h2>
                  <p>Your collection appointment has been successfully scheduled. Here are the details:</p>
                  
                  <div style="background-color: #f8f9fa; padding: 20px; border-radius: 8px; margin: 20px 0;">
                    <h3 style="margin-top: 0; color: #333;">Appointment Details:</h3>
                    <p><strong>Vehicle:</strong> ${vehicleName}</p>
                    <p><strong>Seller:</strong> ${transporterName}</p>
                    <p><strong>Purchase Amount:</strong> R${offerAmount.toLocaleString()}</p>
                    <p><strong>Collection Date:</strong> ${collectionDate}</p>
                    <p><strong>Collection Time:</strong> ${collectionTime}</p>
                    <p><strong>Collection Location:</strong> ${collectionLocation}</p>
                  </div>
                  
                  <div style="background-color: #d4edda; padding: 15px; border-radius: 8px; margin: 20px 0; border-left: 4px solid #28a745;">
                    <h4 style="margin-top: 0; color: #155724;">Preparation Checklist:</h4>
                    <p style="margin: 5px 0;">• Complete payment before collection date</p>
                    <p style="margin: 5px 0;">• Bring valid identification and documentation</p>
                    <p style="margin: 5px 0;">• Arrive on time for your scheduled appointment</p>
                    <p style="margin: 5px 0;">• Inspect the vehicle thoroughly before taking possession</p>
                    <p style="margin: 5px 0;">• Complete all necessary paperwork with the seller</p>
                  </div>
                  
                  <div style="background-color: #fff3cd; padding: 15px; border-radius: 8px; margin: 20px 0; border-left: 4px solid #ffc107;">
                    <h4 style="margin-top: 0; color: #856404;">⚠️ Important Reminder</h4>
                    <p style="margin: 5px 0;">Payment must be completed and approved before collection can proceed. Ensure all payment processes are finalized before your appointment.</p>
                  </div>
                  
                  <div style="text-align: center; margin: 30px 0;">
                    <a href="${offerLink}" 
                       style="background-color: #28a745; color: white; padding: 12px 24px; text-decoration: none; border-radius: 5px; display: inline-block;">
                      View Appointment Details
                    </a>
                  </div>
                  
                  <p>Best regards,<br>
                  Commercial Trader Portal Team</p>
                </div>
              `,
            });

            console.log(
              `[notifyPartiesOnCollectionBooked] Confirmation email sent to dealer ${dealerEmail}`
            );
          } catch (emailError) {
            console.error(
              "[notifyPartiesOnCollectionBooked] Error sending confirmation email to dealer:",
              emailError
            );
          }
        }

        // Email to admins
        const adminEmails = adminUsersSnapshot.docs
          .map((doc) => doc.data().email)
          .filter((email) => !!email);

        if (adminEmails.length > 0) {
          try {
            await sgMail.send({
              from: "admin@ctpapp.co.za",
              to: adminEmails,
              subject: `📋 Collection Appointment Scheduled - ${vehicleName}`,
              html: `
                <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto;">
                  <h2 style="color: #2F7FFF;">Collection Appointment Scheduled 📋</h2>
                  <p>A collection appointment has been scheduled for a vehicle transaction.</p>
                  
                  <div style="background-color: #f8f9fa; padding: 20px; border-radius: 8px; margin: 20px 0;">
                    <h3 style="margin-top: 0; color: #333;">Appointment Summary:</h3>
                    <p><strong>Vehicle:</strong> ${vehicleName}</p>
                    <p><strong>Seller (Transporter):</strong> ${transporterName}</p>
                    <p><strong>Buyer (Dealer):</strong> ${dealerName}</p>
                    <p><strong>Sale Amount:</strong> R${offerAmount.toLocaleString()}</p>
                    <p><strong>Collection Date:</strong> ${collectionDate}</p>
                    <p><strong>Collection Time:</strong> ${collectionTime}</p>
                    <p><strong>Collection Location:</strong> ${collectionLocation}</p>
                  </div>
                  
                  <div style="background-color: #d1ecf1; padding: 15px; border-radius: 8px; margin: 20px 0; border-left: 4px solid #17a2b8;">
                    <h4 style="margin-top: 0; color: #0c5460;">Transaction Status:</h4>
                    <p style="margin: 5px 0;">✅ Collection appointment scheduled</p>
                    <p style="margin: 5px 0;">📋 Both parties have been notified</p>
                    <p style="margin: 5px 0;">💰 Payment completion required before collection</p>
                    <p style="margin: 5px 0;">📞 Monitor for any reported issues</p>
                  </div>
                  
                  <div style="text-align: center; margin: 30px 0;">
                    <a href="${offerLink}" 
                       style="background-color: #2F7FFF; color: white; padding: 12px 24px; text-decoration: none; border-radius: 5px; display: inline-block;">
                      View Transaction Details
                    </a>
                  </div>
                  
                  <p style="color: #666; font-size: 14px;">
                    This is for your information and tracking purposes. Monitor the transaction for successful completion.
                  </p>
                  
                  <p>Best regards,<br>
                  Commercial Trader Portal System</p>
                </div>
              `,
            });

            console.log(
              `[notifyPartiesOnCollectionBooked] Email notification sent to ${adminEmails.length} admins`
            );
          } catch (emailError) {
            console.error(
              "[notifyPartiesOnCollectionBooked] Error sending email to admins:",
              emailError
            );
          }
        }
      }
    } catch (error) {
      console.error("[notifyPartiesOnCollectionBooked] Error:", error);
    }
  }
);

// Notify transporter (seller) to set up collection availability when an offer is accepted
exports.notifyTransporterToSetupCollectionOnOfferAccepted = onDocumentUpdated(
  {
    document: "offers/{offerId}",
    region: "us-central1",
  },
  async (event) => {
    console.log(
      "[notifyTransporterToSetupCollectionOnOfferAccepted] Triggered for offerId:",
      event.params.offerId
    );

    const before = event.data.before.data();
    const after = event.data.after.data();
    const offerId = event.params.offerId;

    if (!before || !after) {
      console.log(
        "[notifyTransporterToSetupCollectionOnOfferAccepted] No before/after data"
      );
      return;
    }

    // Skip locked/collected/completed offers
    const afterStatus = (after.offerStatus || "").toLowerCase();
    if (
      after.statusLocked === true ||
      after.transactionComplete === true ||
      afterStatus === "collected" ||
      afterStatus === "completed" ||
      afterStatus === "sold"
    ) {
      console.log(
        "[notifyTransporterToSetupCollectionOnOfferAccepted] Offer locked/completed, skipping"
      );
      return;
    }

    const beforeStatus = (before.offerStatus || "").toLowerCase();
    const justAccepted =
      beforeStatus !== "accepted" && afterStatus === "accepted";

    // Only prompt if collection availability hasn't been provided yet
    const beforeLocations = before.collectionDetails?.locations || [];
    const afterLocations = after.collectionDetails?.locations || [];
    const collectionNotProvided =
      !afterLocations || afterLocations.length === 0;

    if (!justAccepted || !collectionNotProvided) {
      console.log(
        "[notifyTransporterToSetupCollectionOnOfferAccepted] Conditions not met",
        { justAccepted, collectionNotProvided }
      );
      return;
    }

    try {
      // Resolve transporterId: prefer offer.transporterId, else vehicle.userId
      let transporterId = after.transporterId;
      if (!transporterId && after.vehicleId) {
        const vehicleDoc = await db
          .collection("vehicles")
          .doc(after.vehicleId)
          .get();
        if (vehicleDoc.exists) {
          transporterId = vehicleDoc.data().userId;
        }
      }

      if (!transporterId) {
        console.log(
          "[notifyTransporterToSetupCollectionOnOfferAccepted] No transporterId found"
        );
        return;
      }

      // Fetch transporter and vehicle for context
      const [transporterDoc, vehicleDoc] = await Promise.all([
        db.collection("users").doc(transporterId).get(),
        db.collection("vehicles").doc(after.vehicleId).get(),
      ]);

      if (!transporterDoc.exists) {
        console.log(
          "[notifyTransporterToSetupCollectionOnOfferAccepted] Transporter not found:",
          transporterId
        );
        return;
      }

      const transporterData = transporterDoc.data();
      if (!transporterData.fcmToken) {
        console.log(
          "[notifyTransporterToSetupCollectionOnOfferAccepted] Transporter has no FCM token"
        );
        return;
      }

      const vehicleData = vehicleDoc.exists ? vehicleDoc.data() : {};
      const vehicleName = `${
        vehicleData.brands?.join(", ") || vehicleData.brand || "Vehicle"
      } ${vehicleData.makeModel || vehicleData.model || ""} ${
        vehicleData.year || ""
      }`.trim();

      const message = {
        notification: {
          title: "Set Up Collection Availability",
          body: `Your offer was accepted. Provide collection dates and a location for ${vehicleName} so the buyer can select a slot.`,
        },
        data: {
          offerId: offerId,
          vehicleId: after.vehicleId,
          dealerId: after.dealerId || "",
          notificationType: "collection_setup_needed",
          timestamp: new Date().toISOString(),
        },
        token: transporterData.fcmToken,
      };

      await admin.messaging().send(message);
      console.log(
        `[notifyTransporterToSetupCollectionOnOfferAccepted] Prompt sent to transporter ${transporterId}`
      );
    } catch (error) {
      console.error(
        "[notifyTransporterToSetupCollectionOnOfferAccepted] Error:",
        error
      );
    }
  }
);

// Notify dealer (buyer) when collection availability has been provided by the transporter
exports.notifyDealerOnCollectionSetupReady = onDocumentUpdated(
  {
    document: "offers/{offerId}",
    region: "us-central1",
  },
  async (event) => {
    console.log(
      "[notifyDealerOnCollectionSetupReady] Triggered for offerId:",
      event.params.offerId
    );

    const before = event.data.before.data();
    const after = event.data.after.data();
    const offerId = event.params.offerId;

    if (!before || !after) {
      console.log("[notifyDealerOnCollectionSetupReady] No before/after data");
      return;
    }

    // Skip if already booked by dealer
    const dealerHasSelection = !!(
      after.dealerSelectedCollectionDate &&
      after.dealerSelectedCollectionTime &&
      after.dealerSelectedCollectionLocation
    );
    if (dealerHasSelection) {
      console.log(
        "[notifyDealerOnCollectionSetupReady] Dealer already selected collection, skipping"
      );
      return;
    }

    // Detect first time collection options are provided
    const beforeLocations = before.collectionDetails?.locations || [];
    const afterLocations = after.collectionDetails?.locations || [];
    const locationsBecameAvailable =
      (!beforeLocations || beforeLocations.length === 0) &&
      Array.isArray(afterLocations) &&
      afterLocations.length > 0;

    // Also consider collectionLocation top-level being set for the first time
    const collectionLocationSetNow =
      !before.collectionLocation && !!after.collectionLocation;

    if (!locationsBecameAvailable && !collectionLocationSetNow) {
      console.log(
        "[notifyDealerOnCollectionSetupReady] No new collection availability detected"
      );
      return;
    }

    try {
      // Fetch dealer and vehicle
      const [dealerDoc, vehicleDoc] = await Promise.all([
        db.collection("users").doc(after.dealerId).get(),
        db.collection("vehicles").doc(after.vehicleId).get(),
      ]);

      if (!dealerDoc.exists) {
        console.log(
          "[notifyDealerOnCollectionSetupReady] Dealer not found:",
          after.dealerId
        );
        return;
      }

      const dealerData = dealerDoc.data();
      if (!dealerData.fcmToken) {
        console.log(
          "[notifyDealerOnCollectionSetupReady] Dealer has no FCM token"
        );
        return;
      }

      const vehicleData = vehicleDoc.exists ? vehicleDoc.data() : {};
      const vehicleName = `${
        vehicleData.brands?.join(", ") || vehicleData.brand || "Vehicle"
      } ${vehicleData.makeModel || vehicleData.model || ""} ${
        vehicleData.year || ""
      }`.trim();

      const message = {
        notification: {
          title: "Select Your Collection Slot",
          body: `The seller has provided collection options for ${vehicleName}. Choose your preferred date and time.`,
        },
        data: {
          offerId: offerId,
          vehicleId: after.vehicleId,
          transporterId: after.transporterId || "",
          notificationType: "collection_setup_ready",
          timestamp: new Date().toISOString(),
        },
        token: dealerData.fcmToken,
      };

      await admin.messaging().send(message);
      console.log(
        `[notifyDealerOnCollectionSetupReady] Notification sent to dealer ${after.dealerId}`
      );
    } catch (error) {
      console.error("[notifyDealerOnCollectionSetupReady] Error:", error);
    }
  }
);

// Send daily inspection reminders to dealers and transporters for today's inspections
exports.sendTodayInspectionReminders = onSchedule(
  {
    schedule: "0 8 * * *", // Daily at 8 AM
    timeZone: "Africa/Johannesburg",
    region: "us-central1",
  },
  async (event) => {
    console.log(
      "[sendTodayInspectionReminders] Starting inspection reminder job"
    );

    try {
      // Get today's date at start and end of day in South Africa timezone
      const today = new Date();
      const startOfDay = new Date(
        today.getFullYear(),
        today.getMonth(),
        today.getDate()
      );
      const endOfDay = new Date(
        today.getFullYear(),
        today.getMonth(),
        today.getDate(),
        23,
        59,
        59
      );

      console.log(
        `[sendTodayInspectionReminders] Checking for inspections on ${startOfDay.toDateString()}`
      );

      // Get all offers that have inspection appointments scheduled for today
      const offersSnapshot = await db
        .collection("offers")
        .where("dealerSelectedInspectionDate", ">=", startOfDay)
        .where("dealerSelectedInspectionDate", "<=", endOfDay)
        .get();

      if (offersSnapshot.empty) {
        console.log(
          "[sendTodayInspectionReminders] No inspections scheduled for today"
        );
        return;
      }

      console.log(
        `[sendTodayInspectionReminders] Found ${offersSnapshot.docs.length} inspections scheduled for today`
      );

      let reminderCount = 0;

      for (const offerDoc of offersSnapshot.docs) {
        const offerData = offerDoc.data();
        const offerId = offerDoc.id;

        // Skip if inspection is already completed
        if (
          offerData.inspectionStatus === "completed" ||
          offerData.dealerInspectionComplete === true ||
          offerData.transporterInspectionComplete === true
        ) {
          console.log(
            `[sendTodayInspectionReminders] Inspection ${offerId} already completed, skipping`
          );
          continue;
        }

        try {
          // Get dealer details
          const dealerDoc = await db
            .collection("users")
            .doc(offerData.dealerId)
            .get();
          const dealerData = dealerDoc.exists ? dealerDoc.data() : {};
          const dealerName =
            `${dealerData.firstName || ""} ${
              dealerData.lastName || ""
            }`.trim() ||
            dealerData.companyName ||
            "Dealer";
          const dealerEmail = dealerData.email;

          // Get transporter details
          const transporterDoc = await db
            .collection("users")
            .doc(offerData.transporterId)
            .get();
          const transporterData = transporterDoc.exists
            ? transporterDoc.data()
            : {};
          const transporterName =
            `${transporterData.firstName || ""} ${
              transporterData.lastName || ""
            }`.trim() ||
            transporterData.companyName ||
            "Transporter";
          const transporterEmail = transporterData.email;

          // Get vehicle details
          const vehicleDoc = await db
            .collection("vehicles")
            .doc(offerData.vehicleId)
            .get();
          const vehicleData = vehicleDoc.exists ? vehicleDoc.data() : {};
          const vehicleName = `${
            vehicleData.brands?.join(", ") || vehicleData.brand || "Vehicle"
          } ${vehicleData.makeModel || vehicleData.model || ""} ${
            vehicleData.year || ""
          }`.trim();

          // Format inspection details
          const inspectionDate = offerData.dealerSelectedInspectionDate.toDate
            ? offerData.dealerSelectedInspectionDate
                .toDate()
                .toLocaleDateString()
            : new Date(
                offerData.dealerSelectedInspectionDate
              ).toLocaleDateString();
          const inspectionTime =
            offerData.dealerSelectedInspectionTime || "Time TBD";
          const inspectionLocation =
            offerData.dealerSelectedInspectionLocation || "Location TBD";
          const offerAmount = offerData.offerAmount || 0;

          // Send push notification to dealer
          if (dealerData.fcmToken) {
            try {
              const dealerMessage = {
                notification: {
                  title: "🔍 Inspection Today",
                  body: `Reminder: You have an inspection scheduled today for ${vehicleName} at ${inspectionTime}`,
                },
                data: {
                  offerId: offerId,
                  vehicleId: offerData.vehicleId,
                  transporterId: offerData.transporterId,
                  notificationType: "inspection_today_dealer",
                  inspectionDate: inspectionDate,
                  inspectionTime: inspectionTime,
                  inspectionLocation: inspectionLocation,
                  timestamp: new Date().toISOString(),
                },
                token: dealerData.fcmToken,
              };

              await admin.messaging().send(dealerMessage);
              console.log(
                `[sendTodayInspectionReminders] Push notification sent to dealer ${offerData.dealerId}`
              );
            } catch (dealerPushError) {
              console.error(
                `[sendTodayInspectionReminders] Error sending push to dealer:`,
                dealerPushError
              );
            }
          }

          // Send push notification to transporter
          if (transporterData.fcmToken) {
            try {
              const transporterMessage = {
                notification: {
                  title: "🔍 Inspection Today",
                  body: `Reminder: You have a vehicle inspection scheduled today for your ${vehicleName} at ${inspectionTime}`,
                },
                data: {
                  offerId: offerId,
                  vehicleId: offerData.vehicleId,
                  dealerId: offerData.dealerId,
                  notificationType: "inspection_today_transporter",
                  inspectionDate: inspectionDate,
                  inspectionTime: inspectionTime,
                  inspectionLocation: inspectionLocation,
                  timestamp: new Date().toISOString(),
                },
                token: transporterData.fcmToken,
              };

              await admin.messaging().send(transporterMessage);
              console.log(
                `[sendTodayInspectionReminders] Push notification sent to transporter ${offerData.transporterId}`
              );
            } catch (transporterPushError) {
              console.error(
                `[sendTodayInspectionReminders] Error sending push to transporter:`,
                transporterPushError
              );
            }
          }

          // Send email notifications if SendGrid is available
          if (sgMail) {
            const offerLink = `https://ctpapp.co.za/offer/${offerId}`;

            // Email to dealer (confirmation) - do not include transporter names
            if (dealerEmail) {
              try {
                await sgMail.send({
                  from: "admin@ctpapp.co.za",
                  to: dealerEmail,
                  subject: `🔍 Inspection Reminder - Today's Appointment for ${vehicleName}`,
                  html: `
                    <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto;">
                      <div style="background-color: #2F7FFF; color: white; padding: 20px; text-align: center; border-radius: 8px 8px 0 0;">
                        <h2 style="margin: 0; font-size: 28px;">🔍 Inspection Reminder</h2>
                      </div>
                      
                      <div style="padding: 30px; border: 1px solid #ddd; border-top: none; border-radius: 0 0 8px 8px;">
                        <p style="font-size: 18px; color: #2F7FFF; font-weight: bold;">Good morning, ${dealerName}!</p>
                        
                        <div style="background-color: #f8f9fa; padding: 25px; border-radius: 8px; margin: 25px 0;">
                          <h3 style="margin-top: 0; color: #333; border-bottom: 2px solid #2F7FFF; padding-bottom: 10px;">Today's Inspection Details:</h3>
                          <div style="display: grid; gap: 10px;">
                            <p style="margin: 8px 0;"><strong>🚛 Vehicle:</strong> ${vehicleName}</p>
                            <p style="margin: 8px 0;"><strong>👤 Seller:</strong> ${transporterName}</p>
                            <p style="margin: 8px 0;"><strong>💰 Offer Amount:</strong> R${offerAmount.toLocaleString()}</p>
                            <p style="margin: 8px 0;"><strong>📅 Date:</strong> ${inspectionDate} (Today)</p>
                            <p style="margin: 8px 0;"><strong>🕐 Time:</strong> ${inspectionTime}</p>
                            <p style="margin: 8px 0;"><strong>📍 Location:</strong> ${inspectionLocation}</p>
                          </div>
                        </div>
                        
                        <div style="background-color: #fff3cd; padding: 20px; border-radius: 8px; margin: 25px 0; border-left: 4px solid #ffc107;">
                          <h4 style="margin-top: 0; color: #856404;">📋 Pre-Inspection Checklist:</h4>
                          <ul style="margin: 10px 0; padding-left: 20px; color: #856404;">
                            <li>Arrive on time at the scheduled location</li>
                            <li>Bring necessary inspection equipment and tools</li>
                            <li>Review the vehicle's documented condition reports</li>
                            <li>Take detailed photos of any findings</li>
                            <li>Complete inspection notes and upload results promptly</li>
                          </ul>
                        </div>
                        
                        <div style="background-color: #d1ecf1; padding: 20px; border-radius: 8px; margin: 25px 0; border-left: 4px solid #17a2b8;">
                          <h4 style="margin-top: 0; color: #0c5460;">ℹ️ Important Notes:</h4>
                          <p style="margin: 5px 0; color: #0c5460;">• Contact the seller if you need to reschedule or have questions</p>
                          <p style="margin: 5px 0; color: #0c5460;">• Upload inspection results within 24 hours of completion</p>
                          <p style="margin: 5px 0; color: #0c5460;">• Both parties will be notified once inspection is complete</p>
                        </div>
                        
                        <div style="text-align: center; margin: 35px 0;">
                          <a href="${offerLink}" 
                             style="background-color: #2F7FFF; color: white; padding: 15px 30px; text-decoration: none; border-radius: 5px; display: inline-block; font-weight: bold; font-size: 16px;">
                            View Inspection Details
                          </a>
                        </div>
                        
                        <div style="background-color: #f8f9fa; padding: 15px; border-radius: 8px; text-align: center;">
                          <p style="margin: 0; color: #666; font-size: 14px;">
                            <strong>Need help?</strong> Contact our support team at 
                            <a href="mailto:admin@ctpapp.co.za" style="color: #2F7FFF;">admin@ctpapp.co.za</a>
                          </p>
                        </div>
                        
                        <p style="margin-top: 30px;">Have a successful inspection!</p>
                        
                        <p>Best regards,<br>
                        Commercial Trader Portal Team</p>
                      </div>
                    </div>
                  `,
                });

                console.log(
                  `[sendTodayInspectionReminders] Email sent to dealer ${dealerEmail}`
                );
                reminderCount++;
              } catch (dealerEmailError) {
                console.error(
                  "[sendTodayInspectionReminders] Error sending email to dealer:",
                  dealerEmailError
                );
              }
            }

            // Email to transporter
            if (transporterEmail) {
              try {
                await sgMail.send({
                  from: "admin@ctpapp.co.za",
                  to: transporterEmail,
                  subject: `🔍 Inspection Reminder - Today's Appointment for Your ${vehicleName}`,
                  html: `
                    <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto;">
                      <div style="background-color: #2F7FFF; color: white; padding: 20px; text-align: center; border-radius: 8px 8px 0 0;">
                        <h2 style="margin: 0; font-size: 28px;">🔍 Inspection Reminder</h2>
                      </div>
                      
                      <div style="padding: 30px; border: 1px solid #ddd; border-top: none; border-radius: 0 0 8px 8px;">
                        <p style="font-size: 18px; color: #2F7FFF; font-weight: bold;">Good morning, ${transporterName}!</p>
                        <p style="font-size: 16px;">This is a friendly reminder that your vehicle has an inspection scheduled for <strong>today</strong>.</p>
                        
                        <div style="background-color: #f8f9fa; padding: 25px; border-radius: 8px; margin: 25px 0;">
                          <h3 style="margin-top: 0; color: #333; border-bottom: 2px solid #2F7FFF; padding-bottom: 10px;">Today's Inspection Details:</h3>
                          <div style="display: grid; gap: 10px;">
                            <p style="margin: 8px 0;"><strong>🚛 Your Vehicle:</strong> ${vehicleName}</p>
                            <p style="margin: 8px 0;"><strong>💰 Offer Amount:</strong> R${offerAmount.toLocaleString()}</p>
                            <p style="margin: 8px 0;"><strong>📅 Date:</strong> ${inspectionDate} (Today)</p>
                            <p style="margin: 8px 0;"><strong>🕐 Time:</strong> ${inspectionTime}</p>
                            <p style="margin: 8px 0;"><strong>📍 Location:</strong> ${inspectionLocation}</p>
                          </div>
                        </div>
                        
                        <div style="background-color: #d4edda; padding: 20px; border-radius: 8px; margin: 25px 0; border-left: 4px solid #28a745;">
                          <h4 style="margin-top: 0; color: #155724;">📋 Preparation Checklist:</h4>
                          <ul style="margin: 10px 0; padding-left: 20px; color: #155724;">
                            <li>Ensure your vehicle is accessible at the inspection location</li>
                            <li>Have all vehicle documentation ready (registration, service history, etc.)</li>
                            <li>Be available to answer questions about the vehicle's history</li>
                            <li>Allow the inspector full access to examine the vehicle</li>
                            <li>Be present during the inspection process</li>
                          </ul>
                        </div>
                        
                        <div style="background-color: #fff3cd; padding: 20px; border-radius: 8px; margin: 25px 0; border-left: 4px solid #ffc107;">
                          <h4 style="margin-top: 0; color: #856404;">⚠️ Important Information:</h4>
                          <p style="margin: 5px 0; color: #856404;">• The inspection is crucial for finalizing the sale</p>
                          <p style="margin: 5px 0; color: #856404;">• Be honest about any known issues with the vehicle</p>
                          <p style="margin: 5px 0; color: #856404;">• You'll be notified once the inspection is complete</p>
                          <p style="margin: 5px 0; color: #856404;">• Contact the buyer if you need to reschedule</p>
                        </div>
                        
                        <div style="text-align: center; margin: 35px 0;">
                          <a href="${offerLink}" 
                             style="background-color: #2F7FFF; color: white; padding: 15px 30px; text-decoration: none; border-radius: 5px; display: inline-block; font-weight: bold; font-size: 16px;">
                            View Inspection Details
                          </a>
                        </div>
                        
                        <div style="background-color: #f8f9fa; padding: 15px; border-radius: 8px; text-align: center;">
                          <p style="margin: 0; color: #666; font-size: 14px;">
                            <strong>Need help?</strong> Contact our support team at 
                            <a href="mailto:admin@ctpapp.co.za" style="color: #2F7FFF;">admin@ctpapp.co.za</a>
                          </p>
                        </div>
                        
                        <p style="margin-top: 30px;">Best of luck with your vehicle sale!</p>
                        
                        <p>Best regards,<br>
                        Commercial Trader Portal Team</p>
                      </div>
                    </div>
                  `,
                });

                console.log(
                  `[sendTodayInspectionReminders] Email sent to transporter ${transporterEmail}`
                );
                reminderCount++;
              } catch (transporterEmailError) {
                console.error(
                  "[sendTodayInspectionReminders] Error sending email to transporter:",
                  transporterEmailError
                );
              }
            }
          }
        } catch (offerError) {
          console.error(
            `[sendTodayInspectionReminders] Error processing offer ${offerId}:`,
            offerError
          );
        }
      }

      console.log(
        `[sendTodayInspectionReminders] Job completed. Sent ${reminderCount} inspection reminders.`
      );
    } catch (error) {
      console.error(
        "[sendTodayInspectionReminders] Error in scheduled job:",
        error
      );
    }
  }
);

// Daily check for stalled offers: missed inspection/collection appointments -> alert admins next day
exports.sendStalledOfferAlerts = onSchedule(
  {
    schedule: "30 9 * * *", // Daily at 9:30 AM
    timeZone: "Africa/Johannesburg",
    region: "us-central1",
  },
  async () => {
    console.log("[sendStalledOfferAlerts] Starting stalled offer check");

    const startOfToday = new Date();
    startOfToday.setHours(0, 0, 0, 0);

    try {
      // 1) Missed inspections: inspection was scheduled before today but not completed
      const inspSnap = await db
        .collection("offers")
        .where("dealerSelectedInspectionDate", "<", startOfToday)
        .get();

      // 2) Missed collections: collection was scheduled before today but not completed
      const collSnap = await db
        .collection("offers")
        .where("dealerSelectedCollectionDate", "<", startOfToday)
        .get();

      let alertsSent = 0;

      const adminUsersSnapshot = await db
        .collection("users")
        .where("userRole", "in", ["admin", "sales representative"])
        .get();
      const adminPushTargets = adminUsersSnapshot.docs
        .map((d) => d.data())
        .filter((u) => !!u.fcmToken)
        .map((u) => u.fcmToken);
      const adminEmails = adminUsersSnapshot.docs
        .map((d) => d.data().email)
        .filter((e) => !!e);

      const processMissed = async (
        offerDoc,
        type /* 'inspection'|'collection' */
      ) => {
        const o = offerDoc.data();
        const offerId = offerDoc.id;

        // Skip finalized/locked offers
        const offerStatus = (o.offerStatus || "").toLowerCase();
        if (
          o.statusLocked === true ||
          o.transactionComplete === true ||
          offerStatus === "collected" ||
          offerStatus === "completed" ||
          offerStatus === "sold"
        ) {
          return;
        }

        // Determine if this stage is incomplete
        const isInspectionIncomplete = !(
          o.inspectionStatus === "completed" ||
          o.dealerInspectionComplete === true ||
          o.transporterInspectionComplete === true
        );
        const isCollectionIncomplete = !(o.collectionCompleted === true);

        const scheduledDate =
          type === "inspection"
            ? o.dealerSelectedInspectionDate
            : o.dealerSelectedCollectionDate;
        if (!scheduledDate) return;

        // Convert Firestore Timestamp or string to Date for calculations and keying
        const scheduledAt = scheduledDate.toDate
          ? scheduledDate.toDate()
          : new Date(scheduledDate);

        // Must be before today to be considered missed (we queried < startOfToday, but keep for safety)
        if (!(scheduledAt instanceof Date) || isNaN(scheduledAt.getTime()))
          return;
        if (scheduledAt >= startOfToday) return;

        // If still incomplete, notify admins once per scheduled date
        if (type === "inspection" && !isInspectionIncomplete) return;
        if (type === "collection" && !isCollectionIncomplete) return;

        const yyyy = scheduledAt.getFullYear();
        const mm = String(scheduledAt.getMonth() + 1).padStart(2, "0");
        const dd = String(scheduledAt.getDate()).padStart(2, "0");
        const dateKey = `${yyyy}-${mm}-${dd}`;
        const alertKey = `${type}_missed:${dateKey}`;

        const priorKeys = Array.isArray(o.stalledAlertKeys)
          ? o.stalledAlertKeys
          : [];
        if (priorKeys.includes(alertKey)) {
          // Already alerted for this specific missed date
          return;
        }

        // Fetch participants and vehicle for context
        const [dealerDoc, transporterDoc, vehicleDoc] = await Promise.all([
          o.dealerId ? db.collection("users").doc(o.dealerId).get() : null,
          o.transporterId
            ? db.collection("users").doc(o.transporterId).get()
            : null,
          o.vehicleId ? db.collection("vehicles").doc(o.vehicleId).get() : null,
        ]);

        const dealer = dealerDoc && dealerDoc.exists ? dealerDoc.data() : {};
        const transporter =
          transporterDoc && transporterDoc.exists ? transporterDoc.data() : {};
        const vehicle =
          vehicleDoc && vehicleDoc.exists ? vehicleDoc.data() : {};

        const dealerName =
          `${dealer.firstName || ""} ${dealer.lastName || ""}`.trim() ||
          dealer.companyName ||
          "Dealer";
        const transporterName =
          `${transporter.firstName || ""} ${
            transporter.lastName || ""
          }`.trim() ||
          transporter.companyName ||
          "Transporter";
        const vehicleName = `${
          vehicle.brands?.join(", ") || vehicle.brand || "Vehicle"
        } ${vehicle.makeModel || vehicle.model || ""} ${
          vehicle.year || ""
        }`.trim();

        const scheduledDateStr = scheduledAt.toLocaleDateString();
        const scheduledTimeStr =
          type === "inspection"
            ? o.dealerSelectedInspectionTime || "Time TBD"
            : o.dealerSelectedCollectionTime || "Time TBD";
        const scheduledLocStr =
          type === "inspection"
            ? o.dealerSelectedInspectionLocation || "Location TBD"
            : o.dealerSelectedCollectionLocation || "Location TBD";

        const now = new Date();
        const msDiff = now.getTime() - scheduledAt.getTime();
        const daysOverdue = Math.max(
          1,
          Math.floor(msDiff / (1000 * 60 * 60 * 24))
        );

        // Compose push for admins
        const title =
          type === "inspection"
            ? "🔔 Inspection Missed"
            : "🔔 Collection Missed";
        const body =
          type === "inspection"
            ? `${dealerName} (buyer) and ${transporterName} (seller) missed inspection for ${vehicleName} on ${scheduledDateStr} at ${scheduledTimeStr}`
            : `${transporterName} (seller) and ${dealerName} (buyer) missed collection for ${vehicleName} on ${scheduledDateStr} at ${scheduledTimeStr}`;

        // Send push to each admin
        for (const token of adminPushTargets) {
          try {
            await admin.messaging().send({
              notification: { title, body },
              data: {
                notificationType: "stalled_offer_admin",
                stage: type,
                offerId,
                vehicleId: o.vehicleId || "",
                dealerId: o.dealerId || "",
                transporterId: o.transporterId || "",
                scheduledDate: scheduledDateStr,
                scheduledTime: scheduledTimeStr,
                daysOverdue: String(daysOverdue),
                timestamp: new Date().toISOString(),
              },
              token,
            });
          } catch (e) {
            console.error(
              "[sendStalledOfferAlerts] Error sending admin push:",
              e
            );
          }
        }

        // Send email summary to admins (optional if SendGrid configured)
        if (sgMail && adminEmails.length > 0) {
          try {
            const offerLink = `https://ctpapp.co.za/offer/${offerId}`;
            await sgMail.send({
              from: "admin@ctpapp.co.za",
              to: adminEmails,
              subject:
                type === "inspection"
                  ? `🔔 Missed Inspection Alert - ${vehicleName}`
                  : `🔔 Missed Collection Alert - ${vehicleName}`,
              html: `
                <div style="font-family: Arial, sans-serif; max-width: 640px; margin: 0 auto;">
                  <h2 style="color: #dc3545;">${title}</h2>
                  <p><strong>Vehicle:</strong> ${vehicleName}</p>
                  <p><strong>Buyer:</strong> ${dealerName}</p>
                  <p><strong>Seller:</strong> ${transporterName}</p>
                  <p><strong>Scheduled:</strong> ${scheduledDateStr} at ${scheduledTimeStr}</p>
                  <p><strong>Location:</strong> ${scheduledLocStr}</p>
                  <p><strong>Days overdue:</strong> ${daysOverdue}</p>
                  <div style="text-align: center; margin: 20px 0;">
                    <a href="${offerLink}" style="background:#2F7FFF;color:#fff;padding:10px 18px;text-decoration:none;border-radius:6px;">Open Offer</a>
                  </div>
                  <p style="color:#666;font-size:13px;">This alert is sent once per missed schedule to reduce noise.</p>
                </div>
              `,
            });
          } catch (e) {
            console.error(
              "[sendStalledOfferAlerts] Error sending admin email:",
              e
            );
          }
        }

        // Mark this alert as sent to avoid duplicates
        try {
          await db
            .collection("offers")
            .doc(offerId)
            .update({
              stalledAlertKeys: admin.firestore.FieldValue.arrayUnion(alertKey),
              lastStalledAlertAt: admin.firestore.FieldValue.serverTimestamp(),
              lastStalledReason: type,
            });
        } catch (e) {
          console.error(
            "[sendStalledOfferAlerts] Error updating offer flags:",
            e
          );
        }

        alertsSent++;
      };

      // Process inspections
      for (const doc of inspSnap.docs) {
        await processMissed(doc, "inspection");
      }

      // Process collections
      for (const doc of collSnap.docs) {
        await processMissed(doc, "collection");
      }

      console.log(
        `[sendStalledOfferAlerts] Completed. Alerts sent: ${alertsSent}`
      );
    } catch (err) {
      console.error("[sendStalledOfferAlerts] Error in job:", err);
    }
  }
);

// Notify dealer that transporter has provided inspection availability (inspection needed: dealer to choose)
exports.notifyDealerOnInspectionSetupReady = onDocumentUpdated(
  {
    document: "offers/{offerId}",
    region: "us-central1",
  },
  async (event) => {
    console.log(
      "[notifyDealerOnInspectionSetupReady] Triggered for offerId:",
      event.params.offerId
    );

    const before = event.data.before.data();
    const after = event.data.after.data();
    const offerId = event.params.offerId;
    if (!before || !after) return;

    // Safely get locations arrays before/after
    const beforeLocations =
      before.inspectionDetails?.inspectionLocations?.locations || [];
    const afterLocations =
      after.inspectionDetails?.inspectionLocations?.locations || [];

    // Detect when availability first becomes available
    const becameAvailable =
      beforeLocations.length === 0 && afterLocations.length > 0;

    // Optionally also require a status flag from SetupInspectionPage
    const statusBecameCompleted =
      (before.inspectionDetails?.status || "").toString().toLowerCase() !==
        "completed" &&
      (after.inspectionDetails?.status || "").toString().toLowerCase() ===
        "completed";

    if (!becameAvailable && !statusBecameCompleted) {
      console.log(
        "[notifyDealerOnInspectionSetupReady] No new availability detected, skipping"
      );
      return;
    }

    try {
      // Get dealer
      const dealerDoc = await db.collection("users").doc(after.dealerId).get();
      const dealerData = dealerDoc.exists ? dealerDoc.data() : {};

      // Vehicle details for context
      const vehicleDoc = await db
        .collection("vehicles")
        .doc(after.vehicleId)
        .get();
      const vehicleData = vehicleDoc.exists ? vehicleDoc.data() : {};
      const vehicleName = `${
        vehicleData.brands?.join(", ") || vehicleData.brand || "Vehicle"
      } ${vehicleData.makeModel || vehicleData.model || ""} ${
        vehicleData.year || ""
      }`.trim();

      // Push to dealer – no names
      if (dealerData?.fcmToken) {
        await admin.messaging().send({
          notification: {
            title: "🔧 Inspection Availability Ready",
            body: `Availability for ${vehicleName} has been provided. Please select a date and time.`,
          },
          data: {
            notificationType: "inspection_setup_ready",
            offerId,
            vehicleId: after.vehicleId,
            timestamp: new Date().toISOString(),
          },
          token: dealerData.fcmToken,
        });
        console.log(
          `[notifyDealerOnInspectionSetupReady] Notified dealer ${after.dealerId}`
        );
      }

      // Admin heads-up (optional)
      const adminUsersSnapshot = await db
        .collection("users")
        .where("userRole", "in", ["admin", "sales representative"])
        .get();
      for (const adminDoc of adminUsersSnapshot.docs) {
        const adminData = adminDoc.data();
        if (!adminData.fcmToken) continue;
        try {
          await admin.messaging().send({
            notification: {
              title: "📋 Inspection Availability Submitted",
              body: `Availability submitted for ${vehicleName}. Dealer prompted to choose.`,
            },
            data: {
              notificationType: "inspection_setup_ready_admin",
              offerId,
              vehicleId: after.vehicleId,
              timestamp: new Date().toISOString(),
            },
            token: adminData.fcmToken,
          });
        } catch (e) {
          console.error(
            `[notifyDealerOnInspectionSetupReady] Admin notify error for ${adminDoc.id}:`,
            e
          );
        }
      }
    } catch (e) {
      console.error("[notifyDealerOnInspectionSetupReady] Error:", e);
    }
  }
);

// Notify transporter to set up inspection availability once offer is accepted
exports.notifyTransporterToSetupInspectionOnOfferAccepted = onDocumentUpdated(
  {
    document: "offers/{offerId}",
    region: "us-central1",
  },
  async (event) => {
    console.log(
      "[notifyTransporterToSetupInspectionOnOfferAccepted] Triggered for offerId:",
      event.params.offerId
    );
    const before = event.data.before.data();
    const after = event.data.after.data();
    const offerId = event.params.offerId;
    if (!before || !after) return;

    const beforeStatus = (before.offerStatus || "").toString().toLowerCase();
    const afterStatus = (after.offerStatus || "").toString().toLowerCase();

    // Only when transitioning to accepted
    if (beforeStatus === afterStatus || afterStatus !== "accepted") return;

    try {
      // Determine transporterId (prefer offer field, fallback to vehicle owner)
      let transporterId = after.transporterId;
      if (!transporterId) {
        const vehicleDoc = await db
          .collection("vehicles")
          .doc(after.vehicleId)
          .get();
        if (vehicleDoc.exists) {
          transporterId = vehicleDoc.data().userId;
        }
      }
      if (!transporterId) {
        console.log(
          "[notifyTransporterToSetupInspectionOnOfferAccepted] No transporterId found"
        );
        return;
      }

      const transporterDoc = await db
        .collection("users")
        .doc(transporterId)
        .get();
      const transporterData = transporterDoc.exists
        ? transporterDoc.data()
        : {};

      // Vehicle details for context
      const vehicleDoc = await db
        .collection("vehicles")
        .doc(after.vehicleId)
        .get();
      const vehicleData = vehicleDoc.exists ? vehicleDoc.data() : {};
      const vehicleName = `${
        vehicleData.brands?.join(", ") || vehicleData.brand || "Vehicle"
      } ${vehicleData.makeModel || vehicleData.model || ""} ${
        vehicleData.year || ""
      }`.trim();

      if (transporterData?.fcmToken) {
        await admin.messaging().send({
          notification: {
            title: "🔧 Set Up Inspection Availability",
            body: `Your offer was accepted. Please provide inspection availability for ${vehicleName}.`,
          },
          data: {
            notificationType: "inspection_setup_needed",
            offerId,
            vehicleId: after.vehicleId,
            timestamp: new Date().toISOString(),
          },
          token: transporterData.fcmToken,
        });
        console.log(
          `[notifyTransporterToSetupInspectionOnOfferAccepted] Notified transporter ${transporterId}`
        );
      }
    } catch (e) {
      console.error(
        "[notifyTransporterToSetupInspectionOnOfferAccepted] Error:",
        e
      );
    }
  }
);

// Notify dealer that inspection is needed once offer is accepted
exports.notifyDealerInspectionNeededOnOfferAccepted = onDocumentUpdated(
  {
    document: "offers/{offerId}",
    region: "us-central1",
  },
  async (event) => {
    console.log(
      "[notifyDealerInspectionNeededOnOfferAccepted] Triggered for offerId:",
      event.params.offerId
    );
    const before = event.data.before.data();
    const after = event.data.after.data();
    const offerId = event.params.offerId;
    if (!before || !after) return;

    const beforeStatus = (before.offerStatus || "").toString().toLowerCase();
    const afterStatus = (after.offerStatus || "").toString().toLowerCase();
    if (beforeStatus === afterStatus || afterStatus !== "accepted") return;

    try {
      // Fetch dealer
      const dealerDoc = await db.collection("users").doc(after.dealerId).get();
      const dealerData = dealerDoc.exists ? dealerDoc.data() : {};
      if (!dealerData?.fcmToken) return;

      // Vehicle context
      const vehicleDoc = await db
        .collection("vehicles")
        .doc(after.vehicleId)
        .get();
      const vehicleData = vehicleDoc.exists ? vehicleDoc.data() : {};
      const vehicleName = `${
        vehicleData.brands?.join(", ") || vehicleData.brand || "Vehicle"
      } ${vehicleData.makeModel || vehicleData.model || ""} ${
        vehicleData.year || ""
      }`.trim();

      await admin.messaging().send({
        notification: {
          title: "🔍 Inspection Needed",
          body: `Your offer was accepted. Set up an inspection for ${vehicleName}.`,
        },
        data: {
          notificationType: "inspection_needed",
          offerId,
          vehicleId: after.vehicleId,
          timestamp: new Date().toISOString(),
        },
        token: dealerData.fcmToken,
      });
      console.log(
        `[notifyDealerInspectionNeededOnOfferAccepted] Notified dealer ${after.dealerId}`
      );
    } catch (e) {
      console.error("[notifyDealerInspectionNeededOnOfferAccepted] Error:", e);
    }
  }
);

// Notify admins when a dealer requests an invoice
exports.notifyAdminsOnInvoiceRequest = onDocumentUpdated(
  {
    document: "offers/{offerId}",
    region: "us-central1",
  },
  async (event) => {
    console.log(
      "[notifyAdminsOnInvoiceRequest] Triggered for offerId:",
      event.params.offerId
    );

    const before = event.data.before.data();
    const after = event.data.after.data();
    const offerId = event.params.offerId;

    if (!before || !after) {
      console.log("[notifyAdminsOnInvoiceRequest] No before/after data");
      return;
    }

    // Check if needsInvoice was just set to true (wasn't true before but is now)
    const wasInvoiceNeeded = before.needsInvoice === true;
    const isInvoiceNeeded = after.needsInvoice === true;

    // Only notify if invoice was just requested (not already requested)
    if (wasInvoiceNeeded || !isInvoiceNeeded) {
      console.log(
        "[notifyAdminsOnInvoiceRequest] Invoice not newly requested, skipping"
      );
      return;
    }

    console.log("[notifyAdminsOnInvoiceRequest] New invoice request detected");

    try {
      // Get dealer details (who requested the invoice)
      const dealerDoc = await db.collection("users").doc(after.dealerId).get();
      const dealerData = dealerDoc.exists ? dealerDoc.data() : {};
      const dealerName =
        `${dealerData.firstName || ""} ${dealerData.lastName || ""}`.trim() ||
        dealerData.companyName ||
        "Dealer";
      const dealerEmail = dealerData.email;

      // Get transporter details
      const transporterDoc = await db
        .collection("users")
        .doc(after.transporterId)
        .get();
      const transporterData = transporterDoc.exists
        ? transporterDoc.data()
        : {};
      const transporterName =
        `${transporterData.firstName || ""} ${
          transporterData.lastName || ""
        }`.trim() ||
        transporterData.companyName ||
        "Transporter";

      // Get vehicle details
      const vehicleDoc = await db
        .collection("vehicles")
        .doc(after.vehicleId)
        .get();
      const vehicleData = vehicleDoc.exists ? vehicleDoc.data() : {};
      const vehicleName = `${
        vehicleData.brands?.join(", ") || vehicleData.brand || "Vehicle"
      } ${vehicleData.makeModel || vehicleData.model || ""} ${
        vehicleData.year || ""
      }`.trim();

      const offerAmount = after.offerAmount || 0;

      // Get all admin users for notifications
      const adminUsersSnapshot = await db
        .collection("users")
        .where("userRole", "in", ["admin", "sales representative"])
        .get();

      if (adminUsersSnapshot.empty) {
        console.log("[notifyAdminsOnInvoiceRequest] No admin users found");
        return;
      }

      console.log(
        `[notifyAdminsOnInvoiceRequest] Found ${adminUsersSnapshot.docs.length} admin users to notify`
      );

      // Notify each admin
      for (const adminDoc of adminUsersSnapshot.docs) {
        const adminData = adminDoc.data();
        const adminName =
          `${adminData.firstName || ""} ${adminData.lastName || ""}`.trim() ||
          adminData.companyName ||
          "Admin";

        // Send push notification if admin has FCM token
        if (adminData.fcmToken) {
          try {
            const adminMessage = {
              notification: {
                title: "📄 Invoice Request",
                body: `${dealerName} has requested an invoice for ${vehicleName} (Offer: R${offerAmount.toLocaleString()})`,
              },
              data: {
                offerId: offerId,
                vehicleId: after.vehicleId,
                dealerId: after.dealerId,
                transporterId: after.transporterId,
                notificationType: "invoice_request",
                offerAmount: offerAmount.toString(),
                vehicleName: vehicleName,
                dealerName: dealerName,
                timestamp: new Date().toISOString(),
              },
              token: adminData.fcmToken,
            };

            await admin.messaging().send(adminMessage);
            console.log(
              `[notifyAdminsOnInvoiceRequest] Push notification sent to admin ${adminDoc.id}`
            );
          } catch (adminPushError) {
            console.error(
              `[notifyAdminsOnInvoiceRequest] Error sending push to admin ${adminDoc.id}:`,
              adminPushError
            );
          }
        }
      }

      // Send email notifications if SendGrid is available
      if (sgMail) {
        const offerLink = `https://ctpapp.co.za/offer/${offerId}`;
        const adminEmails = adminUsersSnapshot.docs
          .map((doc) => doc.data().email)
          .filter((email) => !!email);

        if (adminEmails.length > 0) {
          try {
            await sgMail.send({
              from: "admin@ctpapp.co.za",
              to: adminEmails,
              subject: `📄 Invoice Request - ${dealerName} for ${vehicleName}`,
              html: `
                <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto;">
                  <div style="background-color: #2F7FFF; color: white; padding: 20px; text-align: center; border-radius: 8px 8px 0 0;">
                    <h2 style="margin: 0; font-size: 28px;">📄 Invoice Request</h2>
                  </div>
                  
                  <div style="padding: 30px; border: 1px solid #ddd; border-top: none; border-radius: 0 0 8px 8px;">
                    <p style="font-size: 18px; color: #2F7FFF; font-weight: bold;">New Invoice Request</p>
                    <p style="font-size: 16px;">A dealer has requested an invoice to be generated for a vehicle purchase.</p>
                    
                    <div style="background-color: #f8f9fa; padding: 25px; border-radius: 8px; margin: 25px 0;">
                      <h3 style="margin-top: 0; color: #333; border-bottom: 2px solid #2F7FFF; padding-bottom: 10px;">Request Details:</h3>
                      <div style="display: grid; gap: 10px;">
                        <p style="margin: 8px 0;"><strong>🚛 Vehicle:</strong> ${vehicleName}</p>
                        <p style="margin: 8px 0;"><strong>👤 Requesting Dealer:</strong> ${dealerName}</p>
                        <p style="margin: 8px 0;"><strong>📧 Dealer Email:</strong> ${
                          dealerEmail || "Not provided"
                        }</p>
                        <p style="margin: 8px 0;"><strong>🏢 Vehicle Owner:</strong> ${transporterName}</p>
                        <p style="margin: 8px 0;"><strong>💰 Offer Amount:</strong> R${offerAmount.toLocaleString()}</p>
                        <p style="margin: 8px 0;"><strong>📋 Offer ID:</strong> ${offerId}</p>
                        <p style="margin: 8px 0;"><strong>📅 Request Date:</strong> ${new Date().toLocaleString()}</p>
                      </div>
                    </div>
                    
                    <div style="background-color: #fff3cd; padding: 20px; border-radius: 8px; margin: 25px 0; border-left: 4px solid #ffc107;">
                      <h4 style="margin-top: 0; color: #856404;">⚡ Action Required:</h4>
                      <p style="margin: 5px 0; color: #856404;">• Review the offer details and ensure payment has been processed</p>
                      <p style="margin: 5px 0; color: #856404;">• Generate and upload the invoice for this transaction</p>
                      <p style="margin: 5px 0; color: #856404;">• The dealer is waiting for the invoice to complete their purchase</p>
                    </div>
                    
                    <div style="text-align: center; margin: 35px 0;">
                      <a href="${offerLink}" 
                         style="background-color: #2F7FFF; color: white; padding: 15px 30px; text-decoration: none; border-radius: 5px; display: inline-block; font-weight: bold; font-size: 16px;">
                        Process Invoice Request
                      </a>
                    </div>
                    
                    <div style="background-color: #d1ecf1; padding: 20px; border-radius: 8px; margin: 25px 0; border-left: 4px solid #17a2b8;">
                      <h4 style="margin-top: 0; color: #0c5460;">💡 Quick Actions:</h4>
                      <p style="margin: 5px 0; color: #0c5460;">• Click the button above to access the offer management page</p>
                      <p style="margin: 5px 0; color: #0c5460;">• Generate the invoice using the integrated Sage system</p>
                      <p style="margin: 5px 0; color: #0c5460;">• Upload the invoice PDF to complete the transaction</p>
                    </div>
                    
                    <p style="margin-top: 30px;">Please process this request promptly to ensure a smooth transaction experience.</p>
                    
                    <p>Best regards,<br>
                    Commercial Trader Portal System</p>
                  </div>
                </div>
              `,
            });

            console.log(
              `[notifyAdminsOnInvoiceRequest] Email sent to ${adminEmails.length} admin(s)`
            );
          } catch (emailError) {
            console.error(
              "[notifyAdminsOnInvoiceRequest] Error sending email to admins:",
              emailError
            );
          }
        }
      }
    } catch (error) {
      console.error("[notifyAdminsOnInvoiceRequest] Error:", error);
    }
  }
);

// Notify admins when a dealer uploads proof of payment
exports.notifyAdminsOnProofOfPaymentUpload = onDocumentUpdated(
  {
    document: "offers/{offerId}",
    region: "us-central1",
  },
  async (event) => {
    console.log(
      "[notifyAdminsOnProofOfPaymentUpload] Triggered for offerId:",
      event.params.offerId
    );

    const before = event.data.before.data();
    const after = event.data.after.data();
    const offerId = event.params.offerId;

    if (!before || !after) {
      console.log("[notifyAdminsOnProofOfPaymentUpload] No before/after data");
      return;
    }

    // Check if proof of payment was just uploaded (wasn't there before but is now)
    const hadProofOfPayment = !!(
      before.proofOfPaymentUrl && before.proofOfPaymentUrl.trim() !== ""
    );
    const hasProofOfPayment = !!(
      after.proofOfPaymentUrl && after.proofOfPaymentUrl.trim() !== ""
    );

    // Only notify if proof of payment was just uploaded (not already there)
    if (hadProofOfPayment || !hasProofOfPayment) {
      console.log(
        "[notifyAdminsOnProofOfPaymentUpload] Proof of payment not newly uploaded, skipping"
      );
      return;
    }

    console.log(
      "[notifyAdminsOnProofOfPaymentUpload] New proof of payment detected"
    );

    try {
      // Get dealer details (who uploaded the proof of payment)
      const dealerDoc = await db.collection("users").doc(after.dealerId).get();
      const dealerData = dealerDoc.exists ? dealerDoc.data() : {};
      const dealerName =
        `${dealerData.firstName || ""} ${dealerData.lastName || ""}`.trim() ||
        dealerData.companyName ||
        "Dealer";
      const dealerEmail = dealerData.email;

      // Get transporter details
      const transporterDoc = await db
        .collection("users")
        .doc(after.transporterId)
        .get();
      const transporterData = transporterDoc.exists
        ? transporterDoc.data()
        : {};
      const transporterName =
        `${transporterData.firstName || ""} ${
          transporterData.lastName || ""
        }`.trim() ||
        transporterData.companyName ||
        "Transporter";

      // Get vehicle details
      const vehicleDoc = await db
        .collection("vehicles")
        .doc(after.vehicleId)
        .get();
      const vehicleData = vehicleDoc.exists ? vehicleDoc.data() : {};
      const vehicleName = `${
        vehicleData.brands?.join(", ") || vehicleData.brand || "Vehicle"
      } ${vehicleData.makeModel || vehicleData.model || ""} ${
        vehicleData.year || ""
      }`.trim();

      const offerAmount = after.offerAmount || 0;
      const proofOfPaymentFileName = after.proofOfPaymentFileName || "Document";
      const uploadTimestamp = after.uploadTimestamp
        ? after.uploadTimestamp.toDate
          ? after.uploadTimestamp.toDate()
          : new Date(after.uploadTimestamp)
        : new Date();

      // Get all admin users for notifications
      const adminUsersSnapshot = await db
        .collection("users")
        .where("userRole", "in", ["admin", "sales representative"])
        .get();

      if (adminUsersSnapshot.empty) {
        console.log(
          "[notifyAdminsOnProofOfPaymentUpload] No admin users found"
        );
        return;
      }

      console.log(
        `[notifyAdminsOnProofOfPaymentUpload] Found ${adminUsersSnapshot.docs.length} admin users to notify`
      );

      // Notify each admin
      for (const adminDoc of adminUsersSnapshot.docs) {
        const adminData = adminDoc.data();
        const adminName =
          `${adminData.firstName || ""} ${adminData.lastName || ""}`.trim() ||
          adminData.companyName ||
          "Admin";

        // Send push notification if admin has FCM token
        if (adminData.fcmToken) {
          try {
            const adminMessage = {
              notification: {
                title: "💳 Proof of Payment Uploaded",
                body: `${dealerName} has uploaded proof of payment for ${vehicleName} (R${offerAmount.toLocaleString()}) - Review and approve`,
              },
              data: {
                offerId: offerId,
                vehicleId: after.vehicleId,
                dealerId: after.dealerId,
                transporterId: after.transporterId,
                notificationType: "proof_of_payment_uploaded",
                offerAmount: offerAmount.toString(),
                vehicleName: vehicleName,
                dealerName: dealerName,
                proofOfPaymentFileName: proofOfPaymentFileName,
                timestamp: new Date().toISOString(),
              },
              token: adminData.fcmToken,
            };

            await admin.messaging().send(adminMessage);
            console.log(
              `[notifyAdminsOnProofOfPaymentUpload] Push notification sent to admin ${adminDoc.id}`
            );
          } catch (adminPushError) {
            console.error(
              `[notifyAdminsOnProofOfPaymentUpload] Error sending push to admin ${adminDoc.id}:`,
              adminPushError
            );
          }
        }
      }

      // Send email notifications if SendGrid is available
      if (sgMail) {
        const offerLink = `https://ctpapp.co.za/offer/${offerId}`;
        const adminEmails = adminUsersSnapshot.docs
          .map((doc) => doc.data().email)
          .filter((email) => !!email);

        if (adminEmails.length > 0) {
          try {
            await sgMail.send({
              from: "admin@ctpapp.co.za",
              to: adminEmails,
              subject: `💳 Payment Verification Required - ${dealerName} for ${vehicleName}`,
              html: `
                <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto;">
                  <div style="background-color: #28a745; color: white; padding: 20px; text-align: center; border-radius: 8px 8px 0 0;">
                    <h2 style="margin: 0; font-size: 28px;">💳 Proof of Payment Uploaded</h2>
                  </div>
                  
                  <div style="padding: 30px; border: 1px solid #ddd; border-top: none; border-radius: 0 0 8px 8px;">
                    <p style="font-size: 18px; color: #28a745; font-weight: bold;">Payment Verification Needed</p>
                    <p style="font-size: 16px;">A dealer has uploaded proof of payment for a vehicle purchase and is awaiting payment approval.</p>
                    
                    <div style="background-color: #f8f9fa; padding: 25px; border-radius: 8px; margin: 25px 0;">
                      <h3 style="margin-top: 0; color: #333; border-bottom: 2px solid #28a745; padding-bottom: 10px;">Payment Details:</h3>
                      <div style="display: grid; gap: 10px;">
                        <p style="margin: 8px 0;"><strong>🚛 Vehicle:</strong> ${vehicleName}</p>
                        <p style="margin: 8px 0;"><strong>👤 Paying Dealer:</strong> ${dealerName}</p>
                        <p style="margin: 8px 0;"><strong>📧 Dealer Email:</strong> ${
                          dealerEmail || "Not provided"
                        }</p>
                        <p style="margin: 8px 0;"><strong>🏢 Vehicle Owner:</strong> ${transporterName}</p>
                        <p style="margin: 8px 0;"><strong>💰 Payment Amount:</strong> R${offerAmount.toLocaleString()}</p>
                        <p style="margin: 8px 0;"><strong>📄 Document Name:</strong> ${proofOfPaymentFileName}</p>
                        <p style="margin: 8px 0;"><strong>📋 Offer ID:</strong> ${offerId}</p>
                        <p style="margin: 8px 0;"><strong>📅 Upload Time:</strong> ${uploadTimestamp.toLocaleString()}</p>
                      </div>
                    </div>
                    
                    <div style="background-color: #fff3cd; padding: 20px; border-radius: 8px; margin: 25px 0; border-left: 4px solid #ffc107;">
                      <h4 style="margin-top: 0; color: #856404;">⚡ Action Required:</h4>
                      <p style="margin: 5px 0; color: #856404;">• Review the uploaded proof of payment document</p>
                      <p style="margin: 5px 0; color: #856404;">• Verify the payment amount and transaction details</p>
                      <p style="margin: 5px 0; color: #856404;">• Approve or reject the payment to proceed with the transaction</p>
                      <p style="margin: 5px 0; color: #856404;">• The dealer is waiting for payment confirmation</p>
                    </div>
                    
                    <div style="text-align: center; margin: 35px 0;">
                      <a href="${offerLink}" 
                         style="background-color: #28a745; color: white; padding: 15px 30px; text-decoration: none; border-radius: 5px; display: inline-block; font-weight: bold; font-size: 16px;">
                        Review Payment Proof
                      </a>
                    </div>
                    
                    <div style="background-color: #d1ecf1; padding: 20px; border-radius: 8px; margin: 25px 0; border-left: 4px solid #17a2b8;">
                      <h4 style="margin-top: 0; color: #0c5460;">💡 Next Steps:</h4>
                      <p style="margin: 5px 0; color: #0c5460;">• Click the button above to access the offer management page</p>
                      <p style="margin: 5px 0; color: #0c5460;">• Download and review the proof of payment document</p>
                      <p style="margin: 5px 0; color: #0c5460;">• Update the payment status (approved/rejected) with comments if needed</p>
                      <p style="margin: 5px 0; color: #0c5460;">• The dealer will be automatically notified of your decision</p>
                    </div>
                    
                    <div style="background-color: #d4edda; padding: 20px; border-radius: 8px; margin: 25px 0; border-left: 4px solid #28a745;">
                      <h4 style="margin-top: 0; color: #155724;">✅ Verification Checklist:</h4>
                      <ul style="margin: 10px 0; padding-left: 20px; color: #155724;">
                        <li>Confirm payment amount matches the offer amount</li>
                        <li>Verify payment method and transaction reference</li>
                        <li>Check payment date and ensure it's recent</li>
                        <li>Validate banking details match expected account</li>
                        <li>Ensure document is clear and legible</li>
                      </ul>
                    </div>
                    
                    <p style="margin-top: 30px;">Please review and process this payment verification promptly to maintain a smooth transaction flow.</p>
                    
                    <p>Best regards,<br>
                    Commercial Trader Portal System</p>
                  </div>
                </div>
              `,
            });

            console.log(
              `[notifyAdminsOnProofOfPaymentUpload] Email sent to ${adminEmails.length} admin(s)`
            );
          } catch (emailError) {
            console.error(
              "[notifyAdminsOnProofOfPaymentUpload] Error sending email to admins:",
              emailError
            );
          }
        }
      }
    } catch (error) {
      console.error("[notifyAdminsOnProofOfPaymentUpload] Error:", error);
    }
  }
);

// Notify parties when vehicle collection is confirmed
exports.notifyPartiesOnVehicleCollected = onDocumentUpdated(
  {
    document: "offers/{offerId}",
    region: "us-central1",
  },
  async (event) => {
    console.log(
      "[notifyPartiesOnVehicleCollected] Triggered for offerId:",
      event.params.offerId
    );

    const before = event.data.before.data();
    const after = event.data.after.data();
    const offerId = event.params.offerId;

    if (!before || !after) {
      console.log("[notifyPartiesOnVehicleCollected] No before/after data");
      return;
    }

    // Check if offer status was just changed to 'collected' (wasn't collected before but is now)
    const wasCollected = before.offerStatus?.toLowerCase() === "collected";
    const isCollected = after.offerStatus?.toLowerCase() === "collected";

    // Only notify if collection was just confirmed (not already collected)
    if (wasCollected || !isCollected) {
      console.log(
        "[notifyPartiesOnVehicleCollected] Vehicle not newly collected, skipping"
      );
      return;
    }

    console.log(
      "[notifyPartiesOnVehicleCollected] Vehicle collection confirmed"
    );

    try {
      // Get dealer details (who collected the vehicle)
      const dealerDoc = await db.collection("users").doc(after.dealerId).get();
      const dealerData = dealerDoc.exists ? dealerDoc.data() : {};
      const dealerName =
        `${dealerData.firstName || ""} ${dealerData.lastName || ""}`.trim() ||
        dealerData.companyName ||
        "Dealer";
      const dealerEmail = dealerData.email;

      // Get transporter details (original owner)
      const transporterDoc = await db
        .collection("users")
        .doc(after.transporterId)
        .get();
      const transporterData = transporterDoc.exists
        ? transporterDoc.data()
        : {};
      const transporterName =
        `${transporterData.firstName || ""} ${
          transporterData.lastName || ""
        }`.trim() ||
        transporterData.companyName ||
        "Transporter";
      const transporterEmail = transporterData.email;

      // Get vehicle details
      const vehicleDoc = await db
        .collection("vehicles")
        .doc(after.vehicleId)
        .get();
      const vehicleData = vehicleDoc.exists ? vehicleDoc.data() : {};
      const vehicleName = `${
        vehicleData.brands?.join(", ") || vehicleData.brand || "Vehicle"
      } ${vehicleData.makeModel || vehicleData.model || ""} ${
        vehicleData.year || ""
      }`.trim();

      const offerAmount = after.offerAmount || 0;
      const collectionDate = after.collectionDate
        ? after.collectionDate.toDate
          ? after.collectionDate.toDate()
          : new Date(after.collectionDate)
        : new Date();

      // Notify transporter (confirmation that their vehicle was collected)
      if (transporterData.fcmToken) {
        try {
          const transporterMessage = {
            notification: {
              title: "✅ Vehicle Collected Successfully",
              body: `Your ${vehicleName} has been collected. The transaction is now complete!`,
            },
            data: {
              offerId: offerId,
              vehicleId: after.vehicleId,
              dealerId: after.dealerId,
              notificationType: "vehicle_collected",
              offerAmount: offerAmount.toString(),
              vehicleName: vehicleName,
              timestamp: new Date().toISOString(),
            },
            token: transporterData.fcmToken,
          };

          await admin.messaging().send(transporterMessage);
          console.log(
            `[notifyPartiesOnVehicleCollected] Collection confirmation sent to transporter ${after.transporterId}`
          );
        } catch (transporterPushError) {
          console.error(
            `[notifyPartiesOnVehicleCollected] Error sending confirmation to transporter:`,
            transporterPushError
          );
        }
      }

      // Notify dealer (confirmation of successful collection)
      if (dealerData.fcmToken) {
        try {
          const dealerMessage = {
            notification: {
              title: "✅ Collection Confirmed",
              body: `Vehicle collection confirmed for ${vehicleName}. Please rate your experience with ${transporterName}.`,
            },
            data: {
              offerId: offerId,
              vehicleId: after.vehicleId,
              transporterId: after.transporterId,
              notificationType: "collection_confirmed",
              offerAmount: offerAmount.toString(),
              vehicleName: vehicleName,
              transporterName: transporterName,
              timestamp: new Date().toISOString(),
            },
            token: dealerData.fcmToken,
          };

          await admin.messaging().send(dealerMessage);
          console.log(
            `[notifyPartiesOnVehicleCollected] Collection confirmation sent to dealer ${after.dealerId}`
          );
        } catch (dealerPushError) {
          console.error(
            `[notifyPartiesOnVehicleCollected] Error sending confirmation to dealer:`,
            dealerPushError
          );
        }
      }

      // Get all admin users for notifications
      const adminUsersSnapshot = await db
        .collection("users")
        .where("userRole", "in", ["admin", "sales representative"])
        .get();

      // Notify admins
      if (!adminUsersSnapshot.empty) {
        for (const adminDoc of adminUsersSnapshot.docs) {
          const adminData = adminDoc.data();

          if (!adminData.fcmToken) continue;

          try {
            const adminMessage = {
              notification: {
                title: "✅ Transaction Completed",
                body: `${dealerName} collected ${vehicleName} from ${transporterName}. Sale finalized (R${offerAmount.toLocaleString()}).`,
              },
              data: {
                offerId: offerId,
                vehicleId: after.vehicleId,
                dealerId: after.dealerId,
                transporterId: after.transporterId,
                notificationType: "transaction_completed",
                offerAmount: offerAmount.toString(),
                vehicleName: vehicleName,
                dealerName: dealerName,
                transporterName: transporterName,
                timestamp: new Date().toISOString(),
              },
              token: adminData.fcmToken,
            };

            await admin.messaging().send(adminMessage);
            console.log(
              `[notifyPartiesOnVehicleCollected] Transaction complete notification sent to admin ${adminDoc.id}`
            );
          } catch (adminPushError) {
            console.error(
              `[notifyPartiesOnVehicleCollected] Error sending notification to admin ${adminDoc.id}:`,
              adminPushError
            );
          }
        }
      }

      // Send email notifications if SendGrid is available
      if (sgMail) {
        const offerLink = `https://ctpapp.co.za/offer/${offerId}`;

        // Email to transporter (sale completion confirmation)
        if (transporterEmail) {
          try {
            await sgMail.send({
              from: "admin@ctpapp.co.za",
              to: transporterEmail,
              subject: `✅ Vehicle Sale Completed - ${vehicleName} Successfully Collected`,
              html: `
                <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto;">
                  <div style="background-color: #28a745; color: white; padding: 20px; text-align: center; border-radius: 8px 8px 0 0;">
                    <h2 style="margin: 0; font-size: 28px;">✅ Vehicle Sale Completed!</h2>
                  </div>
                  
                  <div style="padding: 30px; border: 1px solid #ddd; border-top: none; border-radius: 0 0 8px 8px;">
                    <p style="font-size: 18px; color: #28a745; font-weight: bold;">Congratulations!</p>
                    <p style="font-size: 16px;">Your vehicle has been successfully collected and the sale is now complete.</p>
                    
                    <div style="background-color: #f8f9fa; padding: 25px; border-radius: 8px; margin: 25px 0;">
                      <h3 style="margin-top: 0; color: #333; border-bottom: 2px solid #28a745; padding-bottom: 10px;">Transaction Summary:</h3>
                      <div style="display: grid; gap: 10px;">
                        <p style="margin: 8px 0;"><strong>🚛 Vehicle Sold:</strong> ${vehicleName}</p>
                        <p style="margin: 8px 0;"><strong>💰 Final Sale Amount:</strong> R${offerAmount.toLocaleString()}</p>
                        <p style="margin: 8px 0;"><strong>📋 Transaction ID:</strong> ${offerId}</p>
                        <p style="margin: 8px 0;"><strong>📅 Collection Date:</strong> ${collectionDate.toLocaleString()}</p>
                        <p style="margin: 8px 0;"><strong>✅ Status:</strong> Transaction Completed</p>
                      </div>
                    </div>
                    
                    <div style="background-color: #d4edda; padding: 20px; border-radius: 8px; margin: 25px 0; border-left: 4px solid #28a745;">
                      <h4 style="margin-top: 0; color: #155724;">🎉 What Happens Next:</h4>
                      <ul style="margin: 10px 0; padding-left: 20px; color: #155724;">
                        <li>Your payment will be processed according to the agreed terms</li>
                        <li>You'll receive a transaction completion certificate</li>
                        <li>Please rate your experience with the buyer</li>
                        <li>Thank you for using Commercial Trader Portal!</li>
                      </ul>
                    </div>
                    
                    <div style="text-align: center; margin: 35px 0;">
                      <a href="${offerLink}" 
                         style="background-color: #28a745; color: white; padding: 15px 30px; text-decoration: none; border-radius: 5px; display: inline-block; font-weight: bold; font-size: 16px;">
                        View Transaction Details
                      </a>
                    </div>
                    
                    <p style="margin-top: 30px;">Thank you for choosing Commercial Trader Portal for your vehicle sale. We hope to serve you again in the future!</p>
                    
                    <p>Best regards,<br>
                    Commercial Trader Portal Team</p>
                  </div>
                </div>
              `,
            });

            console.log(
              `[notifyPartiesOnVehicleCollected] Sale completion email sent to transporter ${transporterEmail}`
            );
          } catch (emailError) {
            console.error(
              "[notifyPartiesOnVehicleCollected] Error sending email to transporter:",
              emailError
            );
          }
        }

        // Email to dealer (collection confirmation)
        if (dealerEmail) {
          try {
            await sgMail.send({
              from: "admin@ctpapp.co.za",
              to: dealerEmail,
              subject: `✅ Collection Confirmed - ${vehicleName} Purchase Complete`,
              html: `
                <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto;">
                  <div style="background-color: #007bff; color: white; padding: 20px; text-align: center; border-radius: 8px 8px 0 0;">
                    <h2 style="margin: 0; font-size: 28px;">✅ Collection Confirmed!</h2>
                  </div>
                  
                  <div style="padding: 30px; border: 1px solid #ddd; border-top: none; border-radius: 0 0 8px 8px;">
                    <p style="font-size: 18px; color: #007bff; font-weight: bold;">Vehicle Successfully Collected</p>
                    <p style="font-size: 16px;">Your vehicle purchase has been completed successfully. Welcome to your new ${vehicleName}!</p>
                    
                    <div style="background-color: #f8f9fa; padding: 25px; border-radius: 8px; margin: 25px 0;">
                      <h3 style="margin-top: 0; color: #333; border-bottom: 2px solid #007bff; padding-bottom: 10px;">Purchase Summary:</h3>
                      <div style="display: grid; gap: 10px;">
                        <p style="margin: 8px 0;"><strong>🚛 Vehicle Purchased:</strong> ${vehicleName}</p>
                        <p style="margin: 8px 0;"><strong>🏢 Purchased From:</strong> ${transporterName}</p>
                        <p style="margin: 8px 0;"><strong>💰 Purchase Amount:</strong> R${offerAmount.toLocaleString()}</p>
                        <p style="margin: 8px 0;"><strong>📋 Transaction ID:</strong> ${offerId}</p>
                        <p style="margin: 8px 0;"><strong>📅 Collection Date:</strong> ${collectionDate.toLocaleString()}</p>
                        <p style="margin: 8px 0;"><strong>✅ Status:</strong> Purchase Completed</p>
                      </div>
                    </div>
                    
                    <div style="background-color: #cce5ff; padding: 20px; border-radius: 8px; margin: 25px 0; border-left: 4px solid #007bff;">
                      <h4 style="margin-top: 0; color: #004085;">📋 Important Reminders:</h4>
                      <ul style="margin: 10px 0; padding-left: 20px; color: #004085;">
                        <li>Ensure all vehicle documentation is transferred properly</li>
                        <li>Update your insurance and registration details</li>
                        <li>Please rate your experience with the seller</li>
                        <li>Keep your transaction receipt for your records</li>
                      </ul>
                    </div>
                    
                    <div style="text-align: center; margin: 35px 0;">
                      <a href="${offerLink}" 
                         style="background-color: #007bff; color: white; padding: 15px 30px; text-decoration: none; border-radius: 5px; display: inline-block; font-weight: bold; font-size: 16px;">
                        View Purchase Details
                      </a>
                    </div>
                    
                    <p style="margin-top: 30px;">Enjoy your new vehicle and thank you for choosing Commercial Trader Portal!</p>
                    
                    <p>Best regards,<br>
                    Commercial Trader Portal Team</p>
                  </div>
                </div>
              `,
            });

            console.log(
              `[notifyPartiesOnVehicleCollected] Collection confirmation email sent to dealer ${dealerEmail}`
            );
          } catch (emailError) {
            console.error(
              "[notifyPartiesOnVehicleCollected] Error sending email to dealer:",
              emailError
            );
          }
        }

        // Email to admins
        const adminEmails = adminUsersSnapshot.docs
          .map((doc) => doc.data().email)
          .filter((email) => !!email);

        if (adminEmails.length > 0) {
          try {
            await sgMail.send({
              from: "admin@ctpapp.co.za",
              to: adminEmails,
              subject: `✅ Transaction Completed - ${vehicleName} Sale Finalized`,
              html: `
                <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto;">
                  <div style="background-color: #6c757d; color: white; padding: 20px; text-align: center; border-radius: 8px 8px 0 0;">
                    <h2 style="margin: 0; font-size: 28px;">✅ Transaction Completed</h2>
                  </div>
                  
                  <div style="padding: 30px; border: 1px solid #ddd; border-top: none; border-radius: 0 0 8px 8px;">
                    <p style="font-size: 18px; color: #6c757d; font-weight: bold;">Vehicle Sale Successfully Completed</p>
                    <p style="font-size: 16px;">A vehicle transaction has been completed successfully on the platform.</p>
                    
                    <div style="background-color: #f8f9fa; padding: 25px; border-radius: 8px; margin: 25px 0;">
                      <h3 style="margin-top: 0; color: #333; border-bottom: 2px solid #6c757d; padding-bottom: 10px;">Transaction Details:</h3>
                      <div style="display: grid; gap: 10px;">
                        <p style="margin: 8px 0;"><strong>🚛 Vehicle:</strong> ${vehicleName}</p>
                        <p style="margin: 8px 0;"><strong>🏢 Seller:</strong> ${transporterName}</p>
                        <p style="margin: 8px 0;"><strong>👤 Buyer:</strong> ${dealerName}</p>
                        <p style="margin: 8px 0;"><strong>💰 Final Amount:</strong> R${offerAmount.toLocaleString()}</p>
                        <p style="margin: 8px 0;"><strong>📋 Transaction ID:</strong> ${offerId}</p>
                        <p style="margin: 8px 0;"><strong>📅 Collection Date:</strong> ${collectionDate.toLocaleString()}</p>
                        <p style="margin: 8px 0;"><strong>✅ Status:</strong> Completed Successfully</p>
                      </div>
                    </div>
                    
                    <div style="text-align: center; margin: 35px 0;">
                      <a href="${offerLink}" 
                         style="background-color: #6c757d; color: white; padding: 15px 30px; text-decoration: none; border-radius: 5px; display: inline-block; font-weight: bold; font-size: 16px;">
                        View Transaction Details
                      </a>
                    </div>
                    
                    <p style="margin-top: 30px;">This transaction is now complete and closed.</p>
                    
                    <p>Best regards,<br>
                    Commercial Trader Portal System</p>
                  </div>
                </div>
              `,
            });

            console.log(
              `[notifyPartiesOnVehicleCollected] Transaction completion notification sent to ${adminEmails.length} admin(s)`
            );
          } catch (emailError) {
            console.error(
              "[notifyPartiesOnVehicleCollected] Error sending admin notification:",
              emailError
            );
          }
        }
      }
    } catch (error) {
      console.error("[notifyPartiesOnVehicleCollected] Error:", error);
    }
  }
);

// Debug function to track offer status changes and log them
exports.trackOfferStatusChanges = onDocumentUpdated(
  {
    document: "offers/{offerId}",
    region: "us-central1",
  },
  async (event) => {
    const before = event.data.before.data();
    const after = event.data.after.data();
    const offerId = event.params.offerId;

    if (!before || !after) return;

    const beforeStatus = before.offerStatus;
    const afterStatus = after.offerStatus;

    // Only log when status actually changes
    if (beforeStatus !== afterStatus) {
      console.log(
        `[OFFER_STATUS_TRACKER] Offer ${offerId}: ${beforeStatus} -> ${afterStatus}`
      );
      console.log(`[OFFER_STATUS_TRACKER] Changed fields:`, {
        statusLocked: after.statusLocked,
        transactionComplete: after.transactionComplete,
        collectionConfirmed: after.collectionConfirmed,
        licenseVerified: after.licenseVerified,
        finalStatus: after.finalStatus,
        isCompleted: after.isCompleted,
        isSold: after.isSold,
      });

      // If a collected offer is being changed to rejected, log warning
      if (beforeStatus === "collected" && afterStatus === "rejected") {
        console.error(
          `[OFFER_STATUS_TRACKER] WARNING: Collected offer ${offerId} was changed to rejected!`
        );
        console.error(`[OFFER_STATUS_TRACKER] Full before data:`, before);
        console.error(`[OFFER_STATUS_TRACKER] Full after data:`, after);
      }
    }
  }
);
