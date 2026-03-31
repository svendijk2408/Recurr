import SwiftUI
import SwiftData

struct ProfilesView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Profile.createdAt) private var profiles: [Profile]

    @State private var showingAddProfile = false
    @State private var profileToEdit: Profile?

    var body: some View {
        List {
            ForEach(profiles) { profile in
                ProfileRowView(profile: profile)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        profileToEdit = profile
                    }
            }
            .onDelete(perform: deleteProfiles)
        }
        .navigationTitle("Profielen")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    showingAddProfile = true
                } label: {
                    Label("Nieuw", systemImage: "plus")
                }
            }
        }
        .sheet(isPresented: $showingAddProfile) {
            AddProfileView()
        }
        .sheet(item: $profileToEdit) { profile in
            AddProfileView(profileToEdit: profile)
        }
        .overlay {
            if profiles.isEmpty {
                ContentUnavailableView(
                    "Geen profielen",
                    systemImage: "person.2",
                    description: Text("Voeg profielen toe voor privé en zakelijk")
                )
            }
        }
    }

    private func deleteProfiles(at offsets: IndexSet) {
        for index in offsets {
            // Don't delete the last profile
            if profiles.count <= 1 { return }

            let profile = profiles[index]
            modelContext.delete(profile)
        }
    }
}

// MARK: - Profile Row View

struct ProfileRowView: View {
    let profile: Profile

    var body: some View {
        HStack(spacing: AppSpacing.md) {
            Image(systemName: profile.iconName)
                .font(.title2)
                .foregroundStyle(profile.color)
                .frame(width: 40, height: 40)
                .background(
                    Circle()
                        .fill(profile.color.opacity(0.15))
                )

            VStack(alignment: .leading, spacing: 2) {
                HStack {
                    Text(profile.name)
                        .font(.headline)

                    if profile.isDefault {
                        Text("Standaard")
                            .font(.caption2)
                            .foregroundStyle(.white)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(
                                Capsule()
                                    .fill(AppColors.primary)
                            )
                    }
                }

                HStack(spacing: AppSpacing.xs) {
                    if profile.isBusiness {
                        Label("Zakelijk", systemImage: "building.2")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    } else {
                        Label("Privé", systemImage: "person")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, AppSpacing.xs)
    }
}

// MARK: - Add/Edit Profile View

struct AddProfileView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    var profileToEdit: Profile?

    @State private var name = ""
    @State private var iconName = "person.fill"
    @State private var colorHex = "6366F1"
    @State private var isBusiness = false
    @State private var isDefault = false

    @State private var showingIconPicker = false
    @State private var showingDeleteAlert = false

    private var isEditing: Bool {
        profileToEdit != nil
    }

    private var title: String {
        isEditing ? "Profiel bewerken" : "Nieuw profiel"
    }

    private var isValid: Bool {
        !name.isEmpty
    }

    private let profileColors = [
        "6366F1", // Indigo
        "8B5CF6", // Purple
        "EC4899", // Pink
        "EF4444", // Red
        "F97316", // Orange
        "EAB308", // Yellow
        "22C55E", // Green
        "14B8A6", // Teal
        "06B6D4", // Cyan
        "3B82F6", // Blue
    ]

    private let profileIcons = [
        "person.fill",
        "person.2.fill",
        "building.2.fill",
        "briefcase.fill",
        "house.fill",
        "star.fill",
        "heart.fill",
        "dollarsign.circle.fill",
        "eurosign.circle.fill",
        "chart.pie.fill"
    ]

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Naam", text: $name)

                    Toggle("Zakelijk profiel", isOn: $isBusiness)
                        .tint(AppColors.primary)

                    Toggle("Standaard profiel", isOn: $isDefault)
                        .tint(AppColors.primary)
                }

                Section("Icoon") {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: AppSpacing.sm) {
                            ForEach(profileIcons, id: \.self) { icon in
                                Button {
                                    iconName = icon
                                } label: {
                                    Image(systemName: icon)
                                        .font(.title2)
                                        .foregroundStyle(iconName == icon ? .white : Color(hex: colorHex))
                                        .frame(width: 44, height: 44)
                                        .background(
                                            Circle()
                                                .fill(iconName == icon ? Color(hex: colorHex) : Color(hex: colorHex).opacity(0.15))
                                        )
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.vertical, AppSpacing.xs)
                    }
                }

                Section("Kleur") {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: AppSpacing.sm) {
                            ForEach(profileColors, id: \.self) { hex in
                                Button {
                                    colorHex = hex
                                } label: {
                                    Circle()
                                        .fill(Color(hex: hex))
                                        .frame(width: 44, height: 44)
                                        .overlay(
                                            Circle()
                                                .stroke(.white, lineWidth: colorHex == hex ? 3 : 0)
                                        )
                                        .overlay(
                                            Image(systemName: "checkmark")
                                                .foregroundStyle(.white)
                                                .opacity(colorHex == hex ? 1 : 0)
                                        )
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.vertical, AppSpacing.xs)
                    }
                }

                if isBusiness {
                    Section {
                        Text("Dit profiel kan BTW-tarieven gebruiken bij betalingen (0%, 9%, 21%)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    } header: {
                        Text("BTW")
                    }
                }

                if isEditing {
                    Section {
                        Button(role: .destructive) {
                            showingDeleteAlert = true
                        } label: {
                            HStack {
                                Spacer()
                                Label("Profiel verwijderen", systemImage: "trash")
                                Spacer()
                            }
                        }
                    }
                }
            }
            .navigationTitle(title)
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Annuleer") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Bewaar") {
                        saveProfile()
                    }
                    .disabled(!isValid)
                }
            }
            .onAppear {
                loadExistingData()
            }
            .alert("Profiel verwijderen?", isPresented: $showingDeleteAlert) {
                Button("Annuleer", role: .cancel) { }
                Button("Verwijder", role: .destructive) {
                    deleteProfile()
                }
            } message: {
                Text("Alle abonnementen in dit profiel worden losgekoppeld.")
            }
        }
    }

    private func loadExistingData() {
        guard let profile = profileToEdit else { return }
        name = profile.name
        iconName = profile.iconName
        colorHex = profile.colorHex
        isBusiness = profile.isBusiness
        isDefault = profile.isDefault
    }

    private func saveProfile() {
        if let existing = profileToEdit {
            existing.name = name
            existing.iconName = iconName
            existing.colorHex = colorHex
            existing.isBusiness = isBusiness
            existing.isDefault = isDefault
        } else {
            let profile = Profile(
                name: name,
                iconName: iconName,
                colorHex: colorHex,
                isBusiness: isBusiness,
                isDefault: isDefault
            )
            modelContext.insert(profile)
        }

        // If this is now default, unset other defaults
        if isDefault {
            let descriptor = FetchDescriptor<Profile>()
            if let allProfiles = try? modelContext.fetch(descriptor) {
                for p in allProfiles {
                    if p.id != profileToEdit?.id && p.isDefault {
                        p.isDefault = false
                    }
                }
            }
        }

        dismiss()
    }

    private func deleteProfile() {
        if let profile = profileToEdit {
            modelContext.delete(profile)
        }
        dismiss()
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        ProfilesView()
    }
    .modelContainer(for: [Profile.self], inMemory: true)
}
