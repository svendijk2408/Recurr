import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(\.themeService) private var themeService
    @Environment(\.cloudKitService) private var cloudKitService
    @Environment(\.modelContext) private var modelContext

    @Query(sort: \Profile.createdAt) private var profiles: [Profile]

    @State private var notificationService = NotificationService.shared
    @State private var showingNotificationAlert = false
    @State private var showingOnboarding = false
    @State private var showingProfilesSheet = false
    @State private var showingAccountsSheet = false
    @State private var showingTagsSheet = false

    @AppStorage("selected_profile_id") private var selectedProfileIdString: String = ""
    @AppStorage("has_seen_onboarding") private var hasSeenOnboarding = false

    private var selectedProfile: Profile? {
        guard let uuid = UUID(uuidString: selectedProfileIdString) else {
            return profiles.first { $0.isDefault } ?? profiles.first
        }
        return profiles.first { $0.id == uuid } ?? profiles.first
    }

    var body: some View {
        #if os(macOS)
        macOSSettingsView
        #else
        iOSSettingsView
        #endif
    }

    // MARK: - iOS Settings View

    #if os(iOS)
    private var iOSSettingsView: some View {
        NavigationStack {
            Form {
                profileSection
                syncSection
                appearanceSection
                dataSection
                notificationsSection
                aboutSection
            }
            .navigationTitle(AppStrings.settings)
            .onAppear {
                createDefaultProfileIfNeeded()
            }
        }
    }
    #endif

    // MARK: - macOS Settings View

    #if os(macOS)
    private var macOSSettingsView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Header
                Text("Instellingen")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .padding(.bottom, 8)

                // Profile Section
                macOSGroupBox(title: "Profiel", icon: "person.fill") {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("Actief profiel")
                            Spacer()
                            Picker("", selection: Binding(
                                get: { selectedProfileIdString },
                                set: { selectedProfileIdString = $0 }
                            )) {
                                ForEach(profiles) { profile in
                                    HStack {
                                        Image(systemName: profile.iconName)
                                        Text(profile.name)
                                        if profile.isBusiness {
                                            Text("(Zakelijk)")
                                                .foregroundStyle(.secondary)
                                        }
                                    }
                                    .tag(profile.id.uuidString)
                                }
                            }
                            .frame(width: 200)
                        }

                        if let profile = selectedProfile, profile.isBusiness {
                            HStack {
                                Image(systemName: "percent")
                                    .foregroundStyle(.green)
                                Text("BTW-modus ingeschakeld")
                                    .foregroundStyle(.secondary)
                            }
                            .font(.caption)
                        }

                        Divider()

                        Button {
                            showingProfilesSheet = true
                        } label: {
                            HStack {
                                Image(systemName: "person.2")
                                Text("Profielen beheren...")
                            }
                        }
                        .buttonStyle(.link)
                    }
                }

                // Sync Section
                macOSGroupBox(title: "Synchronisatie", icon: "icloud") {
                    VStack(alignment: .leading, spacing: 12) {
                        Toggle(isOn: Binding(
                            get: { cloudKitService.iCloudEnabled },
                            set: { cloudKitService.iCloudEnabled = $0 }
                        )) {
                            Text("iCloud synchronisatie")
                        }
                        .toggleStyle(.switch)

                        Divider()

                        HStack {
                            Image(systemName: cloudKitService.isAccountAvailable ? "checkmark.circle.fill" : "xmark.circle.fill")
                                .foregroundStyle(cloudKitService.isAccountAvailable ? .green : .red)
                            Text("iCloud account:")
                            Spacer()
                            Text(cloudKitService.accountStatusDescription)
                                .foregroundStyle(.secondary)
                        }

                        if let lastSync = cloudKitService.lastSyncDate {
                            HStack {
                                Image(systemName: "clock")
                                    .foregroundStyle(.secondary)
                                Text("Laatste sync:")
                                Spacer()
                                Text(lastSync, style: .relative)
                                    .foregroundStyle(.secondary)
                            }
                        }

                        if let error = cloudKitService.syncError {
                            HStack {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .foregroundStyle(.orange)
                                Text(error)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }

                        HStack {
                            Spacer()
                            Button {
                                cloudKitService.checkAccountStatus()
                                cloudKitService.triggerSync()
                            } label: {
                                HStack {
                                    Image(systemName: "arrow.clockwise")
                                    Text("Nu synchroniseren")
                                }
                            }
                        }
                    }
                }

                // Appearance Section
                macOSGroupBox(title: "Weergave", icon: "paintbrush") {
                    HStack {
                        Text("Thema")
                        Spacer()
                        Picker("", selection: Binding(
                            get: { themeService.currentTheme },
                            set: { themeService.currentTheme = $0 }
                        )) {
                            ForEach(AppTheme.allCases) { theme in
                                HStack {
                                    Image(systemName: theme.iconName)
                                    Text(theme.displayName)
                                }
                                .tag(theme)
                            }
                        }
                        .frame(width: 150)
                    }
                }

                // Data Section
                macOSGroupBox(title: "Gegevens", icon: "folder") {
                    VStack(alignment: .leading, spacing: 8) {
                        Button {
                            showingAccountsSheet = true
                        } label: {
                            HStack {
                                Image(systemName: "creditcard")
                                Text("Rekeningen & Passen beheren...")
                            }
                        }
                        .buttonStyle(.link)

                        Button {
                            showingTagsSheet = true
                        } label: {
                            HStack {
                                Image(systemName: "tag")
                                Text("Tags beheren...")
                            }
                        }
                        .buttonStyle(.link)
                    }
                }

                // About Section
                macOSGroupBox(title: "Over Recurr", icon: "info.circle") {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Recurr")
                                    .font(.headline)
                                Text("Beheer je abonnementen en vaste inkomsten met stijl.")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            Text("Versie 2.1.0")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.secondary.opacity(0.1))
                                .clipShape(RoundedRectangle(cornerRadius: 4))
                        }

                        Divider()

                        Button {
                            showingOnboarding = true
                        } label: {
                            HStack {
                                Image(systemName: "sparkles")
                                Text("Bekijk introductie...")
                            }
                        }
                        .buttonStyle(.link)
                    }
                }
            }
            .padding(32)
            .frame(maxWidth: 600, alignment: .leading)
        }
        .frame(minWidth: 500, minHeight: 400)
        .onAppear {
            createDefaultProfileIfNeeded()
        }
        .sheet(isPresented: $showingProfilesSheet) {
            NavigationStack {
                ProfilesView()
                    .frame(minWidth: 400, minHeight: 300)
            }
        }
        .sheet(isPresented: $showingAccountsSheet) {
            NavigationStack {
                AccountsView()
                    .frame(minWidth: 400, minHeight: 300)
            }
        }
        .sheet(isPresented: $showingTagsSheet) {
            NavigationStack {
                TagsView()
                    .frame(minWidth: 400, minHeight: 300)
            }
        }
        .sheet(isPresented: $showingOnboarding) {
            OnboardingView()
                .frame(minWidth: 500, minHeight: 600)
        }
    }

    private func macOSGroupBox<Content: View>(title: String, icon: String, @ViewBuilder content: () -> Content) -> some View {
        GroupBox {
            content()
                .padding(.top, 4)
        } label: {
            Label(title, systemImage: icon)
                .font(.headline)
        }
    }
    #endif

    // MARK: - iOS Sections

    #if os(iOS)
    private var profileSection: some View {
        Section {
            if profiles.isEmpty {
                Text("Laden...")
                    .foregroundStyle(.secondary)
            } else {
                Picker("Actief profiel", selection: Binding(
                    get: { selectedProfileIdString },
                    set: { selectedProfileIdString = $0 }
                )) {
                    ForEach(profiles) { profile in
                        HStack {
                            Image(systemName: profile.iconName)
                                .foregroundStyle(profile.color)
                            Text(profile.name)
                            if profile.isBusiness {
                                Text("(Zakelijk)")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .tag(profile.id.uuidString)
                    }
                }

                if let profile = selectedProfile, profile.isBusiness {
                    HStack {
                        Label("BTW-modus", systemImage: "percent")
                        Spacer()
                        Text("Ingeschakeld")
                            .foregroundStyle(.secondary)
                    }
                }
            }

            NavigationLink {
                ProfilesView()
            } label: {
                Label("Profielen beheren", systemImage: "person.2")
            }
        } header: {
            Text("Profiel")
        } footer: {
            if let profile = selectedProfile, profile.isBusiness {
                Text("Zakelijke profielen kunnen BTW-tarieven (0%, 9%, 21%) instellen per betaling")
            } else {
                Text("Wissel tussen privé en zakelijke profielen")
            }
        }
    }

    private var syncSection: some View {
        Section {
            Toggle(isOn: Binding(
                get: { cloudKitService.iCloudEnabled },
                set: { cloudKitService.iCloudEnabled = $0 }
            )) {
                Label("iCloud synchronisatie", systemImage: "icloud")
            }

            HStack {
                Label("iCloud account", systemImage: cloudKitService.isAccountAvailable ? "checkmark.icloud" : "xmark.icloud")
                Spacer()
                Text(cloudKitService.accountStatusDescription)
                    .foregroundStyle(cloudKitService.isAccountAvailable ? .green : .red)
            }

            if let lastSync = cloudKitService.lastSyncDate {
                HStack {
                    Label("Laatste sync", systemImage: "arrow.triangle.2.circlepath")
                    Spacer()
                    Text(lastSync, style: .relative)
                        .foregroundStyle(.secondary)
                }
            }

            if let error = cloudKitService.syncError {
                HStack {
                    Label("Fout", systemImage: "exclamationmark.triangle")
                        .foregroundStyle(.red)
                    Spacer()
                    Text(error)
                        .font(.caption)
                        .foregroundStyle(.red)
                        .lineLimit(2)
                }
            }

            Button {
                cloudKitService.checkAccountStatus()
                cloudKitService.triggerSync()
            } label: {
                Label("Synchroniseren", systemImage: "arrow.clockwise")
            }
        } header: {
            Text("Synchronisatie")
        } footer: {
            if !cloudKitService.isAccountAvailable {
                Text("Zorg dat je bent ingelogd met iCloud op dit apparaat (Instellingen > Apple ID > iCloud)")
            } else if cloudKitService.iCloudEnabled {
                Text("Gegevens worden automatisch gesynchroniseerd tussen je apparaten")
            } else {
                Text("Schakel uit om alleen lokaal op te slaan. Herstart de app na wijziging.")
            }
        }
    }

    private var appearanceSection: some View {
        Section(AppStrings.appearance) {
            Picker(AppStrings.theme, selection: Binding(
                get: { themeService.currentTheme },
                set: { themeService.currentTheme = $0 }
            )) {
                ForEach(AppTheme.allCases) { theme in
                    Label(theme.displayName, systemImage: theme.iconName)
                        .tag(theme)
                }
            }
        }
    }

    private var dataSection: some View {
        Section("Gegevens") {
            NavigationLink {
                AccountsView()
            } label: {
                Label("Rekeningen & Passen", systemImage: "creditcard")
            }

            NavigationLink {
                TagsView()
            } label: {
                Label("Tags", systemImage: "tag")
            }
        }
    }

    private var notificationsSection: some View {
        Section {
            if notificationService.isAuthorized {
                HStack {
                    Label("Notificaties", systemImage: "bell.fill")
                    Spacer()
                    Text("Ingeschakeld")
                        .foregroundStyle(.secondary)
                }
            } else {
                Button {
                    Task {
                        let granted = await notificationService.requestAuthorization()
                        if !granted {
                            showingNotificationAlert = true
                        }
                    }
                } label: {
                    Label("Notificaties inschakelen", systemImage: "bell")
                }
            }
        } header: {
            Text("Notificaties")
        } footer: {
            Text("Notificaties worden per abonnement ingesteld")
        }
        .alert("Notificaties geblokkeerd", isPresented: $showingNotificationAlert) {
            Button("Instellingen openen") {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }
            Button("Annuleer", role: .cancel) { }
        } message: {
            Text("Schakel notificaties in via Instellingen > Recurr > Notificaties")
        }
    }

    private var aboutSection: some View {
        Section(AppStrings.about) {
            HStack {
                Text(AppStrings.version)
                Spacer()
                Text("2.1.0")
                    .foregroundStyle(.secondary)
            }

            Button {
                showingOnboarding = true
            } label: {
                Label("Bekijk introductie", systemImage: "sparkles")
            }

            VStack(alignment: .leading, spacing: AppSpacing.xs) {
                Text("Recurr")
                    .font(.headline)
                Text("Beheer je abonnementen en vaste inkomsten met stijl.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(.vertical, AppSpacing.xs)
        }
        .fullScreenCover(isPresented: $showingOnboarding) {
            OnboardingView()
        }
    }
    #endif

    // MARK: - Helpers

    private func createDefaultProfileIfNeeded() {
        if profiles.isEmpty {
            let defaultProfile = Profile(
                name: "Privé",
                iconName: "person.fill",
                colorHex: "6366F1",
                isBusiness: false,
                isDefault: true
            )
            modelContext.insert(defaultProfile)
        }
    }
}

// MARK: - Preview

#Preview {
    SettingsView()
}
