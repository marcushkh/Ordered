//
//  ChangeEvent.swift
//  Ordered
//
//  Created by Kai Hin Hung on 12/3/2025.
//
import SwiftUI
import CoreData
import UIKit

struct ChangeEvent: View{
    @ObservedObject var viewModel: ContentViewModel
    var event: Event? = nil
    @Environment(\.dismiss) private var dismissSheet

    private var editingEvent: Event? { event ?? viewModel.changeEvent }
    
    @State var icon: String = ""
    @State var name: String = ""
    @FocusState var nameTyping: Bool
    
    @State private var activeAlert: EditorAlert?
    @State private var hasLoaded = false
    @State private var originalName = ""
    @State private var originalIcon = ""

    private var hasUnsavedChanges: Bool {
        hasLoaded && (name != originalName || icon != originalIcon)
    }
    
    var body : some View{
        NavigationStack {
            EventDetailsForm(name: $name, emoji: $icon, nameTyping: $nameTyping)
                .onAppear {
                    guard !hasLoaded else { return }
                    icon = editingEvent?.icon ?? "💡"
                    name = editingEvent?.name ?? ""
                    originalName = name
                    originalIcon = icon
                    hasLoaded = true
                    nameTyping = true
                }
                .navigationTitle("Edit Event")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .topBarLeading) {
                        Button("Delete", role: .destructive) {
                            activeAlert = .delete
                        }
                    }
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("Save") {
                            if save() { dismiss() }
                        }
                        .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    }
                }
        }
        .presentationDragIndicator(.visible)
        .background {
            EventDismissalGuard(hasUnsavedChanges: hasUnsavedChanges) {
                nameTyping = false
                activeAlert = .discard
            }
        }
        .alert(item: $activeAlert) { alert in
            switch alert {
            case .delete:
                return Alert(
                    title: Text("Delete Event"),
                    message: Text("Are you sure you want to delete this event?"),
                    primaryButton: .cancel(Text("Cancel")),
                    secondaryButton: .destructive(Text("Delete")) {
                        editingEvent?.delete()
                        dismiss()
                    }
                )
            case .discard:
                return Alert(
                    title: Text("Discard Changes?"),
                    message: Text("Your changes to this event haven't been saved."),
                    primaryButton: .cancel(Text("Cancel")),
                    secondaryButton: .destructive(Text("Discard")) { dismiss() }
                )
            case .saveFailure(let message):
                return Alert(
                    title: Text("Couldn't Save Event"),
                    message: Text(message),
                    primaryButton: .default(Text("Retry")) { if save() { dismiss() } },
                    secondaryButton: .cancel(Text("OK"))
                )
            }
        }
    }

    private enum EditorAlert: Identifiable {
        case delete, discard, saveFailure(String)

        var id: String {
            switch self {
            case .delete: return "delete"
            case .discard: return "discard"
            case .saveFailure: return "saveFailure"
            }
        }
    }

    private func save() -> Bool {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else {
            activeAlert = .saveFailure("Enter an event name before closing.")
            return false
        }
        guard let event = editingEvent, event.isActive else { return true }
        guard event.name != trimmedName || event.icon != icon else {
            return true
        }
        let context = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
        context.persistentStoreCoordinator = Model.viewContext.persistentStoreCoordinator
        do {
            let target = try context.existingObject(with: event.objectID) as! Event
            target.name = trimmedName
            target.icon = icon
            try context.save()
            activeAlert = nil
            originalName = name
            originalIcon = icon
            viewModel.refresh.toggle()
            return true
        } catch {
            context.rollback()
            activeAlert = .saveFailure(error.localizedDescription)
            return false
        }
    }

    func dismiss(){
        if event == nil {
            viewModel.changeEvent = nil
            viewModel.showChangeEvent = false
        }
        dismissSheet()
    }
}

/// Observes a sheet dismissal attempt without dismissing or saving its draft.
private struct EventDismissalGuard: UIViewControllerRepresentable {
    var hasUnsavedChanges: Bool
    var onAttemptToDismiss: () -> Void

    func makeUIViewController(context: Context) -> Controller {
        Controller()
    }

    func updateUIViewController(_ controller: Controller, context: Context) {
        controller.hasUnsavedChanges = hasUnsavedChanges
        controller.onAttemptToDismiss = onAttemptToDismiss
        // SwiftUI attaches the hosting controller after updating this background.
        DispatchQueue.main.async { [weak controller] in
            controller?.installDelegate()
        }
    }

    final class Controller: UIViewController, UIAdaptivePresentationControllerDelegate {
        var hasUnsavedChanges = false
        var onAttemptToDismiss: (() -> Void)?
        private weak var previousDelegate: UIAdaptivePresentationControllerDelegate?

        override func viewDidAppear(_ animated: Bool) {
            super.viewDidAppear(animated)
            installDelegate()
        }

        func installDelegate() {
            var candidate: UIViewController? = parent
            while let controller = candidate {
                if let presentation = controller.presentationController,
                   controller.presentingViewController != nil {
                    if presentation.delegate !== self {
                        previousDelegate = presentation.delegate
                        presentation.delegate = self
                    }
                    return
                }
                candidate = controller.parent
            }
        }

        func presentationControllerShouldDismiss(_ presentationController: UIPresentationController) -> Bool {
            !hasUnsavedChanges && (previousDelegate?.presentationControllerShouldDismiss?(presentationController) ?? true)
        }

        func presentationControllerWillDismiss(_ presentationController: UIPresentationController) {
            previousDelegate?.presentationControllerWillDismiss?(presentationController)
        }

        func presentationControllerDidDismiss(_ presentationController: UIPresentationController) {
            previousDelegate?.presentationControllerDidDismiss?(presentationController)
        }

        func presentationControllerDidAttemptToDismiss(_ presentationController: UIPresentationController) {
            onAttemptToDismiss?()
        }
    }
}
