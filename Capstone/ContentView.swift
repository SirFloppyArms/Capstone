import SwiftUI

struct ContentView: View {
    var body: some View {
        NavigationView {
            ZStack {
                LinearGradient(
                    gradient: Gradient(colors: [Color(.systemBlue), Color(.systemTeal)]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()

                VStack(spacing: 30) {
                    HStack {
                        // Top Left: Share button
                        Button(action: {
                            shareApp()
                        }) {
                            Image(systemName: "square.and.arrow.up")
                                .font(.title2)
                                .padding()
                                .background(Color.white.opacity(0.8))
                                .clipShape(Circle())
                        }
                        Spacer()
                        // Top Right: About button
                        NavigationLink(destination: AboutView()) {
                            Image(systemName: "info.circle")
                                .font(.title2)
                                .padding()
                                .background(Color.white.opacity(0.8))
                                .clipShape(Circle())
                        }
                    }
                    .padding(.horizontal)
                    .padding(.top, 10)

                    Spacer()

                    Text("MPI Driving Quiz")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .padding(.bottom, 20)

                    VStack(spacing: 20) {
                        NavigationLink(destination: RoadmapView()) {
                            HomeButtonLabel(title: "Roadmap", color: .blue)
                        }

                        NavigationLink(destination: TimeTrialsView()) {
                            HomeButtonLabel(title: "Time Trials", color: .red)
                        }

                        NavigationLink(destination: LeaderboardView()) {
                            HomeButtonLabel(title: "Leaderboard", color: .purple)
                        }

                        NavigationLink(destination: SettingsView()) {
                            HomeButtonLabel(title: "Settings", color: .gray)
                        }
                    }
                    .padding(.horizontal)

                    Spacer()
                }
            }
        }
        .navigationViewStyle(StackNavigationViewStyle()) // Fixes iPad split issues
    }

    func shareApp() {
        guard let url = URL(string: "https://yourapp.com") else { return }
        let activityVC = UIActivityViewController(activityItems: [url], applicationActivities: nil)

        // Find root controller to present
        if let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let root = scene.windows.first?.rootViewController {
            root.present(activityVC, animated: true, completion: nil)
        }
    }
}

struct HomeButtonLabel: View {
    let title: String
    let color: Color

    var body: some View {
        Text(title)
            .fontWeight(.semibold)
            .frame(maxWidth: .infinity)
            .padding()
            .background(color)
            .foregroundColor(.white)
            .cornerRadius(15)
            .shadow(color: .black.opacity(0.2), radius: 5, x: 0, y: 4)
    }
}

struct AboutView: View {
    var body: some View {
        Text("About This App")
    }
}
