import SwiftUI

struct Question {
    let text: String
    let choices: [String]
    let correctAnswer: String
    let explanation: String
}

struct QuizView: View {
    @Binding var unlockedStages: Int
    @Environment(\.presentationMode) var presentationMode
    @State private var questions: [Question] = []
    @State private var currentQuestionIndex: Int = 0
    @State private var selectedAnswer: String? = nil
    @State private var isCorrect: Bool? = nil
    @State private var score: Int = 0
    @State private var sessionComplete: Bool = false
    
    let stage: Int
    let totalQuestions: Int
    
    init(stage: Int, totalQuestions: Int, unlockedStages: Binding<Int>) {
        self.stage = stage
        self.totalQuestions = totalQuestions
        self._unlockedStages = unlockedStages
        self._questions = State(initialValue: QuizView.loadQuestions(for: stage).shuffled().prefix(totalQuestions).map { $0 })
    }

    var body: some View {
        ZStack {
            LinearGradient(
                gradient: Gradient(colors: [Color.teal.opacity(0.3), Color.blue.opacity(0.3)]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 20) {
                if sessionComplete {
                    VStack(spacing: 16) {
                        Text("Session Complete!")
                            .font(.largeTitle.bold())
                            .foregroundColor(.white)

                        Text("Score: \(score)/\(totalQuestions)")
                            .font(.title2)
                            .foregroundColor(.white)

                        Button("Return to Roadmap") {
                            unlockedStages = max(unlockedStages, stage + 1)
                            UserDefaults.standard.set(unlockedStages, forKey: "unlockedStages")
                            presentationMode.wrappedValue.dismiss()
                        }
                        .padding()
                        .background(Color.orange)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                    }
                } else if !questions.isEmpty {
                    VStack(spacing: 12) {
                        Text("Stage \(stage)")
                            .font(.title.bold())
                            .foregroundColor(.black)

                        Text("Question \(currentQuestionIndex + 1) of \(totalQuestions)")
                            .font(.subheadline)
                            .foregroundColor(.black)

                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color.white.opacity(0.2))
                            .overlay(
                                Text(questions[currentQuestionIndex].text)
                                    .font(.title2)
                                    .padding()
                                    .foregroundColor(.black)
                                    .multilineTextAlignment(.center)
                            )
                            .padding(.horizontal)

                        ForEach(questions[currentQuestionIndex].choices, id: \.self) { choice in
                            Button(action: {
                                if selectedAnswer == nil {
                                    selectedAnswer = choice
                                    checkAnswer()
                                }
                            }) {
                                Text(choice)
                                    .padding()
                                    .frame(maxWidth: .infinity)
                                    .background(getButtonColor(for: choice))
                                    .foregroundColor(.white)
                                    .cornerRadius(10)
                            }
                            .disabled(selectedAnswer != nil)
                            .padding(.horizontal)
                        }

                        if selectedAnswer != nil {
                            Text(questions[currentQuestionIndex].explanation)
                                .font(.body)
                                .foregroundColor(.black.opacity(0.9))
                                .padding()

                            Button("Next Question") {
                                nextQuestion()
                            }
                            .padding()
                            .background(Color.orange)
                            .foregroundColor(.white)
                            .cornerRadius(12)
                        }
                    }
                    .padding()
                } else {
                    Text("No questions found!")
                        .foregroundColor(.white)
                }
            }
        }
        .navigationBarBackButtonHidden(true) // Hides default back button
    }

    // Loads quiz questions from .txt files dynamically
    static func loadQuestions(for stage: Int) -> [Question] {
        guard let path = Bundle.main.path(forResource: "questions_stage\(stage)", ofType: "txt") else {
            print("Questions file not found for stage \(stage)!")
            return []
        }

        do {
            let content = try String(contentsOfFile: path)
            let lines = content.components(separatedBy: "\n")

            return lines.compactMap { line in
                let parts = line.components(separatedBy: ";")
                if parts.count >= 5 {
                    let text = parts[0]
                    let choices = Array(parts[1...parts.count - 3])
                    let correctAnswer = parts[parts.count - 2]
                    let explanation = parts[parts.count - 1]
                    return Question(text: text, choices: choices, correctAnswer: correctAnswer, explanation: explanation)
                }
                return nil
            }
        } catch {
            print("Error reading file: \(error)")
            return []
        }
    }

    func checkAnswer() {
        if let selectedAnswer = selectedAnswer {
            isCorrect = (selectedAnswer == questions[currentQuestionIndex].correctAnswer)
            if isCorrect == true {
                score += 1
            }
        }
    }

    func getButtonColor(for choice: String) -> Color {
        if selectedAnswer == nil { return Color.cyan }
        if choice == selectedAnswer {
            return isCorrect == true ? Color.green : Color.red
        }
        return Color.cyan.opacity(0.6)
    }

    func nextQuestion() {
        if currentQuestionIndex < questions.count - 1 {
            currentQuestionIndex += 1
            selectedAnswer = nil
            isCorrect = nil
        } else {
            sessionComplete = true
        }
    }
}
