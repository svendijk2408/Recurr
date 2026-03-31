import SwiftUI
#if canImport(UIKit)
import PhotosUI
#endif

struct IconPickerView: View {
    @Binding var selectedIconName: String?
    @Binding var customImageData: Data?
    let category: SubscriptionCategory

    @State private var showingSymbolPicker = false
    @State private var searchText = ""

    #if canImport(UIKit)
    @State private var selectedPhotoItem: PhotosPickerItem?
    #endif

    // Common SF Symbols for subscriptions
    private let commonSymbols = [
        "play.fill", "play.tv.fill", "film.fill", "tv.fill",
        "music.note", "music.note.list", "headphones", "hifispeaker.fill",
        "gamecontroller.fill", "dpad.fill", "arcade.stick",
        "app.badge.fill", "laptopcomputer", "desktopcomputer", "iphone",
        "bolt.fill", "powerplug.fill", "wifi", "antenna.radiowaves.left.and.right",
        "shield.fill", "lock.shield.fill", "checkmark.shield.fill",
        "heart.fill", "cross.fill", "pills.fill", "stethoscope",
        "figure.run", "dumbbell.fill", "bicycle", "figure.walk",
        "newspaper.fill", "book.fill", "magazine.fill", "doc.text.fill",
        "graduationcap.fill", "books.vertical.fill", "brain.head.profile",
        "fork.knife", "cup.and.saucer.fill", "takeoutbag.and.cup.and.straw.fill",
        "car.fill", "bus.fill", "tram.fill", "airplane",
        "house.fill", "building.2.fill", "key.fill",
        "creditcard.fill", "banknote.fill", "dollarsign.circle.fill",
        "briefcase.fill", "chart.line.uptrend.xyaxis", "chart.bar.fill",
        "star.fill", "heart.circle.fill", "gift.fill", "tag.fill"
    ]

    var body: some View {
        VStack(spacing: AppSpacing.md) {
            // Current selection preview
            currentSelectionPreview

            // Selection options
            HStack(spacing: AppSpacing.sm) {
                // Use category default
                Button {
                    selectedIconName = nil
                    customImageData = nil
                } label: {
                    Label("Categorie", systemImage: "square.grid.2x2")
                        .font(.subheadline)
                }
                .buttonStyle(.bordered)

                // Pick SF Symbol
                Button {
                    showingSymbolPicker = true
                } label: {
                    Label("Icoon", systemImage: "square.grid.3x3")
                        .font(.subheadline)
                }
                .buttonStyle(.bordered)

                #if canImport(UIKit)
                // Pick photo
                PhotosPicker(
                    selection: $selectedPhotoItem,
                    matching: .images
                ) {
                    Label("Foto", systemImage: "photo")
                        .font(.subheadline)
                }
                .buttonStyle(.bordered)
                .onChange(of: selectedPhotoItem) { _, newValue in
                    Task {
                        if let data = await ImageStorageService.loadFromPhotosPickerItem(newValue) {
                            customImageData = data
                            selectedIconName = nil
                        }
                    }
                }
                #endif
            }
        }
        .sheet(isPresented: $showingSymbolPicker) {
            symbolPickerSheet
        }
    }

    // MARK: - Subviews

    private var currentSelectionPreview: some View {
        HStack {
            SubscriptionIconView(
                iconName: selectedIconName,
                imageData: customImageData,
                category: category,
                size: .large
            )

            VStack(alignment: .leading) {
                Text("Icoon")
                    .font(.headline)

                if customImageData != nil {
                    Text("Eigen foto")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                } else if let iconName = selectedIconName {
                    Text(iconName)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                } else {
                    Text("Categorie standaard")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()
        }
    }

    private var symbolPickerSheet: some View {
        NavigationStack {
            ScrollView {
                LazyVGrid(
                    columns: [GridItem(.adaptive(minimum: 50))],
                    spacing: AppSpacing.sm
                ) {
                    ForEach(filteredSymbols, id: \.self) { symbolName in
                        Button {
                            selectedIconName = symbolName
                            customImageData = nil
                            showingSymbolPicker = false
                        } label: {
                            Image(systemName: symbolName)
                                .font(.title2)
                                .frame(width: 50, height: 50)
                                .background(
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(selectedIconName == symbolName
                                              ? category.color.opacity(0.2)
                                              : Color.clear)
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(
                                            selectedIconName == symbolName
                                            ? category.color
                                            : Color.clear,
                                            lineWidth: 2
                                        )
                                )
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding()
            }
            .searchable(text: $searchText, prompt: "Zoek icoon...")
            .navigationTitle("Kies icoon")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Annuleer") {
                        showingSymbolPicker = false
                    }
                }
            }
        }
    }

    private var filteredSymbols: [String] {
        if searchText.isEmpty {
            return commonSymbols
        }
        return commonSymbols.filter { $0.localizedCaseInsensitiveContains(searchText) }
    }
}

// MARK: - Preview

#Preview {
    struct PreviewWrapper: View {
        @State private var iconName: String? = nil
        @State private var imageData: Data? = nil

        var body: some View {
            Form {
                Section("Icoon kiezen") {
                    IconPickerView(
                        selectedIconName: $iconName,
                        customImageData: $imageData,
                        category: .streaming
                    )
                }
            }
        }
    }

    return PreviewWrapper()
}
