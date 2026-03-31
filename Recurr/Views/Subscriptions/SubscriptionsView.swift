import SwiftUI
import SwiftData

struct SubscriptionsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Subscription.name) private var subscriptions: [Subscription]
    @Query(sort: \Profile.createdAt) private var profiles: [Profile]

    @AppStorage("selected_profile_id") private var selectedProfileIdString: String = ""

    @State private var showingAddSheet = false
    @State private var selectedSubscription: Subscription?
    @State private var filterType: FilterType = .all
    @State private var searchText = ""
    @State private var showAllProfiles = false

    enum FilterType: String, CaseIterable, Identifiable {
        case all = "all"
        case expenses = "expenses"
        case income = "income"

        var id: String { rawValue }

        var displayName: String {
            switch self {
            case .all: return "Alles"
            case .expenses: return "Uitgaven"
            case .income: return "Inkomsten"
            }
        }
    }

    private var currentProfile: Profile? {
        if let uuid = UUID(uuidString: selectedProfileIdString) {
            return profiles.first { $0.id == uuid }
        }
        return profiles.first { $0.isDefault } ?? profiles.first
    }

    private var filteredSubscriptions: [Subscription] {
        var result = subscriptions

        // Apply profile filter (unless showing all profiles)
        if !showAllProfiles, let profileId = currentProfile?.id {
            result = result.filter { $0.profileId == profileId || $0.profileId == nil }
        }

        // Apply type filter
        switch filterType {
        case .all: break
        case .expenses: result = result.filter { !$0.isIncome }
        case .income: result = result.filter { $0.isIncome }
        }

        // Apply search filter
        if !searchText.isEmpty {
            result = result.filter {
                $0.name.localizedCaseInsensitiveContains(searchText)
            }
        }

        return result
    }

    var body: some View {
        NavigationStack {
            ZStack {
                FloatingOrbsBackground()

                if subscriptions.isEmpty {
                    emptyStateView
                } else {
                    subscriptionsList
                }
            }
            .navigationTitle(AppStrings.subscriptions)
            .searchable(text: $searchText, prompt: "Zoek abonnement...")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showingAddSheet = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .foregroundStyle(AppColors.primary)
                    }
                }

                ToolbarItem(placement: .secondaryAction) {
                    Menu {
                        // Profile filter
                        Section("Profiel") {
                            Button {
                                showAllProfiles = true
                            } label: {
                                HStack {
                                    Text("Alle profielen")
                                    if showAllProfiles {
                                        Image(systemName: "checkmark")
                                    }
                                }
                            }

                            ForEach(profiles) { profile in
                                Button {
                                    selectedProfileIdString = profile.id.uuidString
                                    showAllProfiles = false
                                } label: {
                                    HStack {
                                        Image(systemName: profile.iconName)
                                            .foregroundStyle(profile.color)
                                        Text(profile.name)
                                        if !showAllProfiles && currentProfile?.id == profile.id {
                                            Spacer()
                                            Image(systemName: "checkmark")
                                        }
                                    }
                                }
                            }
                        }

                        Divider()

                        // Type filter
                        Section("Type") {
                            ForEach(FilterType.allCases) { type in
                                Button {
                                    filterType = type
                                } label: {
                                    HStack {
                                        Text(type.displayName)
                                        if filterType == type {
                                            Spacer()
                                            Image(systemName: "checkmark")
                                        }
                                    }
                                }
                            }
                        }
                    } label: {
                        Image(systemName: "line.3.horizontal.decrease.circle")
                    }
                }
            }
            .sheet(isPresented: $showingAddSheet) {
                AddSubscriptionView()
            }
            .sheet(item: $selectedSubscription) { subscription in
                SubscriptionDetailView(subscription: subscription)
            }
        }
    }

    // MARK: - Subviews

    private var emptyStateView: some View {
        ContentUnavailableView {
            Label(AppStrings.noSubscriptions, systemImage: "creditcard")
        } description: {
            Text(AppStrings.addFirstSubscription)
        } actions: {
            Button {
                showingAddSheet = true
            } label: {
                Text(AppStrings.addSubscription)
            }
            .buttonStyle(.borderedProminent)
        }
    }

    private var subscriptionsList: some View {
        List {
            // Summary section
            if !filteredSubscriptions.isEmpty {
                summarySection
            }

            // Subscriptions
            ForEach(filteredSubscriptions) { subscription in
                Button {
                    selectedSubscription = subscription
                } label: {
                    SubscriptionRowView(subscription: subscription)
                }
                .buttonStyle(.plain)
                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                    Button(role: .destructive) {
                        deleteSubscription(subscription)
                    } label: {
                        Label(AppStrings.delete, systemImage: "trash")
                    }
                }
                .swipeActions(edge: .leading) {
                    Button {
                        subscription.isActive.toggle()
                    } label: {
                        Label(
                            subscription.isActive ? "Pauzeer" : "Activeer",
                            systemImage: subscription.isActive ? "pause.fill" : "play.fill"
                        )
                    }
                    .tint(subscription.isActive ? .orange : .green)
                }
            }
        }
        #if os(iOS)
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
        #else
        .listStyle(.sidebar)
        #endif
    }

    private var summarySection: some View {
        Section {
            VStack(alignment: .leading, spacing: AppSpacing.sm) {
                // Profile indicator
                if let profile = currentProfile, !showAllProfiles {
                    HStack(spacing: AppSpacing.xs) {
                        Image(systemName: profile.iconName)
                            .foregroundStyle(profile.color)
                        Text(profile.name)
                            .font(.subheadline)
                            .fontWeight(.medium)
                        if profile.isBusiness {
                            Text("(Zakelijk)")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                } else if showAllProfiles {
                    HStack(spacing: AppSpacing.xs) {
                        Image(systemName: "person.2.fill")
                            .foregroundStyle(AppColors.primary)
                        Text("Alle profielen")
                            .font(.subheadline)
                            .fontWeight(.medium)
                    }
                }

                HStack {
                    VStack(alignment: .leading) {
                        Text("Maandelijks totaal")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)

                        let expenses = CostCalculator.totalMonthly(for: filteredSubscriptions, isIncome: false)
                        let income = CostCalculator.totalMonthly(for: filteredSubscriptions, isIncome: true)

                        switch filterType {
                        case .all:
                            BalanceDisplayView(balance: income - expenses, size: .medium)
                        case .expenses:
                            AmountDisplayView(amount: expenses, isIncome: false, size: .medium)
                        case .income:
                            AmountDisplayView(amount: income, isIncome: true, size: .medium)
                        }
                    }

                    Spacer()

                    VStack(alignment: .trailing) {
                        Text("\(filteredSubscriptions.count)")
                            .font(.title2)
                            .fontWeight(.bold)
                        Text("abonnementen")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .listRowBackground(Color.clear)
    }

    // MARK: - Actions

    private func deleteSubscription(_ subscription: Subscription) {
        withAnimation {
            modelContext.delete(subscription)
        }
    }
}

// MARK: - Preview

#Preview {
    SubscriptionsView()
        .modelContainer(for: Subscription.self, inMemory: true)
}
