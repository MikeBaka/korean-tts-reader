import UIKit

public struct VocabularyExporter {

    public static func share(_ words: Set<String>) {
        // Ensure we have something to share and are on the main thread.
        guard !words.isEmpty else { return }
        
        DispatchQueue.main.async {
            // Format the vocabulary into a single string.
            let vocabString = words.sorted().joined(separator: "\n")
            
            // Create the activity view controller to present the share sheet.
            let activityViewController = UIActivityViewController(activityItems: [vocabString], applicationActivities: nil)

            // Find the key window and root view controller to present from.
            guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                  let rootViewController = windowScene.windows.first(where: { $0.isKeyWindow })?.rootViewController else {
                print("VocabularyExporter Error: Could not find a view controller to present from.")
                return
            }
            
            // On iPad, the share sheet must be presented as a popover.
            if let popoverController = activityViewController.popoverPresentationController {
                popoverController.sourceView = rootViewController.view
                // Center the popover source rect.
                popoverController.sourceRect = CGRect(x: rootViewController.view.bounds.midX, y: rootViewController.view.bounds.midY, width: 0, height: 0)
                popoverController.permittedArrowDirections = []
            }

            // Present the share sheet.
            rootViewController.present(activityViewController, animated: true, completion: nil)
        }
    }
}