import SwiftUI

struct QuizStage: Identifiable {
    let id: Int
}

struct RoadmapView: View {
    @ObservedObject private var dataManager = UserDataManager.shared
    @State private var quizStage: QuizStage? = nil
    @State private var refreshTrigger = UUID()

    let totalStages = 15

    var body: some View {
        NavigationView {
            GeometryReader { geo in
                let pathPoints = RoadPath.generatePathPoints(segments: 150, height: geo.size.height * 0.7)
                let nodeIndexes = stride(from: 0, to: pathPoints.count, by: pathPoints.count / totalStages).map { $0 }
                let offsetX: CGFloat = 60
                let contentWidth = (pathPoints.last?.x ?? 0) + offsetX + 100

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
                                score: dataManager.roadmapScores["RoadmapStage\(stage)"],
                                unlocked: stage <= dataManager.unlockedStage
                            ) {
                                quizStage = QuizStage(id: stage)
                            }
                            .position(point)
                        }
                    }
                    .frame(width: contentWidth, height: geo.size.height)
                }
                .id(refreshTrigger)
            }
            .navigationTitle("🚗 Roadmap")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(item: $quizStage, onDismiss: {
                dataManager.loadUserData() // refresh all from shared source
                refreshTrigger = UUID()    // force redraw
            }) { stage in
                QuizView(
                    stage: stage.id,
                    totalQuestions: 20
                ) {
                    dataManager.loadUserData()
                    refreshTrigger = UUID()
                }
            }
        }
    }
}
