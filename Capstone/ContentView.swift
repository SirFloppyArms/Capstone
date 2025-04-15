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

// Placeholder views for navigation
struct LeaderboardView: View {
    @State private var totalScore: Int = 0
    @State private var percentage: Double = 0.0
    @State private var roadmapScore: Int = 0
    @State private var timeTrialScore: Int = 0

    var body: some View {
        VStack(spacing: 30) {
            Text("📊 Leaderboard")
                .font(.largeTitle.bold())
                .padding(.top)

            VStack(spacing: 16) {
                HStack {
                    Text("Total Score:")
                        .fontWeight(.semibold)
                    Spacer()
                    Text("\(totalScore)/600")
                        .font(.headline)
                }

                HStack {
                    Text("Percentage:")
                        .fontWeight(.semibold)
                    Spacer()
                    Text("\(String(format: "%.2f", percentage))%")
                        .font(.headline)
                }

                Divider()

                HStack {
                    Text("📍 Roadmap Score:")
                    Spacer()
                    Text("\(roadmapScore)/300")
                }

                HStack {
                    Text("⏱ Time Trials Score:")
                    Spacer()
                    Text("\(timeTrialScore)/300")
                }
            }
            .padding()
            .background(Color.white.opacity(0.9))
            .cornerRadius(15)
            .shadow(radius: 8)
            .padding(.horizontal)

            Spacer()
        }
        .onAppear {
            let breakdown = ScoreManager.getScoreBreakdown()
            totalScore = breakdown.total
            percentage = ScoreManager.getPercentageScore()
            roadmapScore = breakdown.roadmap
            timeTrialScore = breakdown.timeTrials
        }
    }
}

struct SettingsView: View {
    var body: some View {
        Text("Settings")
    }
}

struct AboutView: View {
    var body: some View {
        Text("About This App")
    }
}
