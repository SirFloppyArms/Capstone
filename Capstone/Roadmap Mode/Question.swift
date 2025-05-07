import SwiftUI

struct Question: Identifiable {
    let id = UUID()
    let text: String
    let choices: [String]
    let correctAnswer: String
    let imageName: String?
}
