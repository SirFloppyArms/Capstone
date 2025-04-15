import SwiftUI

struct TimeTrialsView: View {
    @State private var timeTrialScores: [String: Int] = UserDefaults.standard.dictionary(forKey: "timeTrialScores") as? [String: Int] ?? [:]
    let totalStages = 30

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                Text("Time Trials")
                    .font(.largeTitle)
                    .bold()
                    .padding(.top)

                ForEach(1...totalStages, id: \.self) { stage in
                    let score = timeTrialScores["timeTrialStage\(stage)"]
                    let previousScore = stage == 1 ? 10 : (timeTrialScores["timeTrialStage\(stage - 1)"] ?? 0)
                    let isUnlocked = stage == 1 || previousScore >= 9

                    let backgroundColor: Color = {
                        if let score = score {
                            return score >= 9 ? .green : .red
                        } else {
                            return isUnlocked ? .blue : .gray
                        }
                    }()

                    NavigationLink(
                        destination: TimeTrialQuizView(stage: stage, onComplete: {
                            loadScores()
                        })
                    ) {
                        HStack {
                            Text("Stage \(stage)")
                                .font(.headline)
                                .foregroundColor(.white)

                            Spacer()

                            if let score = score {
                                Text("Score: \(score)/10")
                                    .foregroundColor(.white)
                            } else {
                                Text(isUnlocked ? "Ready" : "Locked")
                                    .foregroundColor(.white)
                            }
                        }
                        .padding()
                        .background(RoundedRectangle(cornerRadius: 12).fill(backgroundColor))
                    }
                    .disabled(!isUnlocked)
                    .padding(.horizontal)
                }

                Spacer()
            }
            .padding()
        }
        .onAppear {
            loadScores()
        }
    }

    private func loadScores() {
        timeTrialScores = UserDefaults.standard.dictionary(forKey: "timeTrialScores") as? [String: Int] ?? [:]
    }
}
