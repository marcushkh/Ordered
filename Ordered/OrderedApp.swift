//
//  OrderedApp.swift
//  Ordered
//
//  Created by Kai Hin Hung on 9/7/2024.
//

import AppIntents
import SwiftUI
import UIKit
import RevenueCat

@main
struct OrderedApp: App {
    @StateObject private var persistenceController = PersistenceController.shared
    
    @AppStorage("welcomeScreen") var welcomeScreen: Bool = true
    
    init() {
        if !Purchases.isConfigured {
            Purchases.configure(withAPIKey: "appl_xnYsiELHTsABRcVdfAShQCpYvQK")
        }
        OrderedShortcuts.updateAppShortcutParameters()
    }

    var body: some Scene {
        WindowGroup {
            Group {
                if persistenceController.isReady {
                    ContentView()
                        .environment(\.managedObjectContext, persistenceController.container.viewContext)
                } else if let error = persistenceController.loadingError {
                    ContentUnavailableView {
                        Label("Couldn't Open Your Data", systemImage: "externaldrive.badge.exclamationmark")
                    } description: {
                        Text("Your saved data has been kept. \(error)")
                    } actions: {
                        Button("Try Again") { persistenceController.load() }
                    }
                } else {
                    LaunchSkeletonView()
                }
            }
            .preferredColorScheme(K.darkModeEnabled ? nil : .light)
        }
    }
}

/// Uses only placeholder shapes, so the database can open before any event fetches begin.
private struct LaunchSkeletonView: View {
    private let placeholder = Color.cPrimary.opacity(0.10)

    var body: some View {
        ZStack {
            Color.cBackground.ignoresSafeArea()
            VStack(spacing: 0) {
                VStack(spacing: 16) {
                    HStack {
                        Circle().fill(placeholder).frame(width: 24, height: 24)
                        Spacer()
                        bar(width: 130, height: 22)
                        Spacer()
                        Circle().fill(placeholder).frame(width: 24, height: 24)
                    }
                    .frame(height: 44)

                    HStack {
                        ForEach(0..<7, id: \.self) { _ in
                            Circle().fill(placeholder).frame(width: 32, height: 32)
                                .frame(maxWidth: .infinity)
                        }
                    }
                }
                .padding(.horizontal, K.horizontal_padding)
                .padding(.top, 8)
                .padding(.bottom, 18)
                .background {
                    UnevenRoundedRectangle(bottomLeadingRadius: 30, bottomTrailingRadius: 30)
                        .fill(Color.color1)
                        .ignoresSafeArea(edges: .top)
                }

                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        bar(width: 110, height: 18)
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 14), count: 3), spacing: 14) {
                            ForEach(0..<9, id: \.self) { _ in
                                VStack(spacing: 16) {
                                    bar(width: 60, height: 12)
                                    Circle().fill(placeholder).frame(width: 56, height: 56)
                                    bar(width: 40, height: 10)
                                }
                                .frame(maxWidth: .infinity, minHeight: 142)
                                .background(Color.color5, in: RoundedRectangle(cornerRadius: 20))
                            }
                        }
                    }
                    .padding(.horizontal, K.horizontal_padding)
                    .padding(.top, 20)
                    .padding(.bottom, 90)
                }
                .scrollIndicators(.hidden)
            }
        }
        .overlay(alignment: .bottom) {
            HStack {
                ForEach(0..<5, id: \.self) { _ in
                    RoundedRectangle(cornerRadius: 6).fill(placeholder)
                        .frame(width: 24, height: 24)
                        .frame(maxWidth: .infinity, minHeight: 44)
                }
            }
            .padding(4)
            .background(Color.color1.opacity(0.9), in: Capsule())
            .padding(.horizontal, K.horizontal_padding)
            .padding(.bottom, 10)
        }
        .allowsHitTesting(false)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Opening Ordered")
    }

    private func bar(width: CGFloat, height: CGFloat) -> some View {
        Capsule().fill(placeholder).frame(width: width, height: height)
    }
}

// Source: https://www.youtube.com/watch?v=6SWrpjTMvzs&ab_channel=codingKo
final class AppDelegate: UIResponder, UIApplicationDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            if let window = (application.connectedScenes.first as? UIWindowScene)?.windows.first {
                window.backgroundColor = UIColor(Color(.pageBackground))
            }
        }
        return true
    }
}
