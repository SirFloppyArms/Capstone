import SwiftUI
import Firebase
import FirebaseAuth
import FirebaseFirestore

struct LeaderboardView: View {
    @State private var roadmapScore = 0
    @State private var timeTrialScore = 0
    @State private var freestyleScore = 0
    @State private var dailyScore = 0
    @State private var totalScore = 0

    @State private var roadmapPercent = 0.0
    @State private var timeTrialPercent = 0.0

    @State private var topUsers: [(username: String, score: Int)] = []

    var body: some View {
        ScrollView {
            VStack(spacing: 30) {
                header
                yourStatsSection
                leaderboardSection
            }
            .padding(.top)
        }
        .background(Color(.systemGroupedBackground).ignoresSafeArea())
        .onAppear {
            loadUserScores()
            fetchTopUsers()
        }
    }

    private var header: some View {
        Text("📊 Leaderboard")
            .font(.system(size: 34, weight: .bold, design: .rounded))
            .padding(.top)
    }

    private var yourStatsSection: some View {
        VStack(spacing: 16) {
            Text("Your Stats")
                .font(.title2.bold())
                .padding(.bottom, 8)

            StatRow(label: "📍 Roadmap Score", score: roadmapScore, total: 300, percent: roadmapPercent)
            StatRow(label: "⏱ Time Trials Score", score: timeTrialScore, total: 300, percent: timeTrialPercent)
            RawStatRow(label: "🗓 Daily Questions Score", score: dailyScore)
            RawStatRow(label: "🎯 Freestyle Score", score: freestyleScore) // 👈 ADD THIS

            Divider()

            RawStatRow(label: "🏁 Total Score", score: totalScore)
        }
        .padding()
        .background(RoundedRectangle(cornerRadius: 20).fill(Color(.systemBackground)).shadow(radius: 4))
        .padding(.horizontal)
    }

    private var leaderboardSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("🌍 Top 10 Global Leaderboard")
                .font(.title3.bold())
                .padding(.bottom, 4)

            ForEach(Array(topUsers.prefix(10).enumerated()), id: \.offset) { index, user in
                HStack(spacing: 15) {
                    Text(rankLabel(for: index))
                        .font(.subheadline.bold())

                    VStack(alignment: .leading, spacing: 2) {
                        Text(user.username)
                            .font(.headline)
                            .lineLimit(1)
                            .minimumScaleFactor(0.7)
                    }

                    Spacer()

                    Text("\(user.score)")
                        .font(.headline.monospacedDigit())
                        .bold()
                }
                .padding(.vertical, 8)
                .padding(.horizontal, 12)
                .background(Color(.systemGray6).opacity(0.5))
                .cornerRadius(12)
            }
        }
        .padding()
        .background(RoundedRectangle(cornerRadius: 20).fill(Color(.systemBackground)).shadow(radius: 4))
        .padding(.horizontal)
    }

    private func rankLabel(for index: Int) -> String {
        switch index {
        case 0: return "🥇"
        case 1: return "🥈"
        case 2: return "🥉"
        default: return "#\(index + 1)"
        }
    }

    private func loadUserScores() {
        let group = DispatchGroup()

        group.enter()
        UserDataManager.shared.fetchRoadmapScores { scores, _ in
            roadmapScore = scores?.values.reduce(0, +) ?? 0
            roadmapPercent = (Double(roadmapScore) / 300) * 100
            group.leave()
        }

        group.enter()
        UserDataManager.shared.fetchTimeTrialScores { scores, _ in
            timeTrialScore = scores?.values.reduce(0, +) ?? 0
            timeTrialPercent = (Double(timeTrialScore) / 300) * 100
            group.leave()
        }

        group.enter()
        UserDataManager.shared.fetchDailyQuestionScore { score, _ in
            dailyScore = score ?? 0
            group.leave()
        }

        group.enter()
        UserDataManager.shared.fetchFreestyleScore { score in
            freestyleScore = score
            group.leave()
        }

        group.notify(queue: .main) {
            totalScore = roadmapScore + timeTrialScore + dailyScore + freestyleScore
        }
    }

    private func fetchTopUsers() {
        let db = Firestore.firestore()

        // First load from cache
        db.collection("users").getDocuments(source: .cache) { snapshot, _ in
            if let documents = snapshot?.documents {
                updateLeaderboard(from: documents)
            }

            // Then refresh from server
            db.collection("users").getDocuments(source: .server) { snapshot, _ in
                if let documents = snapshot?.documents {
                    updateLeaderboard(from: documents)
                }
            }
        }
    }

    private func updateLeaderboard(from documents: [QueryDocumentSnapshot]) {
        var leaderboard: [(String, Int)] = []

        for doc in documents {
            let data = doc.data()
            let username = data["username"] as? String ?? "Unknown"
            let roadmap = data.filter { $0.key.contains("RoadmapStage") }.compactMap { $0.value as? Int }.reduce(0, +)
            let timeTrials = data.filter { $0.key.contains("TimeTrialStage") }.compactMap { $0.value as? Int }.reduce(0, +)
            let dailyScore = data["dailyScore"] as? Int ?? 0
            let freestyleScore = data["freestyleScore"] as? Int ?? 0

            leaderboard.append((username, roadmap + timeTrials + dailyScore + freestyleScore))
        }

        leaderboard.sort { $0.1 > $1.1 }
        topUsers = leaderboard
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
                .foregroundColor(.secondary)
        }
    }
}

struct RawStatRow: View {
    var label: String
    var score: Int

    var body: some View {
        HStack {
            Text(label)
            Spacer()
            Text("\(score)")
                .bold()
        }
        .padding(.vertical, 4)
    }
}
