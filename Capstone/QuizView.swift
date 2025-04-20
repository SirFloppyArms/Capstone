import SwiftUI

struct Question: Identifiable {
    let id = UUID()
    let text: String
    let choices: [String]
    let correctAnswer: String
    let imageName: String?
}

struct QuizView: View {
    let stage: Int
    let totalQuestions: Int
    var onQuizComplete: (() -> Void)? = nil

    @Environment(\.dismiss) private var dismiss

    @State private var questions: [Question] = []
    @State private var currentQuestionIndex = 0
    @State private var selectedAnswer: String? = nil
    @State private var isCorrect: Bool? = nil
    @State private var score = 0
    @State private var sessionComplete = false

    init(stage: Int, totalQuestions: Int, onQuizComplete: (() -> Void)? = nil) {
        self.stage = stage
        self.totalQuestions = totalQuestions
        self.onQuizComplete = onQuizComplete
        let loaded = QuizView.loadQuestions(for: stage).shuffled()
        self._questions = State(initialValue: Array(loaded.prefix(totalQuestions)))
    }

    var body: some View {
        ZStack {
            LinearGradient(
                gradient: Gradient(colors: [.teal.opacity(0.3), .blue.opacity(0.3)]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 20) {
                if sessionComplete {
                    sessionCompleteView
                } else {
                    if questions.isEmpty {
                        Text("No questions found!")
                            .font(.title2)
                            .foregroundColor(.white)
                    } else {
                        quizQuestionView
                    }
                }
            }
            .padding()
        }
        .interactiveDismissDisabled(true)
        .navigationBarBackButtonHidden(true)
    }

    // MARK: - Views

    private var sessionCompleteView: some View {
        VStack(spacing: 20) {
            Text("Session Complete!")
                .font(.largeTitle.bold())
                .foregroundColor(.white)

            Text("Score: \(score)/\(totalQuestions)")
                .font(.title2)
                .foregroundColor(score >= 18 ? .green : .red)

            Button("Return to Roadmap") {
                saveScore()
                if score >= 18 {
                    UserDataManager.shared.updateUnlockedStages(to: stage + 1) { error in
                        if let error = error {
                            print("⚠️ Failed to update unlockedStages: \(error.localizedDescription)")
                        }
                        onQuizComplete?()
                        dismiss()
                    }
                } else {
                    onQuizComplete?()
                    dismiss()
                }
            }
            .padding()
            .background(Color.orange)
            .foregroundColor(.white)
            .cornerRadius(12)
        }
    }

    private var quizQuestionView: some View {
        let question = questions[currentQuestionIndex]

        return VStack(spacing: 16) {
            Text("Stage \(stage) — Question \(currentQuestionIndex + 1)/\(totalQuestions)")
                .font(.headline)
                .foregroundColor(.black)

            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.3))
                .overlay(
                    VStack(spacing: 12) {
                        Text(questions[currentQuestionIndex].text)
                            .font(.title2)
                            .multilineTextAlignment(.center)
                            .foregroundColor(.black)
                            .padding(.horizontal)
                        if let imageName = questions[currentQuestionIndex].imageName, !imageName.isEmpty {
                            Image(imageName)
                                .resizable()
                                .scaledToFit()
                                .frame(maxHeight: 180)
                                .cornerRadius(10)
                        }
                    }
                    .padding()
                )
                .padding(.horizontal)

            ForEach(question.choices, id: \.self) { choice in
                Button {
                    if selectedAnswer == nil {
                        selectedAnswer = choice
                        isCorrect = (choice == question.correctAnswer)
                        if isCorrect == true { score += 1 }
                    }
                } label: {
                    Text(choice)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(getButtonColor(for: choice))
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                .disabled(selectedAnswer != nil)
                .padding(.horizontal)
            }

            if selectedAnswer != nil {
                Text(isCorrect == true ? "Correct" : "Incorrect")
                    .font(.headline)
                    .foregroundColor(isCorrect == true ? .green : .red)
                    .padding(.top, 10)

                Button(currentQuestionIndex < questions.count - 1 ? "Next" : "Finish") {
                    if currentQuestionIndex < questions.count - 1 {
                        currentQuestionIndex += 1
                        selectedAnswer = nil
                        isCorrect = nil
                    } else {
                        sessionComplete = true
                    }
                }
                .padding()
                .background(Color.orange)
                .foregroundColor(.white)
                .cornerRadius(12)
            }
        }
    }

    // MARK: - Helpers

    func getButtonColor(for choice: String) -> Color {
        guard let selected = selectedAnswer else { return .cyan }

        let correct = questions[currentQuestionIndex].correctAnswer

        if choice == correct {
            return .green // Always green for the correct answer
        }

        if choice == selected {
            return .red // User's incorrect selection
        }

        return .cyan.opacity(0.6) // Default for all others
    }

    private func saveScore() {
        UserDataManager.shared.saveRoadmapScore(stage: stage, score: score) { error in
            if let error = error {
                print("⚠️ Failed to save score: \(error.localizedDescription)")
            } else {
                print("✅ Score saved to Firestore")
            }
        }
    }

    // MARK: - Loader

    static func loadQuestions(for stage: Int) -> [Question] {
        guard let path = Bundle.main.path(forResource: "questions_stage\(stage)", ofType: "txt") else {
            print("Questions file not found for stage \(stage)")
            return []
        }

        do {
            let lines = try String(contentsOfFile: path).components(separatedBy: "\n")

            return lines.compactMap { line in
                let parts = line.components(separatedBy: ";")
                guard parts.count >= 5 else { return nil }

                let text = parts[0]
                let choices = Array(parts[1...(parts.count - 3)])
                let correctAnswer = parts[parts.count - 2]
                let imageName = parts.last?.isEmpty == true ? nil : parts.last

                return Question(text: text, choices: choices, correctAnswer: correctAnswer, imageName: imageName)
            }
        } catch {
            print("Error reading file: \(error)")
            return []
        }
    }
}
