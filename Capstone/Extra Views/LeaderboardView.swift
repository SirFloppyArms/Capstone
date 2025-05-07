import SwiftUI
import Firebase
import FirebaseAuth
import FirebaseFirestore

struct LeaderboardView: View {
    @State private var roadmapScore = 0
    @State private var timeTrialScore = 0
    @State private var dailyScore = 0
    @State private var freestyleScore = 0
    @State private var totalScore = 0

    @State private var roadmapPercent = 0.0
    @State private var timeTrialPercent = 0.0

    @State private var topUsers: [(id: String, username: String, score: Int)] = []
    @State private var showFriendsOnly = false

    @State private var selectedUserID: String?
    @State private var showProfile = false

    @ObservedObject private var session = UserSessionManager.shared

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 30) {
                    header
                    yourStatsSection
                    leaderboardToggle
                    leaderboardSection
                }
                .padding(.top)
            }
            .background(Color(.systemGroupedBackground).ignoresSafeArea())
            .onAppear {
                loadUserScores()
                fetchTopUsers()
            }
            .sheet(isPresented: $showProfile) {
                if let userID = selectedUserID {
                    UserProfileView(userID: userID)
                }
            }
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
            RawStatRow(label: "🎯 Freestyle Score", score: freestyleScore)
            Divider()
            RawStatRow(label: "🏁 Total Score", score: totalScore)
        }
        .padding()
        .background(RoundedRectangle(cornerRadius: 20).fill(Color(.systemBackground)).shadow(radius: 4))
        .padding(.horizontal)
    }

    private var leaderboardToggle: some View {
        Picker("Leaderboard Type", selection: $showFriendsOnly) {
            Text("Global").tag(false)
            Text("Friends").tag(true)
        }
        .pickerStyle(SegmentedPickerStyle())
        .padding(.horizontal)
    }

    private var leaderboardSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(showFriendsOnly ? "👥 Friends Leaderboard" : "🌍 Global Leaderboard")
                .font(.title3.bold())

            ForEach(filteredLeaderboard().prefix(10), id: \.id) { user in
                HStack(spacing: 15) {
                    Text(rankLabel(for: topUsers.firstIndex { $0.id == user.id } ?? 0))
                        .font(.subheadline.bold())

                    Button {
                        selectedUserID = user.id
                        showProfile = true
                    } label: {
                        Text(user.username)
                            .font(.headline)
                            .foregroundColor(.blue)
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

    private func filteredLeaderboard() -> [(id: String, username: String, score: Int)] {
        showFriendsOnly ? topUsers.filter { session.friendIDs.contains($0.id) } : topUsers
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

        db.collection("users").getDocuments(source: .default) { snapshot, _ in
            var leaderboard: [(String, String, Int)] = []

            for doc in snapshot?.documents ?? [] {
                let data = doc.data()
                let id = doc.documentID
                let username = data["username"] as? String ?? "Unknown"
                let roadmap = data.filter { $0.key.contains("RoadmapStage") }.compactMap { $0.value as? Int }.reduce(0, +)
                let timeTrials = data.filter { $0.key.contains("TimeTrialStage") }.compactMap { $0.value as? Int }.reduce(0, +)
                let daily = data["dailyScore"] as? Int ?? 0
                let freestyle = data["freestyleScore"] as? Int ?? 0
                let total = roadmap + timeTrials + daily + freestyle
                leaderboard.append((id, username, total))
            }

            leaderboard.sort { $0.2 > $1.2 }
            topUsers = leaderboard
        }
    }
}

class UserSessionManager: ObservableObject {
    static let shared = UserSessionManager()
    
    @Published var friendIDs: [String] = []
    
    private var listener: ListenerRegistration?
    private let db = Firestore.firestore()
    
    private init() {
        startListeningToFriendChanges()
    }
    
    private func startListeningToFriendChanges() {
        guard let uid = Auth.auth().currentUser?.uid else { return }

        listener = db.collection("users").document(uid)
            .addSnapshotListener { [weak self] snapshot, error in
                guard let data = snapshot?.data(), error == nil else { return }
                self?.friendIDs = data["friends"] as? [String] ?? []
            }
    }
    
    func addFriend(_ friendID: String) {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        db.collection("users").document(uid).updateData([
            "friends": FieldValue.arrayUnion([friendID])
        ])
    }
    
    func removeFriend(_ friendID: String) {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        db.collection("users").document(uid).updateData([
            "friends": FieldValue.arrayRemove([friendID])
        ])
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
