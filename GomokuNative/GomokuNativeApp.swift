import SwiftUI

@main
struct GomokuNativeApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .onAppear {
                    requestFullScreen()
                }
        }
    }

    private func requestFullScreen() {
        #if targetEnvironment(macCatalyst) || os(visionOS)
        #else
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene else { return }
            if #available(iOS 16.0, *) {
                let geometryRequest = UIWindowScene.GeometryPreferences.iOS(interfaceOrientations: .all)
                windowScene.requestGeometryUpdate(geometryRequest) { _ in }
                windowScene.sizeRestrictions?.minimumSize = CGSize(width: 10000, height: 10000)
                windowScene.sizeRestrictions?.maximumSize = CGSize(width: 10000, height: 10000)
            }
        }
        #endif
    }
}
