import SwiftUI

struct RoadmapStageNode<Destination: View>: View {
    let stage: Int
    let isUnlocked: Bool
    let destination: Destination

    var body: some View {
        VStack(spacing: 10) {
            ZStack {
                Circle()
                    .fill(
                        isUnlocked ?
                            LinearGradient(colors: [Color.cyan, Color.blue], startPoint: .top, endPoint: .bottom) :
                            LinearGradient(colors: [Color.gray.opacity(0.5), Color.gray.opacity(0.3)], startPoint: .top, endPoint: .bottom)
                    )
                    .frame(width: 80, height: 80)
                    .shadow(color: isUnlocked ? .cyan.opacity(0.4) : .black.opacity(0.1), radius: 10, x: 0, y: 5)

                Text("S\(stage)")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
            }

            Text(isUnlocked ? "Unlocked" : "Locked")
                .font(.caption)
                .foregroundColor(isUnlocked ? .green : .red)

            if isUnlocked {
                NavigationLink(destination: destination) {
                    Text("Start")
                        .font(.caption)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
            } else {
                Text("🔒")
                    .font(.title3)
            }
        }
    }
}
