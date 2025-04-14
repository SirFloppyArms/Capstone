import SwiftUI

struct TimeTrialQuizView: View {
    let stage: Int
    let totalQuestions: Int = 10
    var onComplete: (() -> Void)? = nil

    @Environment(\.dismiss) private var dismiss

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
            LinearGradient(gradient: Gradient(colors: [.orange.opacity(0.2), .red.opacity(0.2)]),
                           startPoint: .topLeading,
                           endPoint: .bottomTrailing)
                .ignoresSafeArea()

            VStack(spacing: 20) {
                if sessionComplete {
                    sessionCompleteView
                } else if questions.isEmpty {
                    Text("No questions found!")
                        .foregroundColor(.white)
                } else {
                    quizQuestionView
                }
            }
            .padding()
            .onAppear {
                loadQuestions()
            }
        }
        .interactiveDismissDisabled(true)
        .navigationBarBackButtonHidden(true)
        .onDisappear {
            timer?.invalidate()
        }
    }

    private var sessionCompleteView: some View {
        VStack(spacing: 20) {
            Text("Time Trial Complete!")
                .font(.largeTitle.bold())
                .foregroundColor(.white)

            Text("Score: \(score)/\(totalQuestions)")
                .font(.title2)
                .foregroundColor(score >= 7 ? .green : .red)

            Button("Return") {
                onComplete?()
                dismiss()
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
            Text("Time Trial \(stage) — Q\(currentQuestionIndex + 1)/\(totalQuestions)")
                .font(.headline)
                .foregroundColor(.black)

            Text("Time Remaining: \(timeRemaining)s")
                .font(.subheadline)
                .foregroundColor(timeRemaining <= 5 ? .red : .black)

            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.3))
                .overlay(
                    VStack(spacing: 12) {
                        Text(question.text)
                            .font(.title2)
                            .multilineTextAlignment(.center)
                            .foregroundColor(.black)
                            .padding(.horizontal)

                        if let imageName = question.imageName, !imageName.isEmpty {
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
                        timer?.invalidate()
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

            if selectedAnswer != nil || timeRemaining <= 0 {
                Text(isCorrect == true ? "Correct" : "Incorrect")
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
                .background(Color.orange)
                .foregroundColor(.white)
                .cornerRadius(12)
            }
        }
        .onAppear {
            startTimer()
        }
    }

    private func getButtonColor(for choice: String) -> Color {
        guard let selectedAnswer = selectedAnswer else {
            return Color.blue
        }

        if choice == selectedAnswer {
            return choice == questions[currentQuestionIndex].correctAnswer ? .green : .red
        }

        if choice == questions[currentQuestionIndex].correctAnswer {
            return .green
        }

        return Color.blue.opacity(0.6)
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
}
