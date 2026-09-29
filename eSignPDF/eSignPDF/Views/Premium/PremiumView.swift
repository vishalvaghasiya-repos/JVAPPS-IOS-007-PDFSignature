//
//  PremiumView.swift
//

import SwiftUI

struct PremiumView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var subscription = SubscriptionManager.shared
    @StateObject private var vm = PremiumViewModel()

    private let benefits = [
        "Unlimited PDF signing",
        "Unlimited saved signatures",
        "No ads",
        "Faster export",
        "Premium templates",
    ]

    var body: some View {
        ZStack {
            Theme.premiumBackground
                .ignoresSafeArea()

            TimelineView(.animation(minimumInterval: 0.03)) { timeline in
                let t = timeline.date.timeIntervalSinceReferenceDate
                Canvas { ctx, size in
                    let blobs: [(CGPoint, CGFloat, Color)] = [
                        (CGPoint(x: size.width * 0.2, y: size.height * 0.15), 160, Theme.premiumPurple.opacity(0.35)),
                        (CGPoint(x: size.width * 0.85, y: size.height * 0.25), 200, Theme.premiumPink.opacity(0.28)),
                        (CGPoint(x: size.width * 0.55, y: size.height * 0.85), 220, Theme.premiumCyan.opacity(0.22)),
                    ]
                    for (i, blob) in blobs.enumerated() {
                        let wobble = CGFloat(sin(t * 0.6 + Double(i)) * 18)
                        let circle = Path(ellipseIn: CGRect(
                            x: blob.0.x - blob.1 / 2 + wobble,
                            y: blob.0.y - blob.1 / 2,
                            width: blob.1,
                            height: blob.1
                        ))
                        ctx.fill(circle, with: .color(blob.2))
                    }
                }
                .blur(radius: 38)
                .ignoresSafeArea()
            }

            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    HStack {
                        Spacer()
                        Button {
                            dismiss()
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 28))
                                .symbolRenderingMode(.hierarchical)
                                .foregroundStyle(.white.opacity(0.85))
                        }
                    }
                    .padding(.top, 6)

                    VStack(alignment: .leading, spacing: 10) {
                        Text("Go Premium")
                            .font(.system(.largeTitle, design: .rounded).weight(.bold))
                            .foregroundStyle(.white)
                        Text("Unlock the full power of \(AppConstants.appDisplayName).")
                            .font(.system(.body, design: .rounded))
                            .foregroundStyle(.white.opacity(0.82))
                    }

                    VStack(alignment: .leading, spacing: 12) {
                        ForEach(benefits, id: \.self) { line in
                            HStack(spacing: 10) {
                                Image(systemName: "checkmark.seal.fill")
                                    .foregroundStyle(Theme.premiumCyan)
                                Text(line)
                                    .font(.system(.subheadline, design: .rounded).weight(.medium))
                                    .foregroundStyle(.white.opacity(0.92))
                            }
                        }
                    }
                    .padding(18)
                    .glassCard(cornerRadius: 22)

                    Text("Free plan includes up to \(AppConstants.freeSignLimit) signed documents. Upgrade anytime.")
                        .font(.system(.caption, design: .rounded))
                        .foregroundStyle(.white.opacity(0.72))

                    VStack(spacing: 12) {
                        ForEach(vm.displayRows()) { row in
                            subscriptionCard(row)
                        }
                    }

                    PrimaryButton(title: vm.isPurchasing ? "Processing…" : "Continue") {
                        Task { await vm.purchase() }
                    }
                    .disabled(vm.isPurchasing || vm.displayRows().isEmpty)

                    Button {
                        Task { await vm.restore() }
                    } label: {
                        Text("Restore Purchase")
                            .font(.system(.subheadline, design: .rounded).weight(.semibold))
                            .foregroundStyle(.white.opacity(0.92))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                    }
                    .buttonStyle(.plain)
                    .disabled(vm.isPurchasing)

                    if let msg = vm.statusMessage {
                        Text(msg)
                            .font(.system(.footnote, design: .rounded))
                            .foregroundStyle(.white.opacity(0.85))
                            .frame(maxWidth: .infinity)
                    }

                    legalFooter
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 28)
            }
        }
        .task {
            await vm.load()
        }
        .onChange(of: subscription.isPremiumActive) { _, active in
            if active {
                dismiss()
            }
        }
    }

    private func subscriptionCard(_ row: PremiumPackageOption) -> some View {
        let selected = vm.selectedPackageId == row.id
        return Button {
            vm.selectedPackageId = row.id
            HapticFeedback.light()
        } label: {
            HStack {
                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: 8) {
                        Text(row.title)
                            .font(.system(.headline, design: .rounded).weight(.semibold))
                        if let badge = row.badge {
                            Text(badge.uppercased())
                                .font(.system(.caption2, design: .rounded).weight(.bold))
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Capsule().fill(Color.white.opacity(0.14)))
                        }
                    }
                    Text(row.subtitle)
                        .font(.system(.caption, design: .rounded))
                        .foregroundStyle(.white.opacity(0.75))
                }
                Spacer()
                Text(row.displayPrice)
                    .font(.system(.title3, design: .rounded).weight(.bold))
            }
            .foregroundStyle(.white)
            .padding(18)
            .background {
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(Color.white.opacity(selected ? 0.16 : 0.08))
                    .overlay {
                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .stroke(
                                LinearGradient(
                                    colors: selected
                                        ? [Theme.premiumPurple, Theme.premiumPink]
                                        : [Color.white.opacity(0.18), Color.white.opacity(0.08)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: selected ? 1.5 : 1
                            )
                    }
            }
        }
        .buttonStyle(.plain)
    }

    private var legalFooter: some View {
        VStack(spacing: 10) {
            Text("Subscriptions renew automatically unless canceled at least 24 hours before the end of the current period. Manage or cancel anytime in your App Store account settings.")
                .font(.system(.caption2, design: .rounded))
                .multilineTextAlignment(.center)
                .foregroundStyle(.white.opacity(0.68))
                .frame(maxWidth: .infinity)

            HStack(spacing: 10) {
                Link("Privacy Policy", destination: AppConstants.URLs.privacy)
                Text("|")
                    .foregroundStyle(.white.opacity(0.45))
                Link("Terms of Use", destination: AppConstants.URLs.terms)
            }
            .font(.system(.caption, design: .rounded).weight(.semibold))
            .foregroundStyle(.white.opacity(0.9))
        }
        .padding(.top, 4)
    }
}
