import SwiftUI

struct FrequencyPickerView: View {
    @Binding var frequencyType: FrequencyType
    @Binding var interval: Int
    @Binding var customUnit: CustomFrequencyUnit?

    var body: some View {
        VStack(spacing: AppSpacing.md) {
            // Frequency type picker
            Picker(AppStrings.frequency, selection: $frequencyType) {
                ForEach(FrequencyType.allCases) { type in
                    Text(type.displayName).tag(type)
                }
            }
            .onChange(of: frequencyType) { _, newValue in
                if newValue == .custom && customUnit == nil {
                    customUnit = .months
                    interval = 1
                }
            }

            // Custom interval options
            if frequencyType == .custom {
                customIntervalPicker
            }
        }
    }

    private var customIntervalPicker: some View {
        HStack {
            Text("Elke")
                .foregroundStyle(.secondary)

            Picker("Interval", selection: $interval) {
                ForEach(1...365, id: \.self) { value in
                    Text("\(value)").tag(value)
                }
            }
            .pickerStyle(.menu)
            .frame(width: 80)

            Picker("Eenheid", selection: Binding(
                get: { customUnit ?? .months },
                set: { customUnit = $0 }
            )) {
                ForEach(CustomFrequencyUnit.allCases) { unit in
                    Text(unit.displayName).tag(unit)
                }
            }
            .pickerStyle(.menu)
        }
    }
}

// MARK: - Compact Frequency Display

struct FrequencyDisplayView: View {
    let frequencyType: FrequencyType
    let interval: Int
    let customUnit: CustomFrequencyUnit?

    init(frequencyType: FrequencyType, interval: Int = 1, customUnit: CustomFrequencyUnit? = nil) {
        self.frequencyType = frequencyType
        self.interval = interval
        self.customUnit = customUnit
    }

    init(subscription: Subscription) {
        self.frequencyType = subscription.frequencyType
        self.interval = subscription.frequencyInterval
        self.customUnit = subscription.customFrequencyUnit
    }

    var displayText: String {
        if frequencyType == .custom, let unit = customUnit {
            let unitName = interval == 1 ? unit.singularName : unit.displayName
            return "Elke \(interval) \(unitName)"
        }
        return frequencyType.displayName
    }

    var body: some View {
        HStack(spacing: AppSpacing.xxs) {
            Image(systemName: "repeat")
                .font(.caption)
            Text(displayText)
                .font(.caption)
        }
        .foregroundStyle(.secondary)
    }
}

// MARK: - Preview

#Preview {
    struct PreviewWrapper: View {
        @State private var frequencyType: FrequencyType = .monthly
        @State private var interval: Int = 1
        @State private var customUnit: CustomFrequencyUnit? = nil

        var body: some View {
            Form {
                Section("Frequentie kiezen") {
                    FrequencyPickerView(
                        frequencyType: $frequencyType,
                        interval: $interval,
                        customUnit: $customUnit
                    )
                }

                Section("Weergave") {
                    FrequencyDisplayView(
                        frequencyType: frequencyType,
                        interval: interval,
                        customUnit: customUnit
                    )
                }
            }
        }
    }

    return PreviewWrapper()
}
