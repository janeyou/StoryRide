import SwiftUI
import SwiftData
import SwiftyDropbox

@main
struct StoryRideApp: App {
    init() {
        let key = Bundle.main.object(forInfoDictionaryKey: "DropboxAppKey") as? String ?? ""
        DropboxClientsManager.setupWithAppKey(key)
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(for: [StoryRecord.self, StoryFolder.self])
    }
}

struct ContentView: View {
    @StateObject private var dropboxService = DropboxService()
    @StateObject private var audioPlayer = AudioPlayerService()

    var body: some View {
        Group {
            if dropboxService.isAuthenticated {
                HomeView()
                    .environmentObject(dropboxService)
                    .environmentObject(audioPlayer)
            } else {
                OnboardingView()
                    .environmentObject(dropboxService)
            }
        }
        .onOpenURL { url in
            _ = dropboxService.handleRedirect(url: url)
        }
    }
}
