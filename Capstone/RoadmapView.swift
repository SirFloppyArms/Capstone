import SwiftUI

// This struct enables .sheet(item:) to work properly
struct QuizStage: Identifiable {
    let id: Int
}

struct RoadmapView: View {
    let totalStages = 10

    // Store the highest unlocked stage from UserDefaults or default to 1
    @State private var unlockedStages: Int = UserDefaults.standard.integer(forKey: "unlockedStages") > 0
        ? UserDefaults.standard.integer(forKey: "unlockedStages")
        : 1

    @State private var quizStage: QuizStage? = nil
    @State private var refreshTrigger = UUID() // Forces the view to reload

    var body: some View {
        NavigationView {
            GeometryReader { geo in
                let segmentSpacing: CGFloat = 20
                let horizontalOffset: CGFloat = 60
                let pathPoints = RoadPath.generatePathPoints(segments: 150, height: geo.size.height * 0.7)
                let nodeIndexes = stride(from: 0, to: pathPoints.count, by: pathPoints.count / totalStages).map { $0 }

                ScrollView(.horizontal, showsIndicators: false) {
                    ZStack {
                        LinearGradient(
                            gradient: Gradient(colors: [Color.blue.opacity(0.3), Color.cyan.opacity(0.2)]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                        .ignoresSafeArea()

                        RoadPath(points: pathPoints.map { CGPoint(x: $0.x + horizontalOffset, y: $0.y) })
                            .frame(width: CGFloat(pathPoints.count) * segmentSpacing + horizontalOffset, height: geo.size.height)

                        ForEach(0..<totalStages, id: \.self) { index in
                            let stage = index + 1
                            let pointIndex = nodeIndexes[index]
                            let point = pathPoints[pointIndex]
                            let shiftedPoint = CGPoint(x: point.x + horizontalOffset, y: point.y)

                            RoadmapStageNode(
                                stage: stage,
                                score: getScore(for: stage),
                                unlocked: isStageUnlocked(stage),
                                onTap: {
                                    quizStage = QuizStage(id: stage)
                                }
                            )
                            .position(x: shiftedPoint.x, y: shiftedPoint.y)
                        }
                    }
                    .frame(width: CGFloat(pathPoints.count) * segmentSpacing + horizontalOffset, height: geo.size.height)
                }
                .id(refreshTrigger)
            }
            .navigationTitle("🚗 Roadmap")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(item: $quizStage, onDismiss: {
                unlockedStages = UserDefaults.standard.integer(forKey: "unlockedStages")
                refreshTrigger = UUID()
            }) { stage in
                QuizView(
                    stage: stage.id,
                    totalQuestions: 20,
                    unlockedStages: $unlockedStages
                )
            }
        }
    }

    // Pulls score from UserDefaults
    func getScore(for stage: Int) -> Int? {
        let allScores = UserDefaults.standard.dictionary(forKey: "stageScores") as? [String: Int] ?? [:]
        return allScores["stage\(stage)"]
    }

    func isStageUnlocked(_ stage: Int) -> Bool {
        return stage <= unlockedStages
    }
}
