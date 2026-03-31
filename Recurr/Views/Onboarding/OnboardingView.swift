import SwiftUI

struct OnboardingView: View {
    @Environment(\.dismiss) private var dismiss
    @AppStorage("has_seen_onboarding") private var hasSeenOnboarding = false

    @State private var currentPage = 0

    private let features: [OnboardingFeature] = [
        OnboardingFeature(
            icon: "creditcard.fill",
            iconColor: .indigo,
            title: "Beheer je abonnementen",
            description: "Houd al je maandelijkse abonnementen en vaste kosten overzichtelijk bij op één plek."
        ),
        OnboardingFeature(
            icon: "chart.pie.fill",
            iconColor: .purple,
            title: "Inzicht in je uitgaven",
            description: "Bekijk direct hoeveel je per dag, week, maand of jaar uitgeeft aan al je abonnementen."
        ),
        OnboardingFeature(
            icon: "eurosign.circle.fill",
            iconColor: .green,
            title: "Inkomsten & Uitgaven",
            description: "Voeg ook je vaste inkomsten toe en zie in één oogopslag je maandelijkse balans."
        ),
        OnboardingFeature(
            icon: "bell.badge.fill",
            iconColor: .orange,
            title: "Slimme herinneringen",
            description: "Ontvang meldingen voordat een betaling plaatsvindt of een proefperiode afloopt."
        ),
        OnboardingFeature(
            icon: "icloud.fill",
            iconColor: .blue,
            title: "Overal gesynchroniseerd",
            description: "Je gegevens worden automatisch gesynchroniseerd via iCloud naar al je Apple apparaten."
        )
    ]

    var body: some View {
        ZStack {
            // Background
            FloatingOrbsBackground()

            VStack(spacing: 0) {
                // Header
                VStack(spacing: AppSpacing.sm) {
                    Image(systemName: "arrow.triangle.2.circlepath.circle.fill")
                        .font(.system(size: 60))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [AppColors.primary, AppColors.secondary],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )

                    Text("Welkom bij Recurr")
                        .font(.largeTitle)
                        .fontWeight(.bold)

                    Text("Versie 2.1.0")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .padding(.top, AppSpacing.xl)
                .padding(.bottom, AppSpacing.lg)

                // Feature cards
                TabView(selection: $currentPage) {
                    ForEach(Array(features.enumerated()), id: \.offset) { index, feature in
                        FeatureCard(feature: feature)
                            .tag(index)
                    }
                }
                #if os(iOS)
                .tabViewStyle(.page(indexDisplayMode: .never))
                #endif

                // Page indicator
                HStack(spacing: AppSpacing.xs) {
                    ForEach(0..<features.count, id: \.self) { index in
                        Circle()
                            .fill(index == currentPage ? AppColors.primary : Color.secondary.opacity(0.3))
                            .frame(width: 8, height: 8)
                            .animation(.easeInOut, value: currentPage)
                    }
                }
                .padding(.vertical, AppSpacing.md)

                // Buttons
                VStack(spacing: AppSpacing.sm) {
                    if currentPage < features.count - 1 {
                        Button {
                            withAnimation {
                                currentPage += 1
                            }
                        } label: {
                            Text("Volgende")
                                .fontWeight(.semibold)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(AppColors.primary)
                                .foregroundStyle(.white)
                                .clipShape(RoundedRectangle(cornerRadius: AppSpacing.buttonCornerRadius))
                        }

                        Button {
                            completeOnboarding()
                        } label: {
                            Text("Overslaan")
                                .foregroundStyle(.secondary)
                        }
                    } else {
                        Button {
                            completeOnboarding()
                        } label: {
                            Text("Aan de slag")
                                .fontWeight(.semibold)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(
                                    LinearGradient(
                                        colors: [AppColors.primary, AppColors.secondary],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .foregroundStyle(.white)
                                .clipShape(RoundedRectangle(cornerRadius: AppSpacing.buttonCornerRadius))
                        }
                    }
                }
                .padding(.horizontal, AppSpacing.lg)
                .padding(.bottom, AppSpacing.xl)
            }
        }
    }

    private func completeOnboarding() {
        hasSeenOnboarding = true
        dismiss()
    }
}

// MARK: - Onboarding Feature Model

struct OnboardingFeature {
    let icon: String
    let iconColor: Color
    let title: String
    let description: String
}

// MARK: - Feature Card

struct FeatureCard: View {
    let feature: OnboardingFeature

    var body: some View {
        VStack(spacing: AppSpacing.lg) {
            // Icon
            ZStack {
                Circle()
                    .fill(feature.iconColor.opacity(0.15))
                    .frame(width: 100, height: 100)

                Image(systemName: feature.icon)
                    .font(.system(size: 44))
                    .foregroundStyle(feature.iconColor)
            }

            // Text
            VStack(spacing: AppSpacing.sm) {
                Text(feature.title)
                    .font(.title2)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)

                Text(feature.description)
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.horizontal, AppSpacing.lg)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Preview

#Preview {
    OnboardingView()
}
