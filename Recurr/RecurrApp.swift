import SwiftUI
import SwiftData

@main
struct RecurrApp: App {
    @State private var themeService = ThemeService()
    @State private var cloudKitService = CloudKitService()

    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Subscription.self,
            Account.self,
            Tag.self,
            Profile.self
        ])

        // Check if iCloud is enabled in UserDefaults
        let iCloudEnabled: Bool
        if UserDefaults.standard.object(forKey: "icloud_sync_enabled") == nil {
            iCloudEnabled = true // Default to true
        } else {
            iCloudEnabled = UserDefaults.standard.bool(forKey: "icloud_sync_enabled")
        }

        let modelConfiguration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false,
            cloudKitDatabase: iCloudEnabled ? .automatic : .none
        )

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.themeService, themeService)
                .environment(\.cloudKitService, cloudKitService)
                .onAppear {
                    // Request notification permissions on first launch
                    Task {
                        await NotificationService.shared.requestAuthorization()
                    }
                }
        }
        .modelContainer(sharedModelContainer)
        #if os(macOS)
        .windowStyle(.hiddenTitleBar)
        .windowResizability(.contentSize)
        #endif
    }
}
