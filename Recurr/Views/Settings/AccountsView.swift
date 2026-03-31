import SwiftUI
import SwiftData

struct AccountsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Account.name) private var accounts: [Account]

    @State private var showingAddSheet = false
    @State private var editingAccount: Account?

    var body: some View {
        List {
            ForEach(accounts) { account in
                AccountRowView(account: account)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        editingAccount = account
                    }
            }
            .onDelete(perform: deleteAccounts)
        }
        .navigationTitle("Rekeningen & Passen")
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
        .overlay {
            if accounts.isEmpty {
                ContentUnavailableView {
                    Label("Geen rekeningen", systemImage: "creditcard")
                } description: {
                    Text("Voeg rekeningen of passen toe om betalingen te categoriseren")
                } actions: {
                    Button("Voeg toe") {
                        showingAddSheet = true
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
        }
        .sheet(isPresented: $showingAddSheet) {
            AddAccountView()
        }
        .sheet(item: $editingAccount) { account in
            AddAccountView(accountToEdit: account)
        }
    }

    private func deleteAccounts(at offsets: IndexSet) {
        for index in offsets {
            modelContext.delete(accounts[index])
        }
    }
}

struct AccountRowView: View {
    let account: Account

    var body: some View {
        HStack(spacing: AppSpacing.sm) {
            Image(systemName: account.iconName)
                .font(.title2)
                .foregroundStyle(Color(hex: account.colorHex))
                .frame(width: 40, height: 40)
                .background(Color(hex: account.colorHex).opacity(0.15))
                .clipShape(RoundedRectangle(cornerRadius: 10))

            Text(account.name)
                .font(.headline)

            Spacer()

            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, AppSpacing.xs)
    }
}

struct AddAccountView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    var accountToEdit: Account?

    @State private var name = ""
    @State private var selectedIcon = "creditcard.fill"
    @State private var selectedColorHex = "6366F1"

    private var isEditing: Bool { accountToEdit != nil }

    private let icons = [
        "creditcard.fill",
        "banknote.fill",
        "building.columns.fill",
        "wallet.pass.fill",
        "dollarsign.circle.fill",
        "eurosign.circle.fill",
        "bag.fill",
        "cart.fill"
    ]

    var body: some View {
        NavigationStack {
            Form {
                Section("Naam") {
                    TextField("Bijv. ING Betaalrekening", text: $name)
                }

                Section("Icoon") {
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 50))], spacing: AppSpacing.sm) {
                        ForEach(icons, id: \.self) { icon in
                            Button {
                                selectedIcon = icon
                            } label: {
                                Image(systemName: icon)
                                    .font(.title2)
                                    .frame(width: 50, height: 50)
                                    .background(
                                        RoundedRectangle(cornerRadius: 10)
                                            .fill(selectedIcon == icon
                                                  ? Color(hex: selectedColorHex).opacity(0.2)
                                                  : Color.clear)
                                    )
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 10)
                                            .stroke(selectedIcon == icon
                                                    ? Color(hex: selectedColorHex)
                                                    : Color.clear, lineWidth: 2)
                                    )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }

                Section("Kleur") {
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 40))], spacing: AppSpacing.sm) {
                        ForEach(TagColors.options, id: \.hex) { option in
                            Button {
                                selectedColorHex = option.hex
                            } label: {
                                Circle()
                                    .fill(Color(hex: option.hex))
                                    .frame(width: 40, height: 40)
                                    .overlay(
                                        Circle()
                                            .stroke(Color.primary, lineWidth: selectedColorHex == option.hex ? 3 : 0)
                                    )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }

                if isEditing {
                    Section {
                        Button(role: .destructive) {
                            if let account = accountToEdit {
                                modelContext.delete(account)
                            }
                            dismiss()
                        } label: {
                            HStack {
                                Spacer()
                                Label("Verwijder rekening", systemImage: "trash")
                                Spacer()
                            }
                        }
                    }
                }
            }
            .navigationTitle(isEditing ? "Bewerk rekening" : "Nieuwe rekening")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Annuleer") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Bewaar") {
                        save()
                    }
                    .disabled(name.isEmpty)
                }
            }
            .onAppear {
                if let account = accountToEdit {
                    name = account.name
                    selectedIcon = account.iconName
                    selectedColorHex = account.colorHex
                }
            }
        }
    }

    private func save() {
        if let account = accountToEdit {
            account.name = name
            account.iconName = selectedIcon
            account.colorHex = selectedColorHex
        } else {
            let account = Account(
                name: name,
                iconName: selectedIcon,
                colorHex: selectedColorHex
            )
            modelContext.insert(account)
        }
        dismiss()
    }
}

#Preview {
    NavigationStack {
        AccountsView()
    }
    .modelContainer(for: Account.self, inMemory: true)
}
