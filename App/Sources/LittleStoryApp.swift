import AppFeatures
import SwiftUI

@main
struct LittleStoryApp: App {
    @State private var container = AppContainer()

    var body: some Scene {
        WindowGroup {
            AppRootView(dependencies: container.dependencies, defaults: container.defaults)
        }
    }
}
