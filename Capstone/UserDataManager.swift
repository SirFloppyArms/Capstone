import Foundation
import Firebase
import FirebaseFirestore
import FirebaseAuth
import Network

class UserDataManager: ObservableObject {
    static let shared = UserDataManager()

    @Published var roadmapScores: [String: Int] = [:]
    @Published var timeTrialScores: [String: Int] = [:]
    @Published var unlockedStage: Int = 0
    @Published var dailyModePoints: Int = 0
    @Published var lastDailyAnswerDate: String? = nil
    @Published var freestyleScore: Int = 0

    private let db = Firestore.firestore()
    private let pendingUpdatesKey = "PendingUpdates"
    private var isOnline = false
    private var pendingUpdates: [[String: Any]] = []

    private init() {
        monitorNetwork()
        loadPendingUpdates()
        loadUserDataWithFallback()
    }

    // MARK: - Network Monitoring

    private func monitorNetwork() {
        let monitor = NWPathMonitor()
        monitor.pathUpdateHandler = { path in
            self.isOnline = path.status == .satisfied
            if self.isOnline {
                self.syncPendingUpdates()
                self.loadUserData()
            }
        }
        let queue = DispatchQueue(label: "NetworkMonitor")
        monitor.start(queue: queue)
    }

    // MARK: - Pending Updates (Offline Sync)

    private func savePendingUpdate(_ update: [String: Any]) {
        pendingUpdates.append(update)
        UserDefaults.standard.set(pendingUpdates, forKey: pendingUpdatesKey)
    }

    private func loadPendingUpdates() {
        if let saved = UserDefaults.standard.array(forKey: pendingUpdatesKey) as? [[String: Any]] {
            pendingUpdates = saved
        }
    }

    private func syncPendingUpdates() {
        guard let uid = Auth.auth().currentUser?.uid else { return }

        let updatesToSync = pendingUpdates
        pendingUpdates.removeAll()
        UserDefaults.standard.removeObject(forKey: pendingUpdatesKey)

        for update in updatesToSync {
            db.collection("users").document(uid).setData(update, merge: true) { error in
                if let error = error {
                    print("⚠️ Sync failed, re-saving update: \(error.localizedDescription)")
                    self.savePendingUpdate(update)
                }
            }
        }
    }

    // MARK: - Public Save Methods

    func saveTimeTrialScore(stage: Int, score: Int, completion: @escaping (Error?) -> Void) {
        save(field: "TimeTrialStage\(stage)", value: score, completion: completion)
    }

    func saveRoadmapScore(stage: Int, score: Int, completion: @escaping (Error?) -> Void) {
        save(field: "RoadmapStage\(stage)", value: score, completion: completion)
    }

    func updateUnlockedStages(to stage: Int, completion: @escaping (Error?) -> Void) {
        save(field: "unlockedStages", value: stage, completion: completion)
    }
    
    func saveFreestyleScore(pointsToAdd: Int, completion: @escaping (Error?) -> Void) {
        let newScore = freestyleScore + pointsToAdd
        save(field: "freestyleScore", value: newScore) { error in
            if error == nil {
                DispatchQueue.main.async {
                    self.freestyleScore = newScore
                    UserDefaults.standard.set(newScore, forKey: "freestyleScore")
                }
            }
            completion(error)
        }
    }

    private func save(field: String, value: Any, completion: @escaping (Error?) -> Void) {
        guard let uid = Auth.auth().currentUser?.uid else {
            completion(NSError(domain: "UserNotLoggedIn", code: 401))
            return
        }

        let update = [field: value]

        if isOnline {
            db.collection("users").document(uid).setData(update, merge: true) { error in
                if let error = error {
                    self.savePendingUpdate(update)
                }
                completion(error)
            }
        } else {
            savePendingUpdate(update)
            self.updateLocalCache(with: update) // ✅
            completion(nil)
        }
    }
    
    func saveDailyModeAnswer(correct: Bool, completion: @escaping (Error?) -> Void) {
        guard let uid = Auth.auth().currentUser?.uid else {
            completion(NSError(domain: "UserNotLoggedIn", code: 401))
            return
        }
        
        let today = DateFormatter.localizedString(from: Date(), dateStyle: .short, timeStyle: .none)
        
        var update: [String: Any] = [
            "lastDailyAnswerDate": today
        ]
        
        if correct {
            update["DailyModePoints"] = (self.dailyModePoints + 2)
        }
        
        if isOnline {
            db.collection("users").document(uid).setData(update, merge: true) { error in
                if error == nil {
                    DispatchQueue.main.async {
                        self.lastDailyAnswerDate = today
                        if correct {
                            self.dailyModePoints += 2
                        }
                    }
                }
                completion(error)
            }
        } else {
            savePendingUpdate(update)
            completion(NSError(domain: "Offline", code: -1009, userInfo: [NSLocalizedDescriptionKey: "You must be online to answer the Daily Question."]))
        }
    }

    // MARK: - Fetch Methods

    func fetchTimeTrialScores(completion: @escaping ([String: Int]?, Error?) -> Void) {
        fetchScores(prefix: "TimeTrialStage", completion: completion)
    }

    func fetchRoadmapScores(completion: @escaping ([String: Int]?, Error?) -> Void) {
        fetchScores(prefix: "RoadmapStage", completion: completion)
    }
        
    func fetchFreestyleScore(completion: @escaping (Int) -> Void) {
        guard let uid = Auth.auth().currentUser?.uid else {
            completion(0)
            return
        }

        let docRef = db.collection("users").document(uid)

        docRef.getDocument(source: .cache) { snapshot, _ in
            if let data = snapshot?.data(), let score = data["freestyleScore"] as? Int {
                completion(score)
            } else {
                docRef.getDocument(source: .server) { snapshot, _ in
                    if let data = snapshot?.data(), let score = data["freestyleScore"] as? Int {
                        completion(score)
                    } else {
                        completion(0)
                    }
                }
            }
        }
    }
    
    func fetchDailyQuestionScore(completion: @escaping (Int?, Error?) -> Void) {
            guard let userId = Auth.auth().currentUser?.uid else {
                completion(nil, NSError(domain: "UserNotLoggedIn", code: 401, userInfo: nil))
                return
            }

            let db = Firestore.firestore()
            let docRef = db.collection("users").document(userId)

            docRef.getDocument { document, error in
                if let error = error {
                    completion(nil, error)
                } else if let document = document, document.exists {
                    let data = document.data()
                    let dailyScore = data?["dailyScore"] as? Int ?? 0
                    completion(dailyScore, nil)
                } else {
                    completion(0, nil)
                }
            }
        }

    private func fetchScores(prefix: String, completion: @escaping ([String: Int]?, Error?) -> Void) {
        guard let uid = Auth.auth().currentUser?.uid else {
            completion(nil, NSError(domain: "UserNotLoggedIn", code: 401))
            return
        }

        let docRef = db.collection("users").document(uid)

        docRef.getDocument(source: .cache) { snapshot, error in
            if let data = snapshot?.data() {
                let filtered = data.filter { $0.key.starts(with: prefix) }
                    .compactMapValues { $0 as? Int }
                completion(filtered, nil)
            } else {
                docRef.getDocument(source: .server) { snapshot, error in
                    guard let data = snapshot?.data(), error == nil else {
                        completion(nil, error)
                        return
                    }
                    let filtered = data.filter { $0.key.starts(with: prefix) }
                        .compactMapValues { $0 as? Int }
                    completion(filtered, nil)
                }
            }
        }
    }

    func fetchUnlockedStages(completion: @escaping (Int?, Error?) -> Void) {
        guard let uid = Auth.auth().currentUser?.uid else {
            completion(nil, NSError(domain: "UserNotLoggedIn", code: 401))
            return
        }

        let docRef = db.collection("users").document(uid)

        docRef.getDocument(source: .cache) { snapshot, error in
            if let data = snapshot?.data(), let stage = data["unlockedStages"] as? Int {
                completion(stage, nil)
            } else {
                docRef.getDocument(source: .server) { snapshot, error in
                    guard let data = snapshot?.data(), error == nil else {
                        completion(nil, error)
                        return
                    }
                    let stage = data["unlockedStages"] as? Int ?? 0
                    completion(stage, nil)
                }
            }
        }
    }

    // MARK: - Load and Sync Logic

    private func loadUserDataWithFallback() {
        if isOnline {
            loadUserData()
        } else {
            loadFromUserDefaults()
        }
    }

    func loadUserData() {
        guard let uid = Auth.auth().currentUser?.uid else { return }

        db.collection("users").document(uid).getDocument(source: .server) { snapshot, error in
            guard let data = snapshot?.data() else {
                self.loadFromUserDefaults()
                return
            }

            let roadmap = data
                .filter { $0.key.starts(with: "RoadmapStage") }
                .compactMapValues { $0 as? Int }

            let timeTrials = data
                .filter { $0.key.starts(with: "TimeTrialStage") }
                .compactMapValues { $0 as? Int }

            let unlocked = data["unlockedStages"] as? Int ?? 0
            let dailyPoints = data["DailyModePoints"] as? Int ?? 0
            let lastAnswer = data["lastDailyAnswerDate"] as? String
            let freestyle = data["freestyleScore"] as? Int ?? 0

            DispatchQueue.main.async {
                self.roadmapScores = roadmap
                self.timeTrialScores = timeTrials
                self.unlockedStage = unlocked
                self.dailyModePoints = dailyPoints
                self.lastDailyAnswerDate = lastAnswer
                self.freestyleScore = freestyle
            }

            // Save for offline fallback
            UserDefaults.standard.set(roadmap, forKey: "roadmapScores")
            UserDefaults.standard.set(timeTrials, forKey: "timeTrialScores")
            UserDefaults.standard.set(unlocked, forKey: "unlockedStage")
            UserDefaults.standard.set(dailyPoints, forKey: "dailyModePoints")
            UserDefaults.standard.set(lastAnswer, forKey: "lastDailyAnswerDate")
            UserDefaults.standard.set(freestyle, forKey: "freestyleScore")
        }
    }

    private func loadFromUserDefaults() {
        if let roadmap = UserDefaults.standard.dictionary(forKey: "roadmapScores") as? [String: Int] {
            roadmapScores = roadmap
        }
        if let timeTrials = UserDefaults.standard.dictionary(forKey: "timeTrialScores") as? [String: Int] {
            timeTrialScores = timeTrials
        }
        unlockedStage = UserDefaults.standard.integer(forKey: "unlockedStage")
        dailyModePoints = UserDefaults.standard.integer(forKey: "dailyModePoints")
        lastDailyAnswerDate = UserDefaults.standard.string(forKey: "lastDailyAnswerDate")
        freestyleScore = UserDefaults.standard.integer(forKey: "freestyleScore")
    }
    
    private func updateLocalCache(with update: [String: Any]) {
        DispatchQueue.main.async {
            var roadmap = self.roadmapScores
            var trials = self.timeTrialScores
            var unlocked = self.unlockedStage
            var freestyle = self.freestyleScore

            for (key, value) in update {
                if let intVal = value as? Int {
                    if key.starts(with: "RoadmapStage") {
                        roadmap[key] = intVal
                    } else if key.starts(with: "TimeTrialStage") {
                        trials[key] = intVal
                    } else if key == "unlockedStages" {
                        unlocked = intVal
                    } else if key == "freestyleScore" {
                        freestyle = intVal
                    }
                }
            }

            self.roadmapScores = roadmap
            self.timeTrialScores = trials
            self.unlockedStage = unlocked
            self.freestyleScore = freestyle

            UserDefaults.standard.set(roadmap, forKey: "roadmapScores")
            UserDefaults.standard.set(trials, forKey: "timeTrialScores")
            UserDefaults.standard.set(unlocked, forKey: "unlockedStage")
            UserDefaults.standard.set(freestyle, forKey: "freestyleScore")
        }
    }
}
