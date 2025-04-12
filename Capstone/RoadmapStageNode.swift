import SwiftUI

struct RoadmapStageNode<Destination: View>: View {
    let stage: Int
    let isUnlocked: Bool
    let destination: Destination

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 25, style: .continuous)
                .fill(isUnlocked ? Color.white : Color.gray.opacity(0.4))
                .frame(width: 120, height: 150)
                .shadow(color: .black.opacity(0.25), radius: 8, x: 0, y: 5)
                .overlay(
                    RoundedRectangle(cornerRadius: 25, style: .continuous)
                        .strokeBorder(isUnlocked ? Color.blue : Color.gray, lineWidth: 2)
                )

            VStack(spacing: 10) {
                Text("Stage \(stage)")
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(isUnlocked ? .black : .gray)

                Image(systemName: isUnlocked ? "checkmark.circle.fill" : "lock.fill")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 35, height: 35)
                    .foregroundColor(isUnlocked ? .green : .red)

                if isUnlocked {
                    NavigationLink(destination: destination) {
                        Text("Start")
                            .font(.caption)
                            .bold()
                            .padding(.horizontal, 20)
                            .padding(.vertical, 8)
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }
                    .buttonStyle(.plain)
                } else {
                    Text("Locked")
                        .font(.caption2)
                        .foregroundColor(.gray)
                }
            }
            .padding(.vertical)
        }
        .frame(width: 130, height: 160)
    }
}
