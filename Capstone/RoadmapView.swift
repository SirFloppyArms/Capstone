import SwiftUI

struct RoadmapView: View {
    let totalStages = 10
    @State private var unlockedStages: Int = UserDefaults.standard.integer(forKey: "unlockedStages") > 0 ?
        UserDefaults.standard.integer(forKey: "unlockedStages") : 1

    var body: some View {
        NavigationView {
            GeometryReader { geo in
                let segmentSpacing: CGFloat = 20
                let horizontalOffset: CGFloat = 60 // Move this ABOVE where it's used
                let pathPoints = RoadPath.generatePathPoints(segments: 150, height: geo.size.height * 0.7)
                let nodeIndexes = stride(from: 0, to: pathPoints.count, by: pathPoints.count / totalStages).map { $0 }

                ScrollView(.horizontal, showsIndicators: false) {
                    ZStack {
                        // Background gradient sky
                        LinearGradient(
                            gradient: Gradient(colors: [Color.blue.opacity(0.3), Color.cyan.opacity(0.2)]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                        .ignoresSafeArea()

                        // Road path shifted right
                        RoadPath(points: pathPoints.map { CGPoint(x: $0.x + horizontalOffset, y: $0.y) })
                            .frame(width: CGFloat(pathPoints.count) * segmentSpacing + horizontalOffset, height: geo.size.height)

                        // Stage nodes
                        ForEach(0..<totalStages) { index in
                            let pointIndex = nodeIndexes[index]
                            let point = pathPoints[pointIndex]
                            let shiftedPoint = CGPoint(x: point.x + horizontalOffset, y: point.y)

                            RoadmapStageNode(
                                stage: index + 1,
                                isUnlocked: index + 1 <= unlockedStages,
                                destination: QuizView(stage: index + 1, totalQuestions: 20, unlockedStages: $unlockedStages)
                            )
                            .position(x: shiftedPoint.x, y: shiftedPoint.y)
                        }
                    }
                    .frame(width: CGFloat(pathPoints.count) * segmentSpacing + horizontalOffset, height: geo.size.height)
                }
            }
            .navigationTitle("🚗 Roadmap")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}
