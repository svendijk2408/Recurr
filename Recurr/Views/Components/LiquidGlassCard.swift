import SwiftUI

struct LiquidGlassCard<Content: View>: View {
    let accentColor: Color
    let content: Content

    init(
        accentColor: Color = AppColors.primary,
        @ViewBuilder content: () -> Content
    ) {
        self.accentColor = accentColor
        self.content = content()
    }

    var body: some View {
        content
            .padding(AppSpacing.md)
            .background(
                RoundedRectangle(cornerRadius: AppSpacing.cardCornerRadius)
                    .fill(.ultraThinMaterial)
            )
            .overlay(
                RoundedRectangle(cornerRadius: AppSpacing.cardCornerRadius)
                    .stroke(
                        LinearGradient(
                            colors: [
                                .white.opacity(0.5),
                                accentColor.opacity(0.2),
                                .clear
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            )
            .shadow(color: .black.opacity(0.1), radius: 10, y: 5)
    }
}

// MARK: - Interactive Glass Card

struct InteractiveGlassCard<Content: View>: View {
    let accentColor: Color
    let action: () -> Void
    let content: Content

    @State private var isPressed = false

    init(
        accentColor: Color = AppColors.primary,
        action: @escaping () -> Void,
        @ViewBuilder content: () -> Content
    ) {
        self.accentColor = accentColor
        self.action = action
        self.content = content()
    }

    var body: some View {
        Button(action: action) {
            content
                .padding(AppSpacing.md)
                .background(
                    RoundedRectangle(cornerRadius: AppSpacing.cardCornerRadius)
                        .fill(.ultraThinMaterial)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: AppSpacing.cardCornerRadius)
                        .stroke(
                            LinearGradient(
                                colors: [
                                    .white.opacity(0.5),
                                    accentColor.opacity(0.2),
                                    .clear
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                )
                .shadow(color: .black.opacity(0.1), radius: isPressed ? 5 : 10, y: isPressed ? 2 : 5)
                .scaleEffect(isPressed ? 0.98 : 1.0)
        }
        .buttonStyle(.plain)
        .onLongPressGesture(minimumDuration: 0, pressing: { pressing in
            withAnimation(.easeInOut(duration: 0.1)) {
                isPressed = pressing
            }
        }, perform: {})
    }
}

// MARK: - Floating Orb Background

struct FloatingOrbsBackground: View {
    @State private var animate = false

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Primary orb
                Circle()
                    .fill(AppColors.primary.opacity(0.15))
                    .blur(radius: 60)
                    .frame(width: 200, height: 200)
                    .offset(
                        x: animate ? 50 : -50,
                        y: animate ? -30 : 30
                    )
                    .position(
                        x: geometry.size.width * 0.2,
                        y: geometry.size.height * 0.3
                    )

                // Secondary orb
                Circle()
                    .fill(AppColors.secondary.opacity(0.12))
                    .blur(radius: 50)
                    .frame(width: 150, height: 150)
                    .offset(
                        x: animate ? -30 : 30,
                        y: animate ? 20 : -20
                    )
                    .position(
                        x: geometry.size.width * 0.8,
                        y: geometry.size.height * 0.5
                    )

                // Accent orb
                Circle()
                    .fill(AppColors.accent.opacity(0.1))
                    .blur(radius: 40)
                    .frame(width: 120, height: 120)
                    .offset(
                        x: animate ? 20 : -20,
                        y: animate ? -40 : 40
                    )
                    .position(
                        x: geometry.size.width * 0.5,
                        y: geometry.size.height * 0.8
                    )
            }
            .animation(
                .easeInOut(duration: 8)
                    .repeatForever(autoreverses: true),
                value: animate
            )
            .onAppear {
                animate = true
            }
        }
        .ignoresSafeArea()
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        FloatingOrbsBackground()

        VStack(spacing: AppSpacing.md) {
            LiquidGlassCard {
                VStack(alignment: .leading, spacing: AppSpacing.sm) {
                    Text("Glass Card")
                        .font(.headline)
                    Text("Beautiful frosted glass effect")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }

            InteractiveGlassCard(accentColor: AppColors.income) {
                print("Tapped!")
            } content: {
                HStack {
                    Image(systemName: "plus.circle.fill")
                        .font(.title2)
                        .foregroundStyle(AppColors.income)
                    Text("Interactive Card")
                        .font(.headline)
                    Spacer()
                }
            }
        }
        .padding()
    }
}
