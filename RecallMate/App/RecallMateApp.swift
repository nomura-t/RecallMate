// RecallMateApp.swift
import SwiftUI
import CoreData

@main
struct RecallMateApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    let persistenceController = PersistenceController.shared

    @StateObject private var appSettings = AppSettings()
    @StateObject private var deepLinkManager = DeepLinkManager()

    @State private var isShowingOnboarding = !UserDefaults.standard.bool(forKey: "hasSeenOnboarding")

    init() {
        // ストリークはアプリ起動ではカウントしない（実際の学習活動時のみ）
        StreakNotificationManager.shared.updatePreferredTime()
        StreakNotificationManager.shared.scheduleStreakReminder()
    }

    var body: some Scene {
        WindowGroup {
            ZStack {
                MainView()
                    .environment(\.managedObjectContext, persistenceController.container.viewContext)
                    .environmentObject(appSettings)
                    .environmentObject(deepLinkManager)
            }
            .onOpenURL { url in
                deepLinkManager.handle(url)
            }
        }
    }
}

// MARK: - Deep Link Manager

class DeepLinkManager: ObservableObject {
    @Published var pendingAction: DeepLinkAction?

    enum DeepLinkAction {
        case startReview
    }

    func handle(_ url: URL) {
        guard url.scheme == "recallmate" else { return }

        switch url.host {
        case "review":
            pendingAction = .startReview
        default:
            break
        }
    }

    func consumeAction() -> DeepLinkAction? {
        let action = pendingAction
        pendingAction = nil
        return action
    }
}
