import SwiftUI

struct TimeTrialQuizView: View {
    let stage: Int
    let totalQuestions: Int = 10
    var onComplete: (() -> Void)? = nil

    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme

    @State private var questions: [Question] = []
    @State private var currentQuestionIndex = 0
    @State private var selectedAnswer: String? = nil
    @State private var isCorrect: Bool? = nil
    @State private var score = 0
    @State private var timer: Timer?
    @State private var timeRemaining = 30
    @State private var sessionComplete = false

    var body: some View {
        ZStack {
            backgroundGradient.ignoresSafeArea()

            VStack {
                if sessionComplete {
                    sessionCompleteView
                } else if questions.isEmpty {
                    Text("No questions found!")
                        .font(.title2)
                        .foregroundColor(.primary)
                } else {
                    quizQuestionView
                }
            }
            .padding()
            .animation(.easeInOut, value: selectedAnswer)
        }
        .interactiveDismissDisabled(true)
        .navigationBarBackButtonHidden(true)
        .onAppear(perform: loadQuestions)
        .onDisappear { timer?.invalidate() }
    }

    private var backgroundGradient: LinearGradient {
        LinearGradient(
            gradient: Gradient(colors: colorScheme == .dark
                               ? [Color(.systemGray6), Color(.systemRed).opacity(0.6)]
                               : [Color(.systemRed).opacity(0.1), Color.white]),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    private var sessionCompleteView: some View {
        VStack(spacing: 20) {
            Text("Time Trial Complete!")
                .font(.largeTitle.bold())
                .foregroundColor(.primary)

            Text("Score: \(score)/\(totalQuestions)")
                .font(.title2)
                .foregroundColor(score >= 7 ? .green : .red)

            Button(action: {
                saveScore()
                onComplete?()
                dismiss()
            }) {
                Text("Return")
                    .bold()
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.accentColor)
                    .foregroundColor(.white)
                    .cornerRadius(14)
            }
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
                Text("Time Trial \(stage) — \(currentQuestionIndex + 1)/\(totalQuestions)")
                    .font(.headline)
                    .foregroundColor(.primary)

                Spacer()

                HStack(spacing: 6) {
                    Image(systemName: "clock.fill")
                        .foregroundColor(timeRemaining <= 5 ? .red : .gray)
                    Text("\(timeRemaining)s")
                        .foregroundColor(timeRemaining <= 5 ? .red : .primary)
                        .bold()
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color.gray.opacity(0.1))
                .cornerRadius(12)
            }
            .padding(.horizontal)

            // Question Card
            VStack(spacing: 16) {
                Text(question.text)
                    .font(.title2.weight(.semibold))
                    .multilineTextAlignment(.center)
                    .foregroundColor(.primary)
                    .padding(.horizontal)
                    .lineLimit(5)
                    .minimumScaleFactor(0.5) // Shrinks text as needed
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: .infinity, alignment: .center)

                if let imageName = question.imageName, !imageName.isEmpty {
                    Image(imageName)
                        .resizable()
                        .scaledToFit()
                        .frame(maxHeight: 180)
                        .cornerRadius(12)
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(colorScheme == .dark ? Color(.secondarySystemBackground) : Color.white)
                    .shadow(color: .black.opacity(0.05), radius: 6, x: 0, y: 2)
            )
            .padding(.horizontal)

            Spacer()

            // Answer Options
            VStack(spacing: 12) {
                ForEach(question.choices, id: \.self) { choice in
                    Button {
                        if selectedAnswer == nil {
                            timer?.invalidate()
                            selectedAnswer = choice
                            isCorrect = (choice == question.correctAnswer)
                            if isCorrect == true { score += 1 }
                        }
                    } label: {
                        Text(choice)
                            .font(.body)
                            .multilineTextAlignment(.center)
                            .lineLimit(3)
                            .minimumScaleFactor(0.6) // Shrinks long answers
                            .fixedSize(horizontal: false, vertical: true)
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding()
                            .background(getButtonColor(for: choice))
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }
                    .disabled(selectedAnswer != nil)
                }

                if selectedAnswer != nil || timeRemaining <= 0 {
                    Text(isCorrect == true ? "Correct ✅" : "Incorrect ❌")
                        .font(.headline)
                        .foregroundColor(isCorrect == true ? .green : .red)
                        .padding(.top, 10)

                    Button(currentQuestionIndex < totalQuestions - 1 ? "Next" : "Finish") {
                        if currentQuestionIndex < totalQuestions - 1 {
                            currentQuestionIndex += 1
                            selectedAnswer = nil
                            isCorrect = nil
                            timeRemaining = 30
                            startTimer()
                        } else {
                            sessionComplete = true
                            timer?.invalidate()
                        }
                    }
                    .padding()
                    .background(Color.accentColor)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                }
            }
            .padding(.horizontal)
        }
        .onAppear {
            startTimer()
        }
    }

    private func getButtonColor(for choice: String) -> Color {
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

    private func startTimer() {
        timer?.invalidate()
        timeRemaining = 30
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            if timeRemaining > 0 {
                timeRemaining -= 1
            } else {
                timer?.invalidate()
                if selectedAnswer == nil {
                    isCorrect = false
                }
            }
        }
    }

    private func loadQuestions() {
        guard let path = Bundle.main.path(forResource: "questions_timeTrial\(stage)", ofType: "txt") else {
            print("⚠️ File not found: questions_timeTrial\(stage).txt")
            return
        }

        do {
            let lines = try String(contentsOfFile: path).components(separatedBy: "\n")

            let loadedQuestions = lines.compactMap { line -> Question? in
                let parts = line.components(separatedBy: ";")
                guard parts.count >= 5 else { return nil }

                let text = parts[0]
                let choices = Array(parts[1...(parts.count - 3)])
                let correctAnswer = parts[parts.count - 2]
                let imageName = parts.last?.isEmpty == true ? nil : parts.last

                return Question(text: text, choices: choices, correctAnswer: correctAnswer, imageName: imageName)
            }

            self.questions = Array(loadedQuestions.prefix(totalQuestions))
        } catch {
            print("⚠️ Failed to read questions: \(error.localizedDescription)")
        }
    }

    private func saveScore() {
        UserDataManager.shared.saveTimeTrialScore(stage: stage, score: score) { error in
            if let error = error {
                print("⚠️ Failed to save score: \(error.localizedDescription)")
            } else {
                print("✅ Score saved to Firestore")
            }
        }
    }
}
