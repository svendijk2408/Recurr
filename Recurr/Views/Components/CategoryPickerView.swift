import SwiftUI

struct CategoryPickerView: View {
    @Binding var selectedCategory: SubscriptionCategory
    let isIncome: Bool

    private var categories: [SubscriptionCategory] {
        isIncome ? SubscriptionCategory.incomeCategories : SubscriptionCategory.expenseCategories
    }

    var body: some View {
        Picker(AppStrings.category, selection: $selectedCategory) {
            ForEach(categories) { category in
                Label {
                    Text(category.displayName)
                } icon: {
                    Image(systemName: category.iconName)
                        .foregroundStyle(category.color)
                }
                .tag(category)
            }
        }
    }
}

// MARK: - Category Grid Picker

struct CategoryGridPicker: View {
    @Binding var selectedCategory: SubscriptionCategory
    let isIncome: Bool

    private var categories: [SubscriptionCategory] {
        isIncome ? SubscriptionCategory.incomeCategories : SubscriptionCategory.expenseCategories
    }

    private let columns = [
        GridItem(.adaptive(minimum: 80), spacing: AppSpacing.sm)
    ]

    var body: some View {
        LazyVGrid(columns: columns, spacing: AppSpacing.sm) {
            ForEach(categories) { category in
                CategoryGridItem(
                    category: category,
                    isSelected: selectedCategory == category
                ) {
                    selectedCategory = category
                }
            }
        }
    }
}

struct CategoryGridItem: View {
    let category: SubscriptionCategory
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: AppSpacing.xs) {
                Image(systemName: category.iconName)
                    .font(.title2)
                    .foregroundStyle(isSelected ? .white : category.color)
                    .frame(width: 44, height: 44)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(isSelected ? category.color : category.color.opacity(0.15))
                    )

                Text(category.displayName)
                    .font(.caption2)
                    .lineLimit(1)
                    .foregroundStyle(isSelected ? category.color : .secondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, AppSpacing.xs)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Category Badge

struct CategoryBadge: View {
    let category: SubscriptionCategory

    var body: some View {
        HStack(spacing: AppSpacing.xxs) {
            Image(systemName: category.iconName)
                .font(.caption2)
            Text(category.displayName)
                .font(.caption2)
        }
        .foregroundStyle(category.color)
        .padding(.horizontal, AppSpacing.xs)
        .padding(.vertical, 2)
        .background(
            Capsule()
                .fill(category.color.opacity(0.15))
        )
    }
}

// MARK: - Preview

#Preview {
    struct PreviewWrapper: View {
        @State private var expenseCategory: SubscriptionCategory = .streaming
        @State private var incomeCategory: SubscriptionCategory = .salary

        var body: some View {
            Form {
                Section("Uitgave categorie") {
                    CategoryPickerView(
                        selectedCategory: $expenseCategory,
                        isIncome: false
                    )
                }

                Section("Inkomst categorie") {
                    CategoryPickerView(
                        selectedCategory: $incomeCategory,
                        isIncome: true
                    )
                }

                Section("Grid Picker") {
                    CategoryGridPicker(
                        selectedCategory: $expenseCategory,
                        isIncome: false
                    )
                }

                Section("Badges") {
                    HStack {
                        CategoryBadge(category: .streaming)
                        CategoryBadge(category: .music)
                        CategoryBadge(category: .salary)
                    }
                }
            }
        }
    }

    return PreviewWrapper()
}
