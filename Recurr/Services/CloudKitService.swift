import Foundation
import SwiftUI
import CloudKit

@Observable
final class CloudKitService {
    private static let iCloudEnabledKey = "icloud_sync_enabled"

    var iCloudEnabled: Bool {
        didSet {
            UserDefaults.standard.set(iCloudEnabled, forKey: Self.iCloudEnabledKey)
        }
    }

    var accountStatus: CKAccountStatus = .couldNotDetermine
    var accountStatusDescription: String {
        switch accountStatus {
        case .available:
            return "Beschikbaar"
        case .noAccount:
            return "Geen iCloud account"
        case .restricted:
            return "Beperkt"
        case .couldNotDetermine:
            return "Onbekend"
        case .temporarilyUnavailable:
            return "Tijdelijk niet beschikbaar"
        @unknown default:
            return "Onbekend"
        }
    }

    var isAccountAvailable: Bool {
        accountStatus == .available
    }

    var lastSyncDate: Date? {
        get { UserDefaults.standard.object(forKey: "last_sync_date") as? Date }
        set { UserDefaults.standard.set(newValue, forKey: "last_sync_date") }
    }

    var syncError: String?

    init() {
        // Default to true if not set
        if UserDefaults.standard.object(forKey: Self.iCloudEnabledKey) == nil {
            self.iCloudEnabled = true
        } else {
            self.iCloudEnabled = UserDefaults.standard.bool(forKey: Self.iCloudEnabledKey)
        }

        // Check iCloud account status
        checkAccountStatus()

        // Listen for account changes
        NotificationCenter.default.addObserver(
            forName: .CKAccountChanged,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.checkAccountStatus()
        }
    }

    func checkAccountStatus() {
        Task { @MainActor in
            do {
                let status = try await CKContainer.default().accountStatus()
                self.accountStatus = status
                self.syncError = nil

                if status == .available {
                    self.lastSyncDate = Date()
                }
            } catch {
                self.syncError = error.localizedDescription
                print("CloudKit account status error: \(error)")
            }
        }
    }

    func triggerSync() {
        // Force a sync by touching the container
        Task {
            do {
                let container = CKContainer.default()
                let status = try await container.accountStatus()

                if status == .available {
                    // Fetch user record ID to trigger sync
                    _ = try? await container.userRecordID()
                    await MainActor.run {
                        self.lastSyncDate = Date()
                        self.syncError = nil
                    }
                }
            } catch {
                await MainActor.run {
                    self.syncError = error.localizedDescription
                }
            }
        }
    }
}

// MARK: - Environment Key

struct CloudKitServiceKey: EnvironmentKey {
    static let defaultValue = CloudKitService()
}

extension EnvironmentValues {
    var cloudKitService: CloudKitService {
        get { self[CloudKitServiceKey.self] }
        set { self[CloudKitServiceKey.self] = newValue }
    }
}
