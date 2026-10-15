//
//  SettingTopBar.swift
//  Ordered
//
//  Created by Kai Hin Hung on 26/5/2025.
//
import SwiftUI

struct SettingTopBar: View {
    @ObservedObject var viewModel: ContentViewModel

    private var isChecking: Bool {
        !viewModel.hasLoadedSubscription || viewModel.isCheckingSubscription
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack(spacing: 12) {
                Image(systemName: "infinity")
                    .font(.system(size: 25, weight: .medium))
                    .foregroundStyle(.color3)
                    .frame(width: 48, height: 48)
                    .background(.color1, in: RoundedRectangle(cornerRadius: 14))
                    .accessibilityHidden(true)

                VStack(alignment: .leading, spacing: 3) {
                    Text("Ordered Premium")
                        .font(.headline)
                        .foregroundStyle(.color3)
                }
            }

            if isChecking {
                HStack(spacing: 10) {
                    ProgressView()
                        .tint(.color3)
                    Text("Checking subscription…")
                        .font(.subheadline)
                        .foregroundStyle(.color3)
                }
                .frame(maxWidth: .infinity, minHeight: 48)
                .background(.color1, in: RoundedRectangle(cornerRadius: 14))
            } else {
                VStack(alignment: .leading, spacing: 6) {
                    Text(viewModel.isSubscriptionActive ? "Every routine, covered." : "Make space for more.")
                        .font(.title2.weight(.bold))
                        .foregroundStyle(.color3)
                    Text(viewModel.isSubscriptionActive
                         ? "Unlimited events are yours. Thank you for supporting Ordered."
                         : "Create unlimited events and keep all your routines in one place.")
                        .font(.subheadline)
                        .foregroundStyle(.cPrimary.opacity(0.75))
                        .fixedSize(horizontal: false, vertical: true)
                }

                if viewModel.isSubscriptionActive {
                    Label("Premium is active", systemImage: "checkmark.seal.fill")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.color3)
                        .frame(maxWidth: .infinity, minHeight: 48)
                        .background(.color1, in: RoundedRectangle(cornerRadius: 14))
                } else {
                    Button {
                        Task { await viewModel.showPaywallIfNeeded() }
                    } label: {
                        HStack {
                            Text("Explore Premium")
                            Spacer(minLength: 8)
                            Image(systemName: "arrow.right")
                        }
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.cBackground)
                        .padding(.horizontal, 16)
                        .frame(minHeight: 48)
                        .background(.color3, in: RoundedRectangle(cornerRadius: 14))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.color5, in: RoundedRectangle(cornerRadius: 24))
        .overlay {
            RoundedRectangle(cornerRadius: 24)
                .strokeBorder(.color2, lineWidth: 1)
                .allowsHitTesting(false)
        }
        .padding(.top, 12)
        .padding(.bottom, 20)
    }
}
