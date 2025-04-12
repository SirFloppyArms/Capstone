import SwiftUI

struct RoadmapView: View {
    let totalStages = 10
    @State private var unlockedStages: Int = UserDefaults.standard.integer(forKey: "unlockedStages") > 0 ?
        UserDefaults.standard.integer(forKey: "unlockedStages") : 1

    var body: some View {
        NavigationView {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 30) {
                    ForEach(1...totalStages, id: \.self) { stage in
                        HStack(spacing: 0) {
                            RoadmapStageNode(
                                stage: stage,
                                isUnlocked: stage <= unlockedStages,
                                destination: QuizView(stage: stage, totalQuestions: 20, unlockedStages: $unlockedStages)
                            )

                            // Draw connector to next stage (except after last stage)
                            if stage != totalStages {
                                Image(systemName: "arrow.right")
                                    .font(.title2)
                                    .foregroundColor(.gray)
                                    .padding(.horizontal, 10)
                            }
                        }
                    }
                }
                .padding(.horizontal)
                .frame(height: 160)
            }
            .navigationTitle("🚗 Roadmap")
        }
    }
}
