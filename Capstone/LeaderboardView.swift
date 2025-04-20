import SwiftUI
import Firebase
import FirebaseAuth
import FirebaseFirestore

struct LeaderboardView: View {
    @State private var roadmapScore: Int = 0
    @State private var timeTrialScore: Int = 0
    @State private var totalScore: Int = 0
    @State private var roadmapPercent: Double = 0
    @State private var timeTrialPercent: Double = 0
    @State private var totalPercent: Double = 0
    @State private var topUsers: [(username: String, score: Int)] = []

    var body: some View {
        ScrollView {
            VStack(spacing: 25) {
                Text("📊 Leaderboard")
                    .font(.largeTitle.bold())
                    .padding(.top)

                VStack(spacing: 16) {
                    Text("Your Stats")
                        .font(.headline)

                    StatRow(label: "📍 Roadmap Score", score: roadmapScore, total: 300, percent: roadmapPercent)
                    StatRow(label: "⏱ Time Trials Score", score: timeTrialScore, total: 300, percent: timeTrialPercent)
                    Divider()
                    StatRow(label: "🏁 Total Score", score: totalScore, total: 600, percent: totalPercent)
                }
                .padding()
                .background(Color.white.opacity(0.9))
                .cornerRadius(15)
                .shadow(radius: 8)
                .padding(.horizontal)

                VStack(alignment: .leading, spacing: 10) {
                    Text("🌍 Top 10 Global Leaderboard")
                        .font(.headline)

                    ForEach(Array(topUsers.prefix(10).enumerated()), id: \.offset) { index, user in
                        HStack(spacing: 15) {
                            Text("#\(index + 1)")
                                .font(.subheadline)
                                .bold()
                                .frame(width: 30)

                            VStack(alignment: .leading, spacing: 2) {
                                Text(user.username)
                                    .font(.headline)
                                Text(rankForScore(user.score))
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            }

                            Spacer()

                            ScoreRingView(score: user.score)

                            Text("\(user.score)")
                                .font(.headline)
                                .monospacedDigit()
                        }
                        .padding(.vertical, 6)
                    }
                }
                .padding()
                .background(Color.white.opacity(0.9))
                .cornerRadius(15)
                .shadow(radius: 8)
                .padding(.horizontal)

                Spacer()
            }
        }
        .onAppear {
            loadUserScores()
            fetchTopUsers()
        }
    }

    func loadUserScores() {
        let group = DispatchGroup()

        group.enter()
        UserDataManager.shared.fetchRoadmapScores { scores, _ in
            roadmapScore = scores?.values.reduce(0, +) ?? 0
            roadmapPercent = Double(roadmapScore) / 300 * 100
            group.leave()
        }

        group.enter()
        UserDataManager.shared.fetchTimeTrialScores { scores, _ in
            timeTrialScore = scores?.values.reduce(0, +) ?? 0
            timeTrialPercent = Double(timeTrialScore) / 300 * 100
            group.leave()
        }

        group.notify(queue: .main) {
            totalScore = roadmapScore + timeTrialScore
            totalPercent = Double(totalScore) / 600 * 100
        }
    }

    func fetchTopUsers() {
        let db = Firestore.firestore()
        db.collection("users").getDocuments { snapshot, error in
            guard let documents = snapshot?.documents else { return }
            var leaderboard: [(String, Int)] = []

            for doc in documents {
                let data = doc.data()
                let name = data["username"] as? String ?? "Unknown"
                let roadmap = data.filter { $0.key.contains("RoadmapStage") }.compactMap { $0.value as? Int }.reduce(0, +)
                let timeTrials = data.filter { $0.key.contains("TimeTrialStage") }.compactMap { $0.value as? Int }.reduce(0, +)
                leaderboard.append((name, roadmap + timeTrials))
            }

            leaderboard.sort { $0.1 > $1.1 }
            topUsers = leaderboard
        }
    }
}

struct StatRow: View {
    var label: String
    var score: Int
    var total: Int
    var percent: Double

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            HStack {
                Text(label)
                Spacer()
                Text("\(score)/\(total)")
            }
            ProgressView(value: percent / 100)
                .progressViewStyle(LinearProgressViewStyle(tint: .blue))
            Text("\(String(format: "%.2f", percent))% complete")
                .font(.caption)
                .foregroundColor(.gray)
        }
    }
}

struct ScoreRingView: View {
    var score: Int
    var maxScore: Int = 600

    var body: some View {
        let percent = Double(score) / Double(maxScore)
        return ZStack {
            Circle()
                .stroke(Color.gray.opacity(0.3), lineWidth: 6)
                .frame(width: 40, height: 40)
            Circle()
                .trim(from: 0, to: percent)
                .stroke(
                    AngularGradient(
                        gradient: Gradient(colors: [.green, .blue, .purple]),
                        center: .center
                    ),
                    style: StrokeStyle(lineWidth: 6, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .frame(width: 40, height: 40)
                .animation(.easeOut(duration: 1), value: percent)
            Text("\(Int(percent * 100))%")
                .font(.caption2)
                .bold()
        }
    }
}

func rankForScore(_ score: Int) -> String {
    switch score {
    case 0..<100: return "🥉 Bronze"
    case 100..<200: return "🥈 Silver"
    case 200..<300: return "🥇 Gold"
    case 300..<400: return "🏆 Platinum"
    case 400..<500: return "💎 Diamond"
    case 500..<590: return "🔥 Champion"
    case 590...600: return "🌟 Legendary"
    default: return "🎖 Unranked"
    }
}
