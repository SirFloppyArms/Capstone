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

    @Environment(\.colorScheme) private var colorScheme
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
            backgroundGradient
                .ignoresSafeArea()

            VStack {
                if sessionComplete {
                    sessionCompleteView
                } else {
                    if questions.isEmpty {
                        Text("No questions found!")
                            .font(.title2)
                            .foregroundColor(.primary)
                    } else {
                        quizQuestionView
                    }
                }
            }
            .padding()
            .animation(.easeInOut, value: selectedAnswer)
        }
        .interactiveDismissDisabled(true)
        .navigationBarBackButtonHidden(true)
    }

    // MARK: - Views

    private var backgroundGradient: LinearGradient {
        LinearGradient(
            gradient: Gradient(colors: colorScheme == .dark
                               ? [Color(.systemGray6), Color(.systemIndigo).opacity(0.6)]
                               : [Color(.systemBlue).opacity(0.15), Color.white]),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    private var sessionCompleteView: some View {
        VStack(spacing: 20) {
            Text("Session Complete!")
                .font(.largeTitle.bold())
                .foregroundColor(.primary)

            Text("Score: \(score)/\(totalQuestions)")
                .font(.title2)
                .foregroundColor(score >= 18 ? .green : .red)

            Button(action: handleCompletion) {
                Text("Return to Roadmap")
                    .bold()
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.accentColor)
                    .foregroundColor(.white)
                    .cornerRadius(14)
            }
            .padding(.top)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(colorScheme == .dark ? Color(.secondarySystemBackground) : Color.white)
                .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
        )
    }

    private var quizQuestionView: some View {
        let question = questions[currentQuestionIndex]

        return VStack(spacing: 16) {
            // Header
            HStack {
                Text("Roadmap \(stage) — \(currentQuestionIndex + 1)/\(totalQuestions)")
                    .font(.headline)
                    .foregroundColor(.primary)
                Spacer()
            }
            .frame(maxWidth: .infinity, alignment: .topLeading)
            .padding(.top)
            .padding(.horizontal)

            // Question text and image section
            VStack(spacing: 16) {
                Text(question.text)
                    .font(.title2.weight(.semibold))
                    .multilineTextAlignment(.center)
                    .lineLimit(nil)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .foregroundColor(.primary)
                    .lineLimit(5)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.horizontal)

                if let imageName = question.imageName, !imageName.isEmpty {
                    Image(imageName)
                        .resizable()
                        .scaledToFit()
                        .frame(maxHeight: 180)
                        .cornerRadius(12)
                }
            }
            .transition(.slide)
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(colorScheme == .dark ? Color(.secondarySystemBackground) : Color.white)
                    .shadow(color: .black.opacity(0.05), radius: 6, x: 0, y: 2)
            )
            .padding(.horizontal)

            Spacer()

            // Answer options
            VStack(spacing: 12) {
                ForEach(question.choices, id: \.self) { choice in
                    Button {
                        if selectedAnswer == nil {
                            selectedAnswer = choice
                            isCorrect = (choice == question.correctAnswer)
                            if isCorrect == true { score += 1 }
                        }
                    } label: {
                        Text(choice)
                            .font(.body)
                            .multilineTextAlignment(.center)
                            .lineLimit(nil)
                            .fixedSize(horizontal: false, vertical: true)
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding()
                            .background(getButtonColor(for: choice))
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }
                    .disabled(selectedAnswer != nil)
                }

                if selectedAnswer != nil {
                    Text(isCorrect == true ? "Correct ✅" : "Incorrect ❌")
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
                    .background(Color.accentColor)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                }
            }
            .padding(.horizontal)
            .transition(.slide)
        }
    }

    // MARK: - Helpers

    func getButtonColor(for choice: String) -> Color {
        guard let selected = selectedAnswer else {
            return Color.blue.opacity(colorScheme == .dark ? 0.6 : 0.8)
        }

        let correct = questions[currentQuestionIndex].correctAnswer

        if choice == correct {
            return .green
        } else if choice == selected {
            return .red
        } else {
            return Color.gray.opacity(0.4)
        }
    }

    private func handleCompletion() {
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
