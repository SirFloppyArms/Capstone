import SwiftUI

struct RoadPath: View {
    let points: [CGPoint]

    var body: some View {
        Canvas { context, size in
            var path = Path()
            guard let first = points.first else { return }
            path.move(to: first)
            for point in points.dropFirst() {
                path.addLine(to: point)
            }

            context.stroke(
                path,
                with: .linearGradient(
                    Gradient(colors: [Color.gray, Color.black]),
                    startPoint: .init(x: 0, y: 0),
                    endPoint: .init(x: size.width, y: 0)
                ),
                style: StrokeStyle(lineWidth: 40, lineCap: .round, lineJoin: .round)
            )

            context.stroke(
                path,
                with: .color(.yellow),
                style: StrokeStyle(lineWidth: 4, dash: [20, 20])
            )
        }
    }

    static func generatePathPoints(
        segments: Int = 1000, // longer road
        spacing: CGFloat = 20, // tighter spacing, more detail
        amplitude: CGFloat = 100, // more dramatic curves
        seed: CGFloat = 42,
        height: CGFloat = 250
    ) -> [CGPoint] {
        let midY = height / 2
        return (0...segments).map { i in
            let x = CGFloat(i) * spacing
            let y = midY + noise(x: CGFloat(i) * 0.5 + seed) * amplitude
            return CGPoint(x: x, y: y)
        }
    }

    private static func noise(x: CGFloat) -> CGFloat {
        return (sin(x * 0.7) + cos(x * 0.4) + sin(x * 0.2)) / 2.5
    }
}
