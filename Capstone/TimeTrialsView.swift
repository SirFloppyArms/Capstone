import SwiftUI

struct TimeTrialsView: View {
    @State private var unlockedTimeTrialStages = UserDefaults.standard.integer(forKey: "unlockedTimeTrialStages")
    @State private var timeTrialScores: [String: Int] = UserDefaults.standard.dictionary(forKey: "timeTrialScores") as? [String: Int] ?? [:]

    let totalStages = 30

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                Text("Time Trials")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .padding(.top)

                ForEach(1...totalStages, id: \.self) { stage in
                    let isUnlocked = stage == 1 || (timeTrialScores["timeTrialStage\(stage - 1)"] ?? 0) > 0
                    let score = timeTrialScores["timeTrialStage\(stage)"]

                    NavigationLink(destination: TimeTrialQuizView(stage: stage, onComplete: {
                        loadScores()
                    })) {
                        HStack {
                            Text("Stage \(stage)")
                                .font(.headline)
                                .foregroundColor(.white)

                            Spacer()

                            if let score = score {
                                Text("Score: \(score)/10")
                                    .foregroundColor(score >= 8 ? .green : .red)
                            } else {
                                Text(isUnlocked ? "Ready" : "Locked")
                                    .foregroundColor(isUnlocked ? .blue : .gray)
                            }
                        }
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(isUnlocked ? Color.blue : Color.gray.opacity(0.5))
                        )
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
