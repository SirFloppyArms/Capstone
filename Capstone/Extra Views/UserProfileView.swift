import SwiftUI
import Firebase

struct UserProfileView: View {
    let userID: String

    @State private var username = "Loading..."
    @State private var scores: [String: Int] = [:]
    @State private var totalScore = 0
    @State private var isFriend = false
    @State private var showRemoveConfirmation = false

    @ObservedObject private var session = UserSessionManager.shared

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                profileHeader

                scoreSummaryCard

                if isFriend {
                    Button(role: .destructive) {
                        showRemoveConfirmation = true
                    } label: {
                        Label("Remove Friend", systemImage: "person.crop.circle.badge.minus")
                    }
                    .confirmationDialog("Are you sure you want to remove \(username) as a friend?",
                                        isPresented: $showRemoveConfirmation) {
                        Button("Remove Friend", role: .destructive) {
                            session.removeFriend(userID)
                        }
                    }
                    .buttonStyle(.bordered)
                } else {
                    Button {
                        session.addFriend(userID)
                    } label: {
                        Label("Add Friend", systemImage: "person.crop.circle.badge.plus")
                    }
                    .buttonStyle(.borderedProminent)
                }

                Spacer()
            }
            .padding()
        }
        .onAppear {
            fetchUserData()
            checkFriendStatus()
        }
    }

    // MARK: - Profile Header
    private var profileHeader: some View {
        VStack(spacing: 12) {
            ZStack {
                LinearGradient(gradient: Gradient(colors: [.blue, .green]),
                               startPoint: .topLeading,
                               endPoint: .bottomTrailing)
                    .frame(height: 180)
                    .cornerRadius(20)
                    .overlay(
                        Circle()
                            .fill(Color.white)
                            .frame(width: 100, height: 100)
                            .overlay(
                                Image(systemName: "person.circle.fill")
                                    .resizable()
                                    .scaledToFit()
                                    .foregroundColor(.blue)
                                    .padding(20)
                            )
                            .offset(y: 90)
                    )
            }

            Text(username)
                .font(.title)
                .fontWeight(.bold)
                .padding(.top, 60)

            HStack(spacing: 8) {
                Image(systemName: "star.fill")
                    .foregroundColor(.yellow)
                Text("Total Score: \(totalScore)")
                    .font(.headline)
            }
        }
    }

    // MARK: - Score Breakdown Card
    private var scoreSummaryCard: some View {
        VStack(spacing: 16) {
            Text("📈 Performance Breakdown")
                .font(.title3.bold())
                .frame(maxWidth: .infinity, alignment: .leading)

            ForEach(["Roadmap", "Time Trials", "Daily", "Freestyle"], id: \.self) { category in
                if let score = scores[category] {
                    ScoreBar(label: category, value: score)
                }
            }
        }
        .padding()
        .background(RoundedRectangle(cornerRadius: 20).fill(Color(.systemBackground)).shadow(radius: 4))
    }

    // MARK: - Data Fetching
    private func fetchUserData() {
        let db = Firestore.firestore()
        db.collection("users").document(userID).getDocument { snapshot, _ in
            if let data = snapshot?.data() {
                username = data["username"] as? String ?? "Unknown"

                let roadmap = data.filter { $0.key.contains("RoadmapStage") }
                    .compactMap { $0.value as? Int }.reduce(0, +)
                let timeTrials = data.filter { $0.key.contains("TimeTrialStage") }
                    .compactMap { $0.value as? Int }.reduce(0, +)
                let daily = data["dailyScore"] as? Int ?? 0
                let freestyle = data["freestyleScore"] as? Int ?? 0

                scores = [
                    "Roadmap": roadmap,
                    "Time Trials": timeTrials,
                    "Daily": daily,
                    "Freestyle": freestyle
                ]
                totalScore = roadmap + timeTrials + daily + freestyle
            }
        }
    }

    private func checkFriendStatus() {
        isFriend = session.friendIDs.contains(userID)
    }
}

// MARK: - ScoreBar View
struct ScoreBar: View {
    var label: String
    var value: Int
    private let maxScore = 300

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(label)
                    .font(.subheadline)
                    .bold()
                Spacer()
                Text("\(value)")
                    .font(.subheadline.monospacedDigit())
            }

            ProgressView(value: min(Double(value), Double(maxScore)), total: Double(maxScore))
                .progressViewStyle(LinearProgressViewStyle(tint: .blue))
                .animation(.easeInOut(duration: 0.4), value: value)
        }
    }
}
