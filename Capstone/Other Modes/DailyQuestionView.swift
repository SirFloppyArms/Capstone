import SwiftUI
import Foundation
import Combine
import FirebaseFirestore
import FirebaseAuth
import Network

struct DailyQuestion: Identifiable, Codable {
    let id: UUID
    let text: String
    let choices: [String]
    let correctAnswer: String
    let imageName: String?

    init(id: UUID = UUID(), text: String, choices: [String], correctAnswer: String, imageName: String? = nil) {
        self.id = id
        self.text = text
        self.choices = choices
        self.correctAnswer = correctAnswer
        self.imageName = imageName
    }

    init?(from dictionary: [String: Any]) {
        guard
            let text = dictionary["text"] as? String,
            let choices = dictionary["choices"] as? [String],
            let correctAnswer = dictionary["correctAnswer"] as? String
        else {
            return nil
        }

        let imageName = dictionary["imageName"] as? String
        self.init(text: text, choices: choices, correctAnswer: correctAnswer, imageName: imageName)
    }

    func toDictionary() -> [String: Any] {
        var dict: [String: Any] = [
            "text": text,
            "choices": choices,
            "correctAnswer": correctAnswer
        ]

        if let imageName = imageName {
            dict["imageName"] = imageName
        }

        return dict
    }
}

enum DailyQuestionError: LocalizedError {
    case offline
    case notFound
    case alreadyAnswered
    case invalidFormat
    case unknown

    var errorDescription: String? {
        switch self {
        case .offline:
            return "You must be online to load the Daily Question."
        case .notFound:
            return "No Daily Question available today."
        case .alreadyAnswered:
            return "You've already answered today's question."
        case .invalidFormat:
            return "The question data is invalid or incomplete."
        case .unknown:
            return "An unknown error occurred."
        }
    }
}

@MainActor
class DailyQuestionViewModel: ObservableObject {
    @Published var question: DailyQuestion?
    @Published var selectedAnswer: String?
    @Published var isCorrect: Bool?
    @Published var isLoading = false
    @Published var error: DailyQuestionError?
    @Published var hasSubmitted = false
    @Published var alreadyAnswered = false

    private let db = Firestore.firestore()
    private var cancellables = Set<AnyCancellable>()
    
    var canSubmit: Bool {
        selectedAnswer != nil && !hasSubmitted
    }

    func load() async {
        isLoading = true
        defer { isLoading = false }

        guard let userID = Auth.auth().currentUser?.uid else {
            self.error = .unknown
            return
        }

        let todayKey = Self.todayDateKey()

        do {
            let userDoc = try await db.collection("users").document(userID).getDocument()
            let lastAnswerDate = userDoc.data()?["lastDailyAnswerDate"] as? String
            if lastAnswerDate == todayKey {
                self.hasSubmitted = true
                self.alreadyAnswered = true
                return
            }

            // Load question from manager
            let fetchedQuestion = try await DailyQuestionManager.shared.fetchTodaysQuestion()
            self.question = fetchedQuestion
            self.error = nil
        } catch let error as DailyQuestionError {
            self.error = error
        } catch {
            self.error = .unknown
        }
    }

    func submitAnswer() {
        guard let selected = selectedAnswer,
              let question = question,
              let userID = Auth.auth().currentUser?.uid else { return }

        self.hasSubmitted = true
        self.isCorrect = (selected == question.correctAnswer)

        let todayKey = Self.todayDateKey()
        let userRef = db.collection("users").document(userID)

        Task {
            do {
                let doc = try await userRef.getDocument()
                let alreadyMarked = (doc.data()?["lastDailyAnswerDate"] as? String) == todayKey

                if !alreadyMarked {
                    var data: [String: Any] = [
                        "lastDailyAnswerDate": todayKey
                    ]
                    if isCorrect == true {
                        data["dailyScore"] = FieldValue.increment(Int64(2))
                    }

                    try await userRef.setData(data, merge: true)
                }
            } catch {
                print("⚠️ Failed to update user progress: \(error.localizedDescription)")
            }
        }
    }

    private static func todayDateKey() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: Date())
    }
}

struct DailyQuestionView: View {
    @StateObject private var viewModel = DailyQuestionViewModel()
    @State private var timeRemaining: TimeInterval = 0
    @State private var timer: Timer?

    var body: some View {
        VStack(spacing: 24) {
            if viewModel.isLoading {
                ProgressView("Loading...")
            } else if let error = viewModel.error {
                errorView(for: error)
            } else if let question = viewModel.question {
                questionView(for: question)
            } else if viewModel.alreadyAnswered {
                alreadyAnsweredView
            } else {
                noQuestionView
            }
        }
        .padding()
        .onAppear {
            Task { await viewModel.load() }
            startMidnightCountdown()
        }
        .onDisappear {
            timer?.invalidate()
        }
        .background(Color(.systemGroupedBackground).ignoresSafeArea())
    }

    @ViewBuilder
    private func questionView(for question: DailyQuestion) -> some View {
        VStack(spacing: 16) {
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
                    if !viewModel.hasSubmitted {
                        viewModel.selectedAnswer = choice
                    }
                }) {
                    Text(choice)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(buttonColor(for: choice))
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                .disabled(viewModel.hasSubmitted)
            }

            if viewModel.canSubmit {
                Button("Submit Answer") {
                    viewModel.submitAnswer()
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.green)
                .foregroundColor(.white)
                .cornerRadius(12)
            }

            if viewModel.hasSubmitted {
                Text(viewModel.isCorrect == true ? "Correct ✅" : "Incorrect ❌")
                    .font(.headline)
                    .foregroundColor(viewModel.isCorrect == true ? .green : .red)
                    .padding(.top)
            }
        }
    }

    private func buttonColor(for choice: String) -> Color {
        guard viewModel.hasSubmitted else {
            return viewModel.selectedAnswer == choice ? Color.blue : Color.blue.opacity(0.5)
        }

        if choice == viewModel.question?.correctAnswer {
            return .green
        } else if choice == viewModel.selectedAnswer {
            return .red
        } else {
            return .gray.opacity(0.4)
        }
    }

    private func errorView(for error: DailyQuestionError) -> some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 64))
                .foregroundColor(.red)

            Text(error.localizedDescription)
                .multilineTextAlignment(.center)

            Button("Retry") {
                Task { await viewModel.load() }
            }
            .padding()
            .background(Color.blue)
            .foregroundColor(.white)
            .cornerRadius(10)
        }
    }

    private var alreadyAnsweredView: some View {
        VStack(spacing: 12) {
            Image(systemName: "checkmark.seal.fill")
                .font(.system(size: 64))
                .foregroundColor(.green)

            Text("You already answered today's question!")
                .font(.title3.bold())

            Text("Next question unlocks in")
            Text(formatTime(timeRemaining))
                .font(.system(.title, design: .monospaced))
                .foregroundColor(.blue)
        }
    }

    private var noQuestionView: some View {
        VStack(spacing: 16) {
            Image(systemName: "questionmark.circle")
                .font(.system(size: 64))
                .foregroundColor(.blue)

            Text("No Daily Question Available")
                .font(.title2.bold())

            Text("Next question unlocks in")
            Text(formatTime(timeRemaining))
                .font(.system(.title, design: .monospaced))
                .foregroundColor(.green)
        }
    }

    private func startMidnightCountdown() {
        updateMidnightTime()
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            updateMidnightTime()
        }
    }

    private func updateMidnightTime() {
        let now = Date()
        let calendar = Calendar.current
        if let midnight = calendar.nextDate(after: now, matching: DateComponents(hour: 0, minute: 0, second: 0), matchingPolicy: .strict, direction: .forward) {
            timeRemaining = midnight.timeIntervalSince(now)
        } else {
            timeRemaining = 0
        }
    }

    private func formatTime(_ interval: TimeInterval) -> String {
        let hours = Int(interval) / 3600
        let minutes = (Int(interval) % 3600) / 60
        let seconds = Int(interval) % 60
        return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
    }
}

actor DailyQuestionManager {
    static let shared = DailyQuestionManager()
    private let db = Firestore.firestore()
    private let monitor = NWPathMonitor()
    private var isConnected: Bool = true

    private init() {
        monitor.pathUpdateHandler = { [weak self] path in
            guard let self = self else { return }
            Task {
                await self.setConnectionStatus(path.status == .satisfied)
            }
        }
        monitor.start(queue: DispatchQueue(label: "NetworkMonitor"))
    }

    private func setConnectionStatus(_ status: Bool) {
        self.isConnected = status
    }

    func fetchTodaysQuestion() async throws -> DailyQuestion {
        guard isConnected else {
            throw DailyQuestionError.offline
        }

        let todayKey = Self.todayDateKey()
        let docRef = db.collection("dailyQuestions").document(todayKey)
        let snapshot = try await docRef.getDocument()

        if snapshot.exists {
            // ✅ Try to parse the existing question
            if let data = snapshot.data()?["question"] as? [String: Any],
               let question = DailyQuestion(from: data) {
                return question
            } else {
                throw DailyQuestionError.invalidFormat
            }
        } else {
            // ❌ Not found in Firebase — use local file and upload it
            guard let fallback = loadRandomQuestionFromFile() else {
                throw DailyQuestionError.notFound
            }

            try await docRef.setData([
                "question": fallback.toDictionary()
            ])
            return fallback
        }
    }

    private func loadRandomQuestionFromFile() -> DailyQuestion? {
        guard let url = Bundle.main.url(forResource: "questions", withExtension: "txt"),
              let content = try? String(contentsOf: url) else {
            print("❌ Failed to load questions.txt")
            return nil
        }

        let lines = content.components(separatedBy: .newlines).filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }

        var questions: [DailyQuestion] = []

        for line in lines {
            let parts = line.components(separatedBy: ";").map { $0.trimmingCharacters(in: .whitespaces) }

            guard parts.count >= 6 else {
                print("⚠️ Skipping malformed line: \(line)")
                continue
            }

            let text = parts[0]
            let choices = Array(parts[1...4])
            let correctAnswer = parts[5]
            let imageName = parts.count >= 7 && !parts[6].isEmpty ? parts[6] : nil

            let question = DailyQuestion(text: text, choices: choices, correctAnswer: correctAnswer, imageName: imageName)
            questions.append(question)
        }

        guard let random = questions.randomElement() else {
            print("❌ No valid questions found in file.")
            return nil
        }

        return random
    }

    private static func todayDateKey() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: Date())
    }
}
