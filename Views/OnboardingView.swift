import SwiftUI

struct OnboardingView: View {
    @EnvironmentObject var dropboxService: DropboxService

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            brandMark
                .padding(.bottom, 28)

            VStack(spacing: 12) {
                Text("StoryRide")
                    .font(.system(size: 40, weight: .bold, design: .rounded))
                    .tracking(-0.5)
                    .foregroundColor(Theme.Color.ink)

                Text("Stories & songs for the road.")
                    .font(.system(size: 15.5, design: .rounded))
                    .foregroundColor(Theme.Color.inkSoft)
                    .multilineTextAlignment(.center)
            }

            Spacer()

            VStack(spacing: 10) {
                Text("STEP ONE")
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .tracking(1.6)
                    .foregroundColor(Theme.Color.inkFaint)

                Button { dropboxService.authenticate() } label: {
                    HStack(spacing: 10) {
                        Image(systemName: "link")
                            .font(.system(size: 17, weight: .semibold))
                        Text("Connect Dropbox")
                            .font(.system(size: 17, weight: .semibold, design: .rounded))
                    }
                    .foregroundColor(Theme.Color.accent)
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(Theme.Color.accent.opacity(0.08))
                    .overlay(
                        Capsule().stroke(Theme.Color.accent.opacity(0.65), lineWidth: 1.5)
                    )
                    .clipShape(Capsule())
                }
                .buttonStyle(.plain)

                Text("Requires a Dropbox account. Audio stays in your Dropbox; StoryRide only reads it.")
                    .font(.system(size: 11.5, design: .rounded))
                    .foregroundColor(Theme.Color.inkFaint)
                    .multilineTextAlignment(.center)
                    .lineSpacing(2)
                    .padding(.top, 6)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 44)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            LinearGradient(
                stops: [
                    .init(color: Theme.Color.accent.opacity(0.10), location: 0),
                    .init(color: Theme.Color.bg, location: 0.45),
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
        )
        .preferredColorScheme(.dark)
    }

    private var brandMark: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(Theme.Color.accent)
                .frame(width: 96, height: 96)
                .shadow(color: Theme.Color.accent.opacity(0.40), radius: 24, x: 0, y: 14)

            Image(systemName: "play.fill")
                .font(.system(size: 38, weight: .bold))
                .foregroundColor(Theme.Color.bg)
                .offset(x: 3)
        }
    }
}
