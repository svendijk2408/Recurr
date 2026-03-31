import SwiftUI
import SwiftData

struct SubscriptionDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Bindable var subscription: Subscription

    @Query private var accounts: [Account]
    @Query private var tags: [Tag]
    @Query private var profiles: [Profile]

    @State private var showingEditSheet = false
    @State private var showingDeleteAlert = false
    @State private var showingCancelTrialAlert = false

    private var account: Account? {
        guard let accountId = subscription.accountId else { return nil }
        return accounts.first { $0.id == accountId }
    }

    private var subscriptionTags: [Tag] {
        let tagIds = subscription.tagUUIDs
        return tags.filter { tagIds.contains($0.id) }
    }

    private var profile: Profile? {
        guard let profileId = subscription.profileId else { return nil }
        return profiles.first { $0.id == profileId }
    }

    private var isBusinessSubscription: Bool {
        profile?.isBusiness ?? false
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: AppSpacing.lg) {
                    // Header with icon and name
                    headerSection

                    // Trial info (if applicable)
                    if subscription.hasTrial {
                        trialCard
                    }

                    // Amount card
                    amountCard

                    // VAT card (only for business subscriptions with VAT)
                    if isBusinessSubscription, let vatRate = subscription.vatRate, vatRate != .zero {
                        vatCard
                    }

                    // Cost breakdown (only if not in trial)
                    if !subscription.isInTrial {
                        costBreakdownCard
                    }

                    // Account & Tags
                    if account != nil || !subscriptionTags.isEmpty {
                        accountAndTagsCard
                    }

                    // Importance Rating (only for expenses)
                    if !subscription.isIncome, let rating = subscription.importanceRating {
                        importanceCard(rating)
                    }

                    // Details card
                    detailsCard

                    // Notes (if any)
                    if let notes = subscription.notes, !notes.isEmpty {
                        notesCard(notes)
                    }
                }
                .padding()
            }
            .background(FloatingOrbsBackground())
            .navigationTitle(subscription.name)
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Sluit") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .primaryAction) {
                    Menu {
                        Button {
                            showingEditSheet = true
                        } label: {
                            Label(AppStrings.edit, systemImage: "pencil")
                        }

                        Button {
                            subscription.isActive.toggle()
                        } label: {
                            Label(
                                subscription.isActive ? "Pauzeer" : "Activeer",
                                systemImage: subscription.isActive ? "pause.fill" : "play.fill"
                            )
                        }

                        if subscription.isInTrial {
                            Button {
                                showingCancelTrialAlert = true
                            } label: {
                                Label("Proefperiode annuleren", systemImage: "xmark.circle")
                            }
                        }

                        Divider()

                        Button(role: .destructive) {
                            showingDeleteAlert = true
                        } label: {
                            Label(AppStrings.delete, systemImage: "trash")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            }
            .sheet(isPresented: $showingEditSheet) {
                AddSubscriptionView(subscriptionToEdit: subscription)
            }
            .alert("Abonnement verwijderen?", isPresented: $showingDeleteAlert) {
                Button("Annuleer", role: .cancel) { }
                Button("Verwijder", role: .destructive) {
                    deleteAndDismiss()
                }
            } message: {
                Text("Dit kan niet ongedaan worden gemaakt.")
            }
            .alert("Proefperiode annuleren?", isPresented: $showingCancelTrialAlert) {
                Button("Annuleer", role: .cancel) { }
                Button("Bevestig", role: .destructive) {
                    subscription.cancelTrial()
                }
            } message: {
                Text("Het abonnement wordt gemarkeerd als geannuleerd en niet meer getoond.")
            }
        }
    }

    // MARK: - Subviews

    private var headerSection: some View {
        VStack(spacing: AppSpacing.md) {
            SubscriptionIconView(subscription: subscription, size: .large)

            VStack(spacing: AppSpacing.xxs) {
                Text(subscription.name)
                    .font(.title2)
                    .fontWeight(.bold)

                CategoryBadge(category: subscription.category)

                HStack(spacing: AppSpacing.xs) {
                    if subscription.isInTrial {
                        Text("Proefperiode")
                            .font(.caption)
                            .foregroundStyle(.blue)
                            .padding(.horizontal, AppSpacing.xs)
                            .padding(.vertical, 2)
                            .background(
                                Capsule()
                                    .fill(.blue.opacity(0.2))
                            )
                    }

                    if !subscription.isActive {
                        Text("Gepauzeerd")
                            .font(.caption)
                            .foregroundStyle(.orange)
                            .padding(.horizontal, AppSpacing.xs)
                            .padding(.vertical, 2)
                            .background(
                                Capsule()
                                    .fill(.orange.opacity(0.2))
                            )
                    }

                    if subscription.trialCancelled {
                        Text("Geannuleerd")
                            .font(.caption)
                            .foregroundStyle(.red)
                            .padding(.horizontal, AppSpacing.xs)
                            .padding(.vertical, 2)
                            .background(
                                Capsule()
                                    .fill(.red.opacity(0.2))
                            )
                    }
                }
            }
        }
    }

    private var trialCard: some View {
        LiquidGlassCard(accentColor: .blue) {
            VStack(spacing: AppSpacing.sm) {
                HStack {
                    Image(systemName: "clock.badge.checkmark")
                        .font(.title2)
                        .foregroundStyle(.blue)

                    VStack(alignment: .leading) {
                        Text("Proefperiode")
                            .font(.headline)

                        if let endDate = subscription.trialEndDate {
                            if subscription.trialCancelled {
                                Text("Geannuleerd")
                                    .font(.subheadline)
                                    .foregroundStyle(.red)
                            } else if let days = subscription.trialDaysRemaining {
                                Text("Nog \(days) dag\(days == 1 ? "" : "en") - eindigt \(endDate.relativeDescription)")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            } else {
                                Text("Afgelopen op \(endDate.shortDescription)")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }

                    Spacer()
                }

                if subscription.isInTrial && !subscription.trialCancelled {
                    Button {
                        showingCancelTrialAlert = true
                    } label: {
                        Text("Annuleren")
                            .font(.subheadline)
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                }
            }
        }
    }

    private var amountCard: some View {
        LiquidGlassCard(accentColor: subscription.isIncome ? AppColors.income : AppColors.expense) {
            VStack(spacing: AppSpacing.sm) {
                Text(subscription.isIncome ? "Inkomst" : "Uitgave")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                AmountDisplayView(
                    amount: subscription.amount,
                    isIncome: subscription.isIncome,
                    size: .xlarge
                )

                FrequencyDisplayView(subscription: subscription)
            }
            .frame(maxWidth: .infinity)
        }
    }

    private var vatCard: some View {
        LiquidGlassCard {
            VStack(alignment: .leading, spacing: AppSpacing.sm) {
                HStack {
                    Image(systemName: "percent")
                        .font(.title2)
                        .foregroundStyle(AppColors.primary)

                    Text("BTW")
                        .font(.headline)

                    Spacer()

                    if let rate = subscription.vatRate {
                        Text(rate.shortName)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .padding(.horizontal, AppSpacing.sm)
                            .padding(.vertical, 4)
                            .background(
                                Capsule()
                                    .fill(AppColors.primary.opacity(0.15))
                            )
                    }
                }

                Divider()

                HStack {
                    Text("Bedrag excl. BTW")
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text(subscription.amountExcludingVAT.currencyFormatted)
                        .fontWeight(.medium)
                }

                HStack {
                    Text("BTW bedrag")
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text(subscription.vatAmount.currencyFormatted)
                        .fontWeight(.medium)
                }

                HStack {
                    Text("Bedrag incl. BTW")
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text(subscription.amount.currencyFormatted)
                        .fontWeight(.semibold)
                }
            }
        }
    }

    private var costBreakdownCard: some View {
        LiquidGlassCard {
            VStack(alignment: .leading, spacing: AppSpacing.md) {
                Text("Kostenberekening")
                    .font(.headline)

                let breakdown = CostCalculator.breakdown(for: subscription)
                CostBreakdownView(breakdown: breakdown, isIncome: subscription.isIncome)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var accountAndTagsCard: some View {
        LiquidGlassCard {
            VStack(alignment: .leading, spacing: AppSpacing.sm) {
                if let account = account {
                    HStack {
                        Image(systemName: account.iconName)
                            .foregroundStyle(Color(hex: account.colorHex))
                        Text(account.name)
                            .font(.subheadline)
                        Spacer()
                    }
                }

                if !subscriptionTags.isEmpty {
                    FlowLayout(spacing: AppSpacing.xs) {
                        ForEach(subscriptionTags) { tag in
                            HStack(spacing: 4) {
                                Circle()
                                    .fill(Color(hex: tag.colorHex))
                                    .frame(width: 8, height: 8)
                                Text(tag.name)
                                    .font(.caption)
                            }
                            .padding(.horizontal, AppSpacing.sm)
                            .padding(.vertical, AppSpacing.xs)
                            .background(
                                Capsule()
                                    .fill(Color(hex: tag.colorHex).opacity(0.15))
                            )
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private func importanceCard(_ rating: Int) -> some View {
        LiquidGlassCard {
            HStack {
                Text("Belangrijkheid")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                Spacer()

                HStack(spacing: 2) {
                    ForEach(0..<5, id: \.self) { index in
                        Image(systemName: index < rating ? "star.fill" : "star")
                            .foregroundStyle(index < rating ? .yellow : .secondary)
                            .font(.caption)
                    }
                }

                if let importance = ImportanceRating(rawValue: rating) {
                    Text(importance.displayName)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    private var detailsCard: some View {
        LiquidGlassCard {
            VStack(spacing: AppSpacing.sm) {
                detailRow(
                    icon: "calendar",
                    label: "Startdatum",
                    value: subscription.startDate.fullDescription
                )

                Divider()

                detailRow(
                    icon: "clock",
                    label: subscription.isInTrial ? "Proefperiode eindigt" : "Volgende betaling",
                    value: subscription.nextPaymentDate.relativeDescription
                )

                Divider()

                detailRow(
                    icon: "repeat",
                    label: "Frequentie",
                    value: subscription.frequencyDisplayName
                )

                if subscription.paymentReminderHours != nil {
                    Divider()

                    if let hours = subscription.paymentReminderHours,
                       let option = PaymentReminderOption(rawValue: hours) {
                        detailRow(
                            icon: "bell",
                            label: "Herinnering",
                            value: option.displayName
                        )
                    }
                }

                Divider()

                detailRow(
                    icon: "eurosign.circle",
                    label: "Valuta",
                    value: subscription.currency
                )

                if let profile = profile {
                    Divider()

                    HStack {
                        Label("Profiel", systemImage: profile.iconName)
                            .foregroundStyle(.secondary)

                        Spacer()

                        HStack(spacing: 4) {
                            Circle()
                                .fill(profile.color)
                                .frame(width: 8, height: 8)
                            Text(profile.name)
                                .fontWeight(.medium)
                            if profile.isBusiness {
                                Text("(Zakelijk)")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
            }
        }
    }

    private func notesCard(_ notes: String) -> some View {
        LiquidGlassCard {
            VStack(alignment: .leading, spacing: AppSpacing.sm) {
                Label("Notities", systemImage: "note.text")
                    .font(.headline)

                Text(notes)
                    .font(.body)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private func detailRow(icon: String, label: String, value: String) -> some View {
        HStack {
            Label(label, systemImage: icon)
                .foregroundStyle(.secondary)

            Spacer()

            Text(value)
                .fontWeight(.medium)
        }
    }

    // MARK: - Actions

    private func deleteAndDismiss() {
        NotificationService.shared.cancelNotifications(for: subscription)
        modelContext.delete(subscription)
        dismiss()
    }
}

// MARK: - Preview

#Preview {
    SubscriptionDetailView(
        subscription: Subscription(
            name: "Netflix Premium",
            amount: 15.99,
            category: .streaming,
            frequencyType: .monthly,
            notes: "Gedeeld met familie"
        )
    )
    .modelContainer(for: [Subscription.self, Account.self, Tag.self], inMemory: true)
}
