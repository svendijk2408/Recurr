import Foundation
import UserNotifications

@Observable
final class NotificationService {
    static let shared = NotificationService()

    private(set) var isAuthorized = false

    private init() {
        checkAuthorizationStatus()
    }

    // MARK: - Authorization

    func requestAuthorization() async -> Bool {
        do {
            let granted = try await UNUserNotificationCenter.current()
                .requestAuthorization(options: [.alert, .badge, .sound])
            await MainActor.run {
                self.isAuthorized = granted
            }
            return granted
        } catch {
            print("Notification authorization error: \(error)")
            return false
        }
    }

    func checkAuthorizationStatus() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async {
                self.isAuthorized = settings.authorizationStatus == .authorized
            }
        }
    }

    // MARK: - Payment Reminders

    /// Schedule a payment reminder notification
    func schedulePaymentReminder(for subscription: Subscription) {
        guard let hoursBeforePayment = subscription.paymentReminderHours,
              hoursBeforePayment > 0 else { return }

        let nextPayment = subscription.calculateNextPaymentDate()
        let reminderDate = Calendar.current.date(
            byAdding: .hour,
            value: -hoursBeforePayment,
            to: nextPayment
        ) ?? nextPayment

        // Don't schedule if reminder date is in the past
        guard reminderDate > Date() else { return }

        let content = UNMutableNotificationContent()
        content.title = "Aankomende betaling"
        content.body = "\(subscription.name): \(subscription.amount.currencyFormatted) wordt binnenkort afgeschreven"
        content.sound = .default
        content.categoryIdentifier = "PAYMENT_REMINDER"

        let components = Calendar.current.dateComponents(
            [.year, .month, .day, .hour, .minute],
            from: reminderDate
        )
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)

        let request = UNNotificationRequest(
            identifier: "payment-\(subscription.id.uuidString)",
            content: content,
            trigger: trigger
        )

        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Error scheduling payment reminder: \(error)")
            }
        }
    }

    // MARK: - Trial Reminders

    /// Schedule a trial expiration reminder notification
    func scheduleTrialReminder(for subscription: Subscription) {
        guard subscription.hasTrial,
              !subscription.trialCancelled,
              let trialEndDate = subscription.trialEndDate,
              let daysBeforeExpiry = subscription.trialReminderDays,
              daysBeforeExpiry > 0 else { return }

        let reminderDate = Calendar.current.date(
            byAdding: .day,
            value: -daysBeforeExpiry,
            to: trialEndDate
        ) ?? trialEndDate

        // Don't schedule if reminder date is in the past
        guard reminderDate > Date() else { return }

        let content = UNMutableNotificationContent()
        content.title = "Proefperiode loopt af"
        content.body = "\(subscription.name) proefperiode eindigt over \(daysBeforeExpiry) dag(en). Wil je annuleren?"
        content.sound = .default
        content.categoryIdentifier = "TRIAL_REMINDER"

        let components = Calendar.current.dateComponents(
            [.year, .month, .day, .hour, .minute],
            from: reminderDate
        )
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)

        let request = UNNotificationRequest(
            identifier: "trial-\(subscription.id.uuidString)",
            content: content,
            trigger: trigger
        )

        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Error scheduling trial reminder: \(error)")
            }
        }
    }

    // MARK: - Cancel Notifications

    /// Cancel all notifications for a subscription
    func cancelNotifications(for subscription: Subscription) {
        UNUserNotificationCenter.current().removePendingNotificationRequests(
            withIdentifiers: [
                "payment-\(subscription.id.uuidString)",
                "trial-\(subscription.id.uuidString)"
            ]
        )
    }

    /// Cancel all notifications
    func cancelAllNotifications() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
    }

    // MARK: - Reschedule All

    /// Reschedule all notifications for all subscriptions
    func rescheduleAllNotifications(for subscriptions: [Subscription]) {
        cancelAllNotifications()

        for subscription in subscriptions where subscription.isActive {
            schedulePaymentReminder(for: subscription)
            scheduleTrialReminder(for: subscription)
        }
    }
}

// MARK: - Notification Options

enum PaymentReminderOption: Int, CaseIterable, Identifiable {
    case none = 0
    case oneHour = 1
    case threeHours = 3
    case sixHours = 6
    case twelveHours = 12
    case oneDay = 24
    case twoDays = 48
    case threeDays = 72
    case oneWeek = 168

    var id: Int { rawValue }

    var displayName: String {
        switch self {
        case .none: return "Uit"
        case .oneHour: return "1 uur van tevoren"
        case .threeHours: return "3 uur van tevoren"
        case .sixHours: return "6 uur van tevoren"
        case .twelveHours: return "12 uur van tevoren"
        case .oneDay: return "1 dag van tevoren"
        case .twoDays: return "2 dagen van tevoren"
        case .threeDays: return "3 dagen van tevoren"
        case .oneWeek: return "1 week van tevoren"
        }
    }
}

enum TrialReminderOption: Int, CaseIterable, Identifiable {
    case none = 0
    case oneDay = 1
    case twoDays = 2
    case threeDays = 3
    case oneWeek = 7
    case twoWeeks = 14

    var id: Int { rawValue }

    var displayName: String {
        switch self {
        case .none: return "Uit"
        case .oneDay: return "1 dag van tevoren"
        case .twoDays: return "2 dagen van tevoren"
        case .threeDays: return "3 dagen van tevoren"
        case .oneWeek: return "1 week van tevoren"
        case .twoWeeks: return "2 weken van tevoren"
        }
    }
}
