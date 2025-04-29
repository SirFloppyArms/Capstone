import SwiftUI
import Foundation
import FirebaseFirestore
import Network
import FirebaseAuth

struct DailyQuestion: Identifiable, Codable {
    let id: UUID
    let text: String
    let choices: [String]
    let correctAnswer: String

    init(id: UUID = UUID(), text: String, choices: [String], correctAnswer: String) {
        self.id = id
        self.text = text
        self.choices = choices
        self.correctAnswer = correctAnswer
    }

    init?(from dictionary: [String: Any]) {
        guard
            let text = dictionary["text"] as? String,
            let choices = dictionary["choices"] as? [String],
            let correctAnswer = dictionary["correctAnswer"] as? String
        else {
            return nil
        }
        self.init(text: text, choices: choices, correctAnswer: correctAnswer)
    }

    func toDictionary() -> [String: Any] {
        [
            "text": text,
            "choices": choices,
            "correctAnswer": correctAnswer
        ]
    }
}

struct DailyQuestionView: View {
    @State private var question: Question?
    @State private var selectedAnswer: String?
    @State private var hasSubmitted = false
    @State private var isCorrect: Bool?
    @State private var isLoading = true
    @State private var showOfflineError = false
    @State private var timeUntilMidnight: TimeInterval = 0
    @State private var timer: Timer?

    var body: some View {
        VStack {
            if isLoading {
                ProgressView("Loading Daily Question...")
            } else if showOfflineError {
                offlineErrorView
            } else if let question = question {
                questionContent(question)
            } else {
                noQuestionView
            }
        }
        .padding()
        .background(Color(.systemGroupedBackground).ignoresSafeArea())
        .onAppear {
            loadDailyQuestion()
            startTimer()
        }
        .onDisappear {
            timer?.invalidate()
        }
    }

    private var noQuestionView: some View {
        VStack(spacing: 20) {
            Image(systemName: "questionmark.circle")
                .font(.system(size: 64))
                .foregroundColor(.blue)

            Text("No Daily Question Available")
                .font(.title2.bold())

            Text("Next question unlocks in")
                .font(.body)
                .foregroundColor(.secondary)

            Text(timeString(from: timeUntilMidnight))
                .font(.system(size: 32, weight: .bold, design: .monospaced))
                .foregroundColor(.green)
        }
        .padding()
    }

    private func startTimer() {
        updateTimeUntilMidnight()

        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            updateTimeUntilMidnight()
        }
    }

    private func updateTimeUntilMidnight() {
        let now = Date()
        let calendar = Calendar.current
        if let midnight = calendar.nextDate(after: now, matching: DateComponents(hour: 0, minute: 0, second: 0), matchingPolicy: .strict, direction: .forward) {
            timeUntilMidnight = midnight.timeIntervalSince(now)
        } else {
            timeUntilMidnight = 0
        }
    }

    private func timeString(from interval: TimeInterval) -> String {
        let hours = Int(interval) / 3600
        let minutes = (Int(interval) % 3600) / 60
        let seconds = Int(interval) % 60
        return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
    }

    private var offlineErrorView: some View {
        VStack(spacing: 16) {
            Image(systemName: "wifi.slash")
                .font(.system(size: 64))
                .foregroundColor(.red)
            Text("You must be online to use Daily Mode.")
                .font(.title3.bold())
                .multilineTextAlignment(.center)
            Button(action: loadDailyQuestion) {
                Text("Retry")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(12)
            }
            .padding(.horizontal)
        }
        .padding()
    }

    @ViewBuilder
    private func questionContent(_ question: Question) -> some View {
        VStack(spacing: 20) {
            Text(question.text)
                .font(.title2)
                .multilineTextAlignment(.center)

            if let imageName = question.imageName, !imageName.isEmpty {
                Image(imageName)
                    .resizable()
                    .scaledToFit()
                    .frame(maxHeight: 200)
                    .cornerRadius(10)
            }

            ForEach(question.choices, id: \.self) { choice in
                Button(action: {
                    if !hasSubmitted {
                        selectedAnswer = choice
                    }
                }) {
                    Text(choice)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(buttonColor(for: choice))
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                .disabled(hasSubmitted)
            }

            if selectedAnswer != nil && !hasSubmitted {
                Button(action: submitAnswer) {
                    Text("Submit Answer")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.green)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                }
                .padding(.top)
            }

            if hasSubmitted {
                Text(isCorrect == true ? "Correct ✅" : "Incorrect ❌")
                    .font(.headline)
                    .foregroundColor(isCorrect == true ? .green : .red)
                    .padding(.top, 10)
            }
        }
        .padding()
    }

    private func loadDailyQuestion() {
        isLoading = true

        let userID = Auth.auth().currentUser?.uid ?? ""
        let db = Firestore.firestore()
        let today = DateFormatter.localizedString(from: Date(), dateStyle: .short, timeStyle: .none)
        
        db.collection("users").document(userID).getDocument { snapshot, error in
            if let data = snapshot?.data(), let lastAnswerDate = data["lastDailyAnswerDate"] as? String, lastAnswerDate == today {
                // Already answered today
                DispatchQueue.main.async {
                    self.isLoading = false
                    self.hasSubmitted = true
                }
            } else {
                // Not answered yet, load question
                DailyQuestionManager.shared.fetchTodaysQuestion { loadedQuestion in
                    DispatchQueue.main.async {
                        self.isLoading = false
                        if let loadedQuestion = loadedQuestion {
                            self.question = loadedQuestion
                            self.showOfflineError = false
                        } else {
                            self.showOfflineError = true
                        }
                    }
                }
            }
        }
    }

    private func submitAnswer() {
        guard let selected = selectedAnswer, let question = question else { return }
        hasSubmitted = true
        isCorrect = (selected == question.correctAnswer)

        let userID = Auth.auth().currentUser?.uid ?? ""
        let db = Firestore.firestore()
        let today = DateFormatter.localizedString(from: Date(), dateStyle: .short, timeStyle: .none)

        let userRef = db.collection("users").document(userID)
        
        userRef.getDocument { snapshot, error in
            if let data = snapshot?.data() {
                if let lastAnswerDate = data["lastDailyAnswerDate"] as? String, lastAnswerDate == today {
                    // Already answered today, do nothing
                    return
                } else {
                    // Save that they've answered today
                    userRef.updateData([
                        "lastDailyAnswerDate": today,
                        "dailyScore": FieldValue.increment(Int64(2))
                    ])
                }
            } else {
                // If no data exists (unlikely), still update
                userRef.setData([
                    "lastDailyAnswerDate": today,
                    "dailyScore": 2
                ], merge: true)
            }
        }
    }

    private func buttonColor(for choice: String) -> Color {
        if hasSubmitted {
            if choice == question?.correctAnswer {
                return .green
            } else if choice == selectedAnswer {
                return .red
            } else {
                return .gray.opacity(0.5)
            }
        } else {
            return selectedAnswer == choice ? Color.blue : Color.blue.opacity(0.5)
        }
    }
}

class DailyQuestionManager {
    static let shared = DailyQuestionManager()
    private let db = Firestore.firestore()
    private let monitor = NWPathMonitor()
    private var isConnected = false

    private init() {
        monitor.pathUpdateHandler = { path in
            self.isConnected = (path.status == .satisfied)
        }
        let queue = DispatchQueue(label: "NetworkMonitor")
        monitor.start(queue: queue)
    }

    func fetchTodaysQuestion(completion: @escaping (Question?) -> Void) {
        guard isConnected else {
            print("⚠️ No internet connection.")
            completion(nil)
            return
        }

        let today = formattedTodayDate()
        let docRef = db.collection("dailyQuestions").document(today)

        docRef.getDocument { snapshot, error in
            if let data = snapshot?.data(), let questionData = data["question"] as? [String: Any], let question = self.parseQuestion(from: questionData) {
                completion(question)
            } else {
                // No fallback allowed anymore
                completion(nil)
            }
        }
    }

    // MARK: - Helpers

    private func formattedTodayDate() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: Date())
    }

    func parseQuestion(from data: [String: Any]) -> Question? {
        guard
            let text = data["text"] as? String,
            let choices = data["choices"] as? [String],
            let correctAnswer = data["correctAnswer"] as? String
        else {
            return nil
        }
        let imageName = data["imageName"] as? String
        return Question(text: text, choices: choices, correctAnswer: correctAnswer, imageName: imageName)
    }
}
