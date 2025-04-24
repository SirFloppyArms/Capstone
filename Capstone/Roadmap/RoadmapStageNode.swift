import SwiftUI

struct RoadmapStageNode: View {
    let stage: Int
    let score: Int?
    let unlocked: Bool
    let onTap: () -> Void

    var statusColor: Color {
        if let score = score {
            return score >= 18 ? .green : .red // Green for passed, red for failed
        } else if unlocked {
            return .blue // Current
        } else {
            return .gray // Locked
        }
    }

    var body: some View {
        Button(action: {
            if unlocked {
                onTap()
            }
        }) {
            ZStack {
                RoundedRectangle(cornerRadius: 16)
                    .fill(statusColor)
                    .frame(width: 75, height: 100)
                    .shadow(color: .black.opacity(0.3), radius: 8, x: 0, y: 4)

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
                            .foregroundColor(.white.opacity(0.8))
                    }
                }
            }
        }
        .disabled(!unlocked)
    }
}
