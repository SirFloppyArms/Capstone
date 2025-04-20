import SwiftUI

struct QuizStage: Identifiable {
    let id: Int
}

struct RoadmapView: View {
    @State private var roadmapScores: [String: Int] = [:]
    @State private var unlockedStages = 1
    @State private var quizStage: QuizStage? = nil
    @State private var refreshTrigger = UUID()

    let totalStages = 15

    var body: some View {
        NavigationView {
            GeometryReader { geo in
                let pathPoints = RoadPath.generatePathPoints(segments: 150, height: geo.size.height * 0.7)
                let nodeIndexes = stride(from: 0, to: pathPoints.count, by: pathPoints.count / totalStages).map { $0 }
                let offsetX: CGFloat = 60
                let contentWidth = (pathPoints.last?.x ?? 0) + offsetX + 100 // Add extra padding

                ScrollView(.horizontal, showsIndicators: false) {
                    ZStack {
                        LinearGradient(
                            gradient: Gradient(colors: [Color.blue.opacity(0.3), Color.cyan.opacity(0.2)]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                        .ignoresSafeArea()

                        RoadPath(points: pathPoints.map { CGPoint(x: $0.x + offsetX, y: $0.y) })
                            .frame(width: contentWidth, height: geo.size.height)

                        ForEach(0..<totalStages, id: \.self) { index in
                            let stage = index + 1
                            let point = CGPoint(
                                x: pathPoints[nodeIndexes[index]].x + offsetX,
                                y: pathPoints[nodeIndexes[index]].y
                            )

                            RoadmapStageNode(
                                stage: stage,
                                score: roadmapScores["RoadmapStage\(stage)"],
                                unlocked: stage <= unlockedStages
                            ) {
                                quizStage = QuizStage(id: stage)
                            }
                            .position(point)
                        }
                    }
                    .frame(width: contentWidth, height: geo.size.height)
                }
                .onAppear(perform: loadData)
                .id(refreshTrigger)
            }
            .navigationTitle("🚗 Roadmap")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(item: $quizStage, onDismiss: {
                loadData() // centralize reload logic here
            }) { stage in
                QuizView(
                    stage: stage.id,
                    totalQuestions: 20
                ) {
                    loadData() // called when quiz finishes
                }
            }
        }
    }

    private func loadData() {
        UserDataManager.shared.fetchRoadmapScores { scores, error in
            if let scores = scores {
                roadmapScores = scores
            } else if let error = error {
                print("⚠️ Failed to load scores: \(error.localizedDescription)")
            }
        }

        UserDataManager.shared.fetchUnlockedStages { stage, error in
            if let stage = stage {
                unlockedStages = stage
            } else if let error = error {
                print("⚠️ Failed to load unlocked stages: \(error.localizedDescription)")
            }
        }
    }
}
