import SwiftUI
import SwiftData

struct TagsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Tag.name) private var tags: [Tag]

    @State private var showingAddSheet = false
    @State private var editingTag: Tag?

    var body: some View {
        List {
            ForEach(tags) { tag in
                TagRowView(tag: tag)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        editingTag = tag
                    }
            }
            .onDelete(perform: deleteTags)
        }
        .navigationTitle("Tags")
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
            if tags.isEmpty {
                ContentUnavailableView {
                    Label("Geen tags", systemImage: "tag")
                } description: {
                    Text("Voeg tags toe om abonnementen te groeperen")
                } actions: {
                    Button("Voeg toe") {
                        showingAddSheet = true
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
        }
        .sheet(isPresented: $showingAddSheet) {
            AddTagView()
        }
        .sheet(item: $editingTag) { tag in
            AddTagView(tagToEdit: tag)
        }
    }

    private func deleteTags(at offsets: IndexSet) {
        for index in offsets {
            modelContext.delete(tags[index])
        }
    }
}

struct TagRowView: View {
    let tag: Tag

    var body: some View {
        HStack(spacing: AppSpacing.sm) {
            Circle()
                .fill(Color(hex: tag.colorHex))
                .frame(width: 12, height: 12)

            Text(tag.name)
                .font(.headline)

            Spacer()

            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, AppSpacing.xs)
    }
}

struct AddTagView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    var tagToEdit: Tag?

    @State private var name = ""
    @State private var selectedColorHex = "6366F1"

    private var isEditing: Bool { tagToEdit != nil }

    var body: some View {
        NavigationStack {
            Form {
                Section("Naam") {
                    TextField("Bijv. Werk, Entertainment", text: $name)
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
                            if let tag = tagToEdit {
                                modelContext.delete(tag)
                            }
                            dismiss()
                        } label: {
                            HStack {
                                Spacer()
                                Label("Verwijder tag", systemImage: "trash")
                                Spacer()
                            }
                        }
                    }
                }
            }
            .navigationTitle(isEditing ? "Bewerk tag" : "Nieuwe tag")
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
                if let tag = tagToEdit {
                    name = tag.name
                    selectedColorHex = tag.colorHex
                }
            }
        }
    }

    private func save() {
        if let tag = tagToEdit {
            tag.name = name
            tag.colorHex = selectedColorHex
        } else {
            let tag = Tag(
                name: name,
                colorHex: selectedColorHex
            )
            modelContext.insert(tag)
        }
        dismiss()
    }
}

// MARK: - Tag Picker for Subscription Form

struct TagPickerView: View {
    @Query(sort: \Tag.name) private var allTags: [Tag]
    @Binding var selectedTagIds: [UUID]

    var body: some View {
        if allTags.isEmpty {
            Text("Geen tags beschikbaar")
                .foregroundStyle(.secondary)
        } else {
            FlowLayout(spacing: AppSpacing.xs) {
                ForEach(allTags) { tag in
                    TagChip(
                        tag: tag,
                        isSelected: selectedTagIds.contains(tag.id)
                    ) {
                        if selectedTagIds.contains(tag.id) {
                            selectedTagIds.removeAll { $0 == tag.id }
                        } else {
                            selectedTagIds.append(tag.id)
                        }
                    }
                }
            }
        }
    }
}

struct TagChip: View {
    let tag: Tag
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
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
                    .fill(isSelected ? Color(hex: tag.colorHex).opacity(0.2) : Color.secondary.opacity(0.1))
            )
            .overlay(
                Capsule()
                    .stroke(isSelected ? Color(hex: tag.colorHex) : Color.clear, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Flow Layout

struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = arrange(proposal: proposal, subviews: subviews)
        return result.size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = arrange(proposal: proposal, subviews: subviews)

        for (index, frame) in result.frames.enumerated() {
            subviews[index].place(
                at: CGPoint(x: bounds.minX + frame.minX, y: bounds.minY + frame.minY),
                proposal: ProposedViewSize(frame.size)
            )
        }
    }

    private func arrange(proposal: ProposedViewSize, subviews: Subviews) -> (size: CGSize, frames: [CGRect]) {
        let maxWidth = proposal.width ?? .infinity
        var frames: [CGRect] = []
        var x: CGFloat = 0
        var y: CGFloat = 0
        var rowHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)

            if x + size.width > maxWidth && x > 0 {
                x = 0
                y += rowHeight + spacing
                rowHeight = 0
            }

            frames.append(CGRect(origin: CGPoint(x: x, y: y), size: size))
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }

        return (CGSize(width: maxWidth, height: y + rowHeight), frames)
    }
}

#Preview {
    NavigationStack {
        TagsView()
    }
    .modelContainer(for: Tag.self, inMemory: true)
}
