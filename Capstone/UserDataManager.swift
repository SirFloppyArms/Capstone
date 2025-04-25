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
                self.loadUserData() // Re-sync when back online
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
            self.updateLocalCache(with: update) // ✅ NEW: update @Published values from local change
            completion(nil)
        }
    }

    // MARK: - Public Fetch Methods

    func fetchTimeTrialScores(completion: @escaping ([String: Int]?, Error?) -> Void) {
        fetchScores(prefix: "TimeTrialStage", completion: completion)
    }

    func fetchRoadmapScores(completion: @escaping ([String: Int]?, Error?) -> Void) {
        fetchScores(prefix: "RoadmapStage", completion: completion)
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

            DispatchQueue.main.async {
                self.roadmapScores = roadmap
                self.timeTrialScores = timeTrials
                self.unlockedStage = unlocked
            }

            // Save to UserDefaults for offline fallback
            UserDefaults.standard.set(roadmap, forKey: "roadmapScores")
            UserDefaults.standard.set(timeTrials, forKey: "timeTrialScores")
            UserDefaults.standard.set(unlocked, forKey: "unlockedStage")
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
    }
    
    private func updateLocalCache(with update: [String: Any]) {
        DispatchQueue.main.async {
            var roadmap = self.roadmapScores
            var trials = self.timeTrialScores
            var unlocked = self.unlockedStage

            for (key, value) in update {
                if let intVal = value as? Int {
                    if key.starts(with: "RoadmapStage") {
                        roadmap[key] = intVal
                    } else if key.starts(with: "TimeTrialStage") {
                        trials[key] = intVal
                    } else if key == "unlockedStages" {
                        unlocked = intVal
                    }
                }
            }

            self.roadmapScores = roadmap
            self.timeTrialScores = trials
            self.unlockedStage = unlocked

            UserDefaults.standard.set(roadmap, forKey: "roadmapScores")
            UserDefaults.standard.set(trials, forKey: "timeTrialScores")
            UserDefaults.standard.set(unlocked, forKey: "unlockedStage")
        }
    }
}
