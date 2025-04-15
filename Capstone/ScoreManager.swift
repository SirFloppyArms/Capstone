import Foundation

struct ScoreManager {
    static let totalRoadmapQuestions = 15 * 20 // 300
    static let totalTimeTrialQuestions = 30 * 10 // 300
    static let totalPossibleScore = totalRoadmapQuestions + totalTimeTrialQuestions // 600

    static func getTotalScore() -> Int {
        let roadmapScores = UserDefaults.standard.dictionary(forKey: "stageScores") as? [String: Int] ?? [:]
        let timeTrialScores = UserDefaults.standard.dictionary(forKey: "timeTrialScores") as? [String: Int] ?? [:]

        let roadmapTotal = roadmapScores.reduce(0) { $0 + $1.value }
        let timeTrialTotal = timeTrialScores.reduce(0) { $0 + $1.value }

        return roadmapTotal + timeTrialTotal
    }

    static func getScoreBreakdown() -> (roadmap: Int, timeTrials: Int, total: Int) {
        let roadmapScores = UserDefaults.standard.dictionary(forKey: "stageScores") as? [String: Int] ?? [:]
        let timeTrialScores = UserDefaults.standard.dictionary(forKey: "timeTrialScores") as? [String: Int] ?? [:]

        let roadmapTotal = roadmapScores.reduce(0) { $0 + $1.value }
        let timeTrialTotal = timeTrialScores.reduce(0) { $0 + $1.value }

        return (roadmapTotal, timeTrialTotal, roadmapTotal + timeTrialTotal)
    }

    static func getPercentageScore() -> Double {
        let score = getTotalScore()
        return (Double(score) / Double(totalPossibleScore)) * 100.0
    }
}
