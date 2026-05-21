import SwiftUI

struct OnboardingView: View {
    @EnvironmentObject var dropboxService: DropboxService

    var body: some View {
        ZStack {
            Theme.Color.bg.ignoresSafeArea()

            VStack(spacing: 32) {
                Spacer()

                VStack(spacing: 12) {
                    Text("StoryRide")
                        .font(Theme.Font.display(56, weight: .regular))
                        .foregroundColor(Theme.Color.textStrong)

                    Text("Stories & songs for the road")
                        .font(Theme.Font.body(18))
                        .foregroundColor(Theme.Color.textMuted)
                }

                Spacer()

                Button(action: { dropboxService.authenticate() }) {
                    HStack(spacing: 12) {
                        Image(systemName: "link")
                            .font(.system(size: 18, weight: .medium))
                        Text("Connect Dropbox")
                    }
                    .font(Theme.Font.display(20, weight: .medium))
                    .foregroundColor(Theme.Color.bg)
                    .frame(maxWidth: .infinity)
                    .frame(height: 64)
                    .background(Theme.Color.accent)
                    .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.card))
                }
                .padding(.horizontal, 32)

                Spacer().frame(height: 60)
            }
        }
        .preferredColorScheme(.dark)
    }
}
