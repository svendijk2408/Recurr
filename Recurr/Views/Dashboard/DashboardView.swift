import SwiftUI
import SwiftData

struct DashboardView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(filter: #Predicate<Subscription> { $0.isActive }) private var activeSubscriptions: [Subscription]
    @Query private var allSubscriptions: [Subscription]
    @Query(sort: \Profile.createdAt) private var profiles: [Profile]

    @AppStorage("selected_profile_id") private var selectedProfileIdString: String = ""

    @State private var selectedSubscription: Subscription?
    @State private var showingAddSheet = false

    private var currentProfile: Profile? {
        if let uuid = UUID(uuidString: selectedProfileIdString) {
            return profiles.first { $0.id == uuid }
        }
        return profiles.first { $0.isDefault } ?? profiles.first
    }

    private var filteredActiveSubscriptions: [Subscription] {
        guard let profileId = currentProfile?.id else { return activeSubscriptions }
        return activeSubscriptions.filter { $0.profileId == profileId || $0.profileId == nil }
    }

    private var filteredAllSubscriptions: [Subscription] {
        guard let profileId = currentProfile?.id else { return allSubscriptions }
        return allSubscriptions.filter { $0.profileId == profileId || $0.profileId == nil }
    }

    private var monthlyIncome: Decimal {
        CostCalculator.totalMonthly(for: filteredActiveSubscriptions, isIncome: true)
    }

    private var monthlyExpenses: Decimal {
        CostCalculator.totalMonthly(for: filteredActiveSubscriptions, isIncome: false)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: AppSpacing.lg) {
                    // Quick add buttons
                    quickAddSection

                    // Balance card
                    BalanceCardView(
                        monthlyIncome: monthlyIncome,
                        monthlyExpenses: monthlyExpenses
                    )

                    // Profile indicator
                    if let profile = currentProfile {
                        profileIndicator(profile)
                    }

                    // Today's payments (if any)
                    TodaysPaymentsWidget(subscriptions: filteredActiveSubscriptions)

                    // Upcoming payments
                    UpcomingPaymentsView(subscriptions: filteredActiveSubscriptions) { subscription in
                        selectedSubscription = subscription
                    }

                    // Stats summary
                    statsSection
                }
                .padding()
            }
            .background(FloatingOrbsBackground())
            .navigationTitle(AppStrings.overview)
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showingAddSheet = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .foregroundStyle(AppColors.primary)
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

    private var quickAddSection: some View {
        HStack(spacing: AppSpacing.sm) {
            QuickAddButton(
                title: "Uitgave",
                icon: "minus.circle.fill",
                color: AppColors.expense,
                isIncome: false
            ) {
                showingAddSheet = true
            }

            QuickAddButton(
                title: "Inkomst",
                icon: "plus.circle.fill",
                color: AppColors.income,
                isIncome: true
            ) {
                showingAddSheet = true
            }
        }
    }

    private func profileIndicator(_ profile: Profile) -> some View {
        HStack(spacing: AppSpacing.sm) {
            Image(systemName: profile.iconName)
                .font(.title3)
                .foregroundStyle(profile.color)

            Text(profile.name)
                .font(.headline)

            if profile.isBusiness {
                Text("Zakelijk")
                    .font(.caption)
                    .foregroundStyle(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        Capsule()
                            .fill(AppColors.primary)
                    )
            }

            Spacer()

            Menu {
                ForEach(profiles) { p in
                    Button {
                        selectedProfileIdString = p.id.uuidString
                    } label: {
                        HStack {
                            Image(systemName: p.iconName)
                            Text(p.name)
                            if p.id == profile.id {
                                Image(systemName: "checkmark")
                            }
                        }
                    }
                }
            } label: {
                Image(systemName: "chevron.down")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: AppSpacing.cardCornerRadius))
    }

    private var statsSection: some View {
        LiquidGlassCard {
            VStack(spacing: AppSpacing.md) {
                HStack {
                    Label("Statistieken", systemImage: "chart.bar.fill")
                        .font(.headline)
                    Spacer()
                }

                LazyVGrid(
                    columns: [GridItem(.flexible()), GridItem(.flexible())],
                    spacing: AppSpacing.md
                ) {
                    StatItem(
                        title: "Totaal actief",
                        value: "\(filteredActiveSubscriptions.count)",
                        icon: "checkmark.circle.fill",
                        color: AppColors.primary
                    )

                    StatItem(
                        title: "Gepauzeerd",
                        value: "\(filteredAllSubscriptions.count - filteredActiveSubscriptions.count)",
                        icon: "pause.circle.fill",
                        color: .orange
                    )

                    StatItem(
                        title: "Jaarlijkse uitgaven",
                        value: CostCalculator.totalYearly(for: filteredActiveSubscriptions, isIncome: false).shortCurrencyFormatted,
                        icon: "calendar",
                        color: AppColors.expense
                    )

                    StatItem(
                        title: "Jaarlijkse inkomsten",
                        value: CostCalculator.totalYearly(for: filteredActiveSubscriptions, isIncome: true).shortCurrencyFormatted,
                        icon: "calendar",
                        color: AppColors.income
                    )
                }
            }
        }
    }
}

// MARK: - Quick Add Button

struct QuickAddButton: View {
    let title: String
    let icon: String
    let color: Color
    let isIncome: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: icon)
                    .foregroundStyle(color)
                Text(title)
                    .fontWeight(.medium)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, AppSpacing.sm)
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: AppSpacing.buttonCornerRadius))
            .overlay(
                RoundedRectangle(cornerRadius: AppSpacing.buttonCornerRadius)
                    .stroke(color.opacity(0.3), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Stat Item

struct StatItem: View {
    let title: String
    let value: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(spacing: AppSpacing.xs) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(color)

            Text(value)
                .font(.title3)
                .fontWeight(.bold)

            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, AppSpacing.sm)
    }
}

// MARK: - Preview

#Preview {
    DashboardView()
        .modelContainer(for: Subscription.self, inMemory: true)
}
