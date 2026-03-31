import SwiftUI
import SwiftData

struct AddSubscriptionView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @Query(sort: \Account.name) private var accounts: [Account]
    @Query(sort: \Tag.name) private var tags: [Tag]
    @Query(sort: \Profile.createdAt) private var profiles: [Profile]

    @AppStorage("selected_profile_id") private var selectedProfileIdString: String = ""

    // Edit mode
    var subscriptionToEdit: Subscription?

    // Form state - Basic
    @State private var name = ""
    @State private var amountString = ""
    @State private var isIncome = false
    @State private var category: SubscriptionCategory = .other
    @State private var frequencyType: FrequencyType = .monthly
    @State private var frequencyInterval: Int = 1
    @State private var customFrequencyUnit: CustomFrequencyUnit? = nil
    @State private var startDate = Date()
    @State private var nextPaymentDate = Date()
    @State private var iconName: String? = nil
    @State private var customImageData: Data? = nil
    @State private var notes = ""
    @State private var isActive = true

    // Form state - Trial Period
    @State private var hasTrial = false
    @State private var trialEndDate = Date().addingTimeInterval(7 * 24 * 60 * 60) // 7 days from now
    @State private var trialCancelled = false
    @State private var trialReminderDays: TrialReminderOption = .none

    // Form state - Notifications
    @State private var paymentReminderHours: PaymentReminderOption = .none

    // Form state - Account & Tags
    @State private var selectedAccountId: UUID? = nil
    @State private var selectedTagIds: [UUID] = []

    // Form state - Importance Rating
    @State private var importanceRating: Int? = nil

    // Form state - Profile & VAT
    @State private var selectedProfileId: UUID? = nil
    @State private var vatRate: VATRate? = nil

    @State private var showingDeleteAlert = false

    private var currentProfile: Profile? {
        if let profileId = selectedProfileId {
            return profiles.first { $0.id == profileId }
        }
        if let uuid = UUID(uuidString: selectedProfileIdString) {
            return profiles.first { $0.id == uuid }
        }
        return profiles.first { $0.isDefault } ?? profiles.first
    }

    private var isBusinessProfile: Bool {
        currentProfile?.isBusiness ?? false
    }

    private var isEditing: Bool {
        subscriptionToEdit != nil
    }

    private var title: String {
        isEditing ? AppStrings.editSubscription : AppStrings.addSubscription
    }

    private var amount: Decimal {
        let sanitized = amountString
            .replacingOccurrences(of: ",", with: ".")
            .replacingOccurrences(of: "€", with: "")
            .trimmingCharacters(in: .whitespaces)
        return Decimal(string: sanitized) ?? 0
    }

    private var isValid: Bool {
        !name.isEmpty && amount > 0
    }

    var body: some View {
        NavigationStack {
            Form {
                // Basic info section
                basicInfoSection

                // Category & Icon section
                categorySection

                // Frequency section
                frequencySection

                // Dates section
                datesSection

                // Trial Period section (only for expenses)
                if !isIncome {
                    trialSection
                }

                // Notifications section
                notificationsSection

                // Account section
                accountSection

                // Tags section
                tagsSection

                // Importance Rating (only for expenses)
                if !isIncome {
                    importanceSection
                }

                // VAT section (only for business profiles and expenses)
                if isBusinessProfile && !isIncome {
                    vatSection
                }

                // Notes section
                notesSection

                // Cost breakdown preview
                if isValid && !hasTrial {
                    costBreakdownSection
                }

                // Delete button (only when editing)
                if isEditing {
                    deleteSection
                }
            }
            .navigationTitle(title)
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(AppStrings.cancel) {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button(AppStrings.save) {
                        saveSubscription()
                    }
                    .disabled(!isValid)
                }
            }
            .onAppear {
                loadExistingData()
            }
            .onChange(of: isIncome) { _, newValue in
                // Switch to appropriate category when toggling income
                if newValue && !category.isIncomeCategory {
                    category = .salary
                } else if !newValue && category.isIncomeCategory {
                    category = .other
                }
                // Reset importance for income
                if newValue {
                    importanceRating = nil
                    hasTrial = false
                }
            }
            .alert("Abonnement verwijderen?", isPresented: $showingDeleteAlert) {
                Button("Annuleer", role: .cancel) { }
                Button("Verwijder", role: .destructive) {
                    deleteSubscription()
                }
            } message: {
                Text("Dit kan niet ongedaan worden gemaakt.")
            }
        }
    }

    // MARK: - Form Sections

    private var basicInfoSection: some View {
        Section {
            TextField(AppStrings.name, text: $name)
                .textContentType(.name)

            HStack {
                Text(AppDefaults.currencySymbol)
                    .foregroundStyle(.secondary)

                TextField(AppStrings.amount, text: $amountString)
                    #if os(iOS)
                    .keyboardType(.decimalPad)
                    #endif
            }

            Toggle(AppStrings.isIncome, isOn: $isIncome)
                .tint(AppColors.income)

            Toggle(AppStrings.isActive, isOn: $isActive)
                .tint(AppColors.primary)
        }
    }

    private var categorySection: some View {
        Section("Categorie & Icoon") {
            CategoryPickerView(
                selectedCategory: $category,
                isIncome: isIncome
            )

            IconPickerView(
                selectedIconName: $iconName,
                customImageData: $customImageData,
                category: category
            )
        }
    }

    private var frequencySection: some View {
        Section(AppStrings.frequency) {
            FrequencyPickerView(
                frequencyType: $frequencyType,
                interval: $frequencyInterval,
                customUnit: $customFrequencyUnit
            )
        }
    }

    private var datesSection: some View {
        Section("Datums") {
            DatePicker(
                AppStrings.startDate,
                selection: $startDate,
                displayedComponents: .date
            )

            if !hasTrial {
                DatePicker(
                    AppStrings.nextPayment,
                    selection: $nextPaymentDate,
                    displayedComponents: .date
                )
            }
        }
    }

    private var trialSection: some View {
        Section {
            Toggle("Proefperiode", isOn: $hasTrial)
                .tint(AppColors.primary)

            if hasTrial {
                DatePicker(
                    "Proefperiode eindigt",
                    selection: $trialEndDate,
                    in: Date()...,
                    displayedComponents: .date
                )

                if isEditing {
                    Toggle("Geannuleerd tijdens proef", isOn: $trialCancelled)
                        .tint(.orange)
                }

                Picker("Herinnering proefperiode", selection: $trialReminderDays) {
                    ForEach(TrialReminderOption.allCases) { option in
                        Text(option.displayName).tag(option)
                    }
                }
            }
        } header: {
            Text("Proefperiode")
        } footer: {
            if hasTrial {
                Text("Na de proefperiode wordt dit automatisch een actief abonnement, tenzij je het als geannuleerd markeert.")
            }
        }
    }

    private var notificationsSection: some View {
        Section {
            Picker("Betalingsherinnering", selection: $paymentReminderHours) {
                ForEach(PaymentReminderOption.allCases) { option in
                    Text(option.displayName).tag(option)
                }
            }
        } header: {
            Text("Notificaties")
        } footer: {
            if paymentReminderHours != .none {
                Text("Je ontvangt een melding \(paymentReminderHours.displayName.lowercased())")
            }
        }
    }

    private var accountSection: some View {
        Section {
            if accounts.isEmpty {
                NavigationLink {
                    AccountsView()
                } label: {
                    HStack {
                        Text("Geen rekeningen")
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text("Toevoegen")
                            .foregroundStyle(AppColors.primary)
                    }
                }
            } else {
                Picker("Rekening/Pas", selection: $selectedAccountId) {
                    Text("Geen").tag(nil as UUID?)
                    ForEach(accounts) { account in
                        HStack {
                            Image(systemName: account.iconName)
                                .foregroundStyle(Color(hex: account.colorHex))
                            Text(account.name)
                        }
                        .tag(account.id as UUID?)
                    }
                }
            }
        } header: {
            Text("Rekening/Pas")
        }
    }

    private var tagsSection: some View {
        Section {
            if tags.isEmpty {
                NavigationLink {
                    TagsView()
                } label: {
                    HStack {
                        Text("Geen tags")
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text("Toevoegen")
                            .foregroundStyle(AppColors.primary)
                    }
                }
            } else {
                TagPickerView(selectedTagIds: $selectedTagIds)
            }
        } header: {
            Text("Tags")
        }
    }

    private var importanceSection: some View {
        Section {
            Picker("Hoe belangrijk?", selection: $importanceRating) {
                Text("Niet ingesteld").tag(nil as Int?)
                ForEach(ImportanceRating.allCases) { rating in
                    HStack {
                        ForEach(0..<rating.starCount, id: \.self) { _ in
                            Image(systemName: "star.fill")
                                .foregroundStyle(.yellow)
                        }
                        Text(rating.displayName)
                    }
                    .tag(rating.rawValue as Int?)
                }
            }
        } header: {
            Text("Belangrijkheid")
        } footer: {
            Text("Helpt bij het identificeren van abonnementen die je kunt opzeggen")
        }
    }

    private var vatSection: some View {
        Section {
            Picker("BTW-tarief", selection: $vatRate) {
                Text("Geen BTW").tag(nil as VATRate?)
                ForEach(VATRate.allCases) { rate in
                    Text(rate.displayName).tag(rate as VATRate?)
                }
            }

            if let rate = vatRate, rate != .zero {
                VStack(alignment: .leading, spacing: AppSpacing.xs) {
                    HStack {
                        Text("Bedrag excl. BTW")
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text(previewAmountExclVAT)
                            .fontWeight(.medium)
                    }
                    HStack {
                        Text("BTW bedrag")
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text(previewVATAmount)
                            .fontWeight(.medium)
                    }
                }
                .font(.subheadline)
            }
        } header: {
            Text("BTW")
        } footer: {
            Text("Ingevoerd bedrag wordt beschouwd als inclusief BTW")
        }
    }

    private var previewAmountExclVAT: String {
        guard let rate = vatRate, rate != .zero else { return "€0,00" }
        let exclAmount = amount / rate.multiplier
        return exclAmount.currencyFormatted
    }

    private var previewVATAmount: String {
        guard let rate = vatRate, rate != .zero else { return "€0,00" }
        let exclAmount = amount / rate.multiplier
        let vatAmount = amount - exclAmount
        return vatAmount.currencyFormatted
    }

    private var notesSection: some View {
        Section(AppStrings.notes) {
            TextField("Optionele notities...", text: $notes, axis: .vertical)
                .lineLimit(3...6)
        }
    }

    private var costBreakdownSection: some View {
        Section("Kostenberekening") {
            let breakdown = CostCalculator.breakdown(for: previewSubscription)
            CostBreakdownView(breakdown: breakdown, isIncome: isIncome)
        }
    }

    private var deleteSection: some View {
        Section {
            Button(role: .destructive) {
                showingDeleteAlert = true
            } label: {
                HStack {
                    Spacer()
                    Label(AppStrings.deleteSubscription, systemImage: "trash")
                    Spacer()
                }
            }
        }
    }

    // MARK: - Preview Subscription

    private var previewSubscription: Subscription {
        Subscription(
            name: name,
            amount: amount,
            isIncome: isIncome,
            category: category,
            frequencyType: frequencyType,
            frequencyInterval: frequencyInterval,
            customFrequencyUnit: customFrequencyUnit,
            startDate: startDate,
            nextPaymentDate: nextPaymentDate,
            iconName: iconName,
            customImageData: customImageData,
            notes: notes.nilIfEmpty,
            isActive: isActive
        )
    }

    // MARK: - Actions

    private func loadExistingData() {
        guard let subscription = subscriptionToEdit else { return }

        name = subscription.name
        amountString = "\(subscription.amount)"
        isIncome = subscription.isIncome
        category = subscription.category
        frequencyType = subscription.frequencyType
        frequencyInterval = subscription.frequencyInterval
        customFrequencyUnit = subscription.customFrequencyUnit
        startDate = subscription.startDate
        nextPaymentDate = subscription.nextPaymentDate
        iconName = subscription.iconName
        customImageData = subscription.customImageData
        notes = subscription.notes ?? ""
        isActive = subscription.isActive

        // Trial
        hasTrial = subscription.hasTrial
        trialEndDate = subscription.trialEndDate ?? Date().addingTimeInterval(7 * 24 * 60 * 60)
        trialCancelled = subscription.trialCancelled
        trialReminderDays = TrialReminderOption(rawValue: subscription.trialReminderDays ?? 0) ?? .none

        // Notifications
        paymentReminderHours = PaymentReminderOption(rawValue: subscription.paymentReminderHours ?? 0) ?? .none

        // Account & Tags
        selectedAccountId = subscription.accountId
        selectedTagIds = subscription.tagUUIDs

        // Importance
        importanceRating = subscription.importanceRating

        // Profile & VAT
        selectedProfileId = subscription.profileId
        vatRate = subscription.vatRate
    }

    private func saveSubscription() {
        let notificationService = NotificationService.shared

        if let existing = subscriptionToEdit {
            // Cancel existing notifications
            notificationService.cancelNotifications(for: existing)

            // Update existing
            existing.name = name
            existing.amount = amount
            existing.isIncome = isIncome
            existing.category = category
            existing.frequencyType = frequencyType
            existing.frequencyInterval = frequencyInterval
            existing.customFrequencyUnit = customFrequencyUnit
            existing.startDate = startDate
            existing.nextPaymentDate = hasTrial ? trialEndDate : nextPaymentDate
            existing.iconName = iconName
            existing.customImageData = customImageData
            existing.notes = notes.nilIfEmpty
            existing.isActive = isActive

            // Trial
            existing.hasTrial = hasTrial
            existing.trialEndDate = hasTrial ? trialEndDate : nil
            existing.trialCancelled = trialCancelled
            existing.trialReminderDays = trialReminderDays.rawValue > 0 ? trialReminderDays.rawValue : nil

            // Notifications
            existing.paymentReminderHours = paymentReminderHours.rawValue > 0 ? paymentReminderHours.rawValue : nil

            // Account & Tags
            existing.accountId = selectedAccountId
            existing.tagUUIDs = selectedTagIds

            // Importance
            existing.importanceRating = importanceRating

            // Profile & VAT
            existing.profileId = selectedProfileId ?? currentProfile?.id
            existing.vatPercentage = vatRate?.rawValue

            // Schedule new notifications
            notificationService.schedulePaymentReminder(for: existing)
            notificationService.scheduleTrialReminder(for: existing)
        } else {
            // Create new
            let subscription = Subscription(
                name: name,
                amount: amount,
                isIncome: isIncome,
                category: category,
                frequencyType: frequencyType,
                frequencyInterval: frequencyInterval,
                customFrequencyUnit: customFrequencyUnit,
                startDate: startDate,
                nextPaymentDate: hasTrial ? trialEndDate : nextPaymentDate,
                iconName: iconName,
                customImageData: customImageData,
                notes: notes.nilIfEmpty,
                isActive: !hasTrial || !trialCancelled, // Inactive if trial is cancelled
                hasTrial: hasTrial,
                trialEndDate: hasTrial ? trialEndDate : nil,
                trialReminderDays: trialReminderDays.rawValue > 0 ? trialReminderDays.rawValue : nil,
                paymentReminderHours: paymentReminderHours.rawValue > 0 ? paymentReminderHours.rawValue : nil,
                accountId: selectedAccountId,
                tagUUIDs: selectedTagIds,
                importanceRating: importanceRating,
                profileId: selectedProfileId ?? currentProfile?.id,
                vatPercentage: vatRate?.rawValue
            )
            modelContext.insert(subscription)

            // Schedule notifications
            notificationService.schedulePaymentReminder(for: subscription)
            notificationService.scheduleTrialReminder(for: subscription)
        }

        dismiss()
    }

    private func deleteSubscription() {
        if let subscription = subscriptionToEdit {
            NotificationService.shared.cancelNotifications(for: subscription)
            modelContext.delete(subscription)
        }
        dismiss()
    }
}

// MARK: - Preview

#Preview("Add") {
    AddSubscriptionView()
        .modelContainer(for: [Subscription.self, Account.self, Tag.self], inMemory: true)
}

#Preview("Edit") {
    AddSubscriptionView(
        subscriptionToEdit: Subscription(
            name: "Netflix",
            amount: 15.99,
            category: .streaming,
            frequencyType: .monthly
        )
    )
    .modelContainer(for: [Subscription.self, Account.self, Tag.self], inMemory: true)
}
