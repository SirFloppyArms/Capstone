import SwiftUI

struct RoadmapStageNode: View {
    let stage: Int
    let score: Int?
    let unlocked: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: {
            if unlocked {
                withAnimation(.easeInOut) {
                    onTap()
                }
            }
        }) {
            VStack(spacing: 8) {
                ZStack {
                    RoundedRectangle(cornerRadius: 20)
                        .fill(backgroundColor)
                        .frame(width: 80, height: 100)
                        .shadow(color: .black.opacity(0.3), radius: 6, x: 0, y: 4)

                    VStack(spacing: 6) {
                        Text("S\(stage)")
                            .font(.headline)
                            .foregroundColor(.white)

                        if let score = score {
                            Text("\(score)/20")
                                .font(.subheadline)
                                .foregroundColor(.white)
                            Image(systemName: score >= 18 ? "checkmark.circle.fill" : "xmark.circle.fill")
                                .foregroundColor(.white)
                        } else if !unlocked {
                            Image(systemName: "lock.fill")
                                .foregroundColor(.white.opacity(0.7))
                        }
                    }
                }
            }
        }
        .disabled(!unlocked)
    }

    private var backgroundColor: Color {
        if let score = score {
            return score >= 18 ? Color.green : Color.red
        } else if unlocked {
            return Color.accentColor
        } else {
            return Color.gray.opacity(0.5)
        }
    }
}
