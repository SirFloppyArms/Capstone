import SwiftUI
import FirebaseFirestore
import FirebaseAuth

struct FreestyleView: View {
    @State private var allQuestions: [Question] = []
    @State private var currentQuestion: Question?
    @State private var selectedAnswer: String?
    @State private var isCorrect: Bool?
    @State private var freestyleScore = 0

    private let db = Firestore.firestore()

    var body: some View {
        VStack(spacing: 20) {
            if let question = currentQuestion {
                if let imageName = question.imageName, !imageName.isEmpty {
                    Image(imageName)
                        .resizable()
                        .scaledToFit()
                        .frame(height: 150)
                }
                
                Text(question.text)
                    .font(.title2)
                    .multilineTextAlignment(.center)
                
                ForEach(question.choices, id: \.self) { choice in
                    Button(action: {
                        if isCorrect == nil {
                            selectedAnswer = choice
                            checkAnswer()
                        }
                    }) {
                        Text(choice)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(buttonBackground(for: choice))
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }
                    .disabled(isCorrect != nil)
                }
                
                if isCorrect != nil {
                    Button("Next Question") {
                        loadNextQuestion()
                    }
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                }
                
                Text("Score: \(freestyleScore)")
                    .font(.headline)
                    .padding(.top, 20)
            } else {
                Text("Loading questions...")
            }
        }
        .padding()
        .onAppear {
            loadQuestionsFromFile()
            loadUserScore()
        }
    }

    private func loadQuestionsFromFile() {
        if let path = Bundle.main.path(forResource: "questions", ofType: "txt") {
            do {
                let data = try String(contentsOfFile: path)
                let lines = data.components(separatedBy: .newlines)
                self.allQuestions = lines.compactMap { line in
                    let parts = line.components(separatedBy: ";")
                    if parts.count >= 6 {
                        let question = parts[0]
                        let choices = Array(parts[1...4])
                        let answer = parts[5]
                        let image = parts.count > 6 ? parts[6] : nil
                        return Question(text: question, choices: choices, correctAnswer: answer, imageName: image)
                    }
                    return nil
                }
                self.loadNextQuestion()
            } catch {
                print("Error reading questions file:", error.localizedDescription)
            }
        }
    }

    private func loadNextQuestion() {
        selectedAnswer = nil
        isCorrect = nil
        if !allQuestions.isEmpty {
            currentQuestion = allQuestions.randomElement()
        }
    }

    private func checkAnswer() {
        guard let selected = selectedAnswer, let correct = currentQuestion?.correctAnswer else { return }
        isCorrect = (selected == correct)
        if isCorrect == true {
            freestyleScore += 1
        } else {
            freestyleScore -= 1
        }
        saveScore()
    }

    private func saveScore() {
        guard let userID = Auth.auth().currentUser?.uid else { return }
        db.collection("users").document(userID).setData([
            "freestyleScore": freestyleScore
        ], merge: true)
    }

    private func loadUserScore() {
        guard let userID = Auth.auth().currentUser?.uid else { return }
        db.collection("users").document(userID).getDocument { snapshot, error in
            if let data = snapshot?.data(), let savedScore = data["freestyleScore"] as? Int {
                self.freestyleScore = savedScore
            }
        }
    }

    private func buttonBackground(for choice: String) -> Color {
        if let selected = selectedAnswer {
            if choice == currentQuestion?.correctAnswer {
                return Color.green // Always highlight the correct answer
            } else if choice == selected {
                return Color.red // Highlight the wrong selected choice
            } else {
                return Color.gray // Others stay gray
            }
        } else {
            return Color.blue // No selection yet
        }
    }
}
