import SwiftUI
import Firebase

struct UserProfileView: View {
    let userID: String

    @State private var username = "Loading..."
    @State private var roadmapScore = 0
    @State private var timeTrialScore = 0
    @State private var dailyScore = 0
    @State private var freestyleScore = 0
    @State private var totalScore = 0
    @State private var isFriend = false
    @State private var showRemoveConfirmation = false
    @State private var showFriendActionConfirmation = false
    @State private var friendActionMessage = ""

    @ObservedObject private var session = UserSessionManager.shared

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                profileHeader

                performanceBreakdown

                friendButton
                
                if showFriendActionConfirmation {
                    Text(friendActionMessage)
                        .font(.footnote)
                        .foregroundColor(.green)
                        .transition(.opacity)
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

    private var performanceBreakdown: some View {
        VStack(spacing: 16) {
            Text("📈 Performance Breakdown")
                .font(.title3.bold())
                .frame(maxWidth: .infinity, alignment: .leading)

            StatRow(label: "📍 Roadmap Score", score: roadmapScore, total: 300, percent: percent(for: roadmapScore))
            StatRow(label: "⏱ Time Trials Score", score: timeTrialScore, total: 300, percent: percent(for: timeTrialScore))
            RawStatRow(label: "🗓 Daily Questions Score", score: dailyScore)
            RawStatRow(label: "🎯 Freestyle Score", score: freestyleScore)
        }
        .padding()
        .background(RoundedRectangle(cornerRadius: 20).fill(Color(.systemBackground)).shadow(radius: 4))
    }

    private var friendButton: some View {
        Group {
            if isFriend {
                Button(role: .destructive) {
                    showRemoveConfirmation = true
                } label: {
                    Label("Remove Friend", systemImage: "person.crop.circle.badge.minus")
                }
                .confirmationDialog("Are you sure you want to remove \(username) as a friend?", isPresented: $showRemoveConfirmation) {
                    Button("Remove Friend", role: .destructive) {
                        session.removeFriend(userID)
                        friendActionMessage = "\(username) removed from friends"
                        isFriend = false
                        showFriendActionConfirmation = true
                        hideConfirmationAfterDelay()
                    }
                    Button("Cancel", role: .cancel) { }
                }
                .buttonStyle(.bordered)
            } else {
                Button {
                    session.addFriend(userID)
                    friendActionMessage = "\(username) added as a friend"
                    isFriend = true
                    showFriendActionConfirmation = true
                    hideConfirmationAfterDelay()
                } label: {
                    Label("Add Friend", systemImage: "person.crop.circle.badge.plus")
                }
                .buttonStyle(.borderedProminent)
            }
        }
    }

    private func fetchUserData() {
        let db = Firestore.firestore()
        db.collection("users").document(userID).getDocument { snapshot, _ in
            if let data = snapshot?.data() {
                username = data["username"] as? String ?? "Unknown"

                roadmapScore = data.filter { $0.key.contains("RoadmapStage") }
                    .compactMap { $0.value as? Int }.reduce(0, +)
                timeTrialScore = data.filter { $0.key.contains("TimeTrialStage") }
                    .compactMap { $0.value as? Int }.reduce(0, +)
                dailyScore = data["dailyScore"] as? Int ?? 0
                freestyleScore = data["freestyleScore"] as? Int ?? 0

                totalScore = roadmapScore + timeTrialScore + dailyScore + freestyleScore
            }
        }
    }

    private func checkFriendStatus() {
        isFriend = session.friendIDs.contains(userID)
    }

    private func percent(for score: Int) -> Double {
        min(Double(score) / 300.0 * 100.0, 100.0)
    }
    
    private func hideConfirmationAfterDelay() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            showFriendActionConfirmation = false
        }
    }
}
