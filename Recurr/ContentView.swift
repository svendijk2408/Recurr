import SwiftUI

struct ContentView: View {
    @Environment(\.themeService) private var themeService
    @AppStorage("has_seen_onboarding") private var hasSeenOnboarding = false
    @State private var selectedTab = 0
    @State private var showingOnboarding = false

    var body: some View {
        Group {
            #if os(macOS)
            macOSLayout
            #else
            iOSLayout
            #endif
        }
        .onAppear {
            if !hasSeenOnboarding {
                showingOnboarding = true
            }
        }
        #if os(iOS)
        .fullScreenCover(isPresented: $showingOnboarding) {
            OnboardingView()
        }
        #else
        .sheet(isPresented: $showingOnboarding) {
            OnboardingView()
                .frame(minWidth: 500, minHeight: 600)
        }
        #endif
    }

    // MARK: - iOS Layout (TabView)

    private var iOSLayout: some View {
        TabView(selection: $selectedTab) {
            DashboardView()
                .tabItem {
                    Label(AppStrings.overview, systemImage: "house.fill")
                }
                .tag(0)

            SubscriptionsView()
                .tabItem {
                    Label(AppStrings.subscriptions, systemImage: "creditcard.fill")
                }
                .tag(1)

            SettingsView()
                .tabItem {
                    Label(AppStrings.settings, systemImage: "gearshape.fill")
                }
                .tag(2)
        }
        .tint(AppColors.primary)
        .preferredColorScheme(themeService.preferredColorScheme)
    }

    // MARK: - macOS Layout (NavigationSplitView)

    #if os(macOS)
    @State private var selectedSidebarItem: SidebarItem? = .overview

    enum SidebarItem: String, CaseIterable, Identifiable {
        case overview
        case subscriptions
        case settings

        var id: String { rawValue }

        var title: String {
            switch self {
            case .overview: return AppStrings.overview
            case .subscriptions: return AppStrings.subscriptions
            case .settings: return AppStrings.settings
            }
        }

        var icon: String {
            switch self {
            case .overview: return "house.fill"
            case .subscriptions: return "creditcard.fill"
            case .settings: return "gearshape.fill"
            }
        }
    }

    private var macOSLayout: some View {
        NavigationSplitView {
            List(SidebarItem.allCases, selection: $selectedSidebarItem) { item in
                Label(item.title, systemImage: item.icon)
                    .tag(item)
            }
            .navigationTitle("Recurr")
            .listStyle(.sidebar)
        } detail: {
            switch selectedSidebarItem {
            case .overview:
                DashboardView()
            case .subscriptions:
                SubscriptionsView()
            case .settings:
                SettingsView()
            case .none:
                Text("Selecteer een item")
            }
        }
        .preferredColorScheme(themeService.preferredColorScheme)
    }
    #endif
}

// MARK: - Preview

#Preview {
    ContentView()
        .modelContainer(for: Subscription.self, inMemory: true)
        .environment(\.themeService, ThemeService())
}
