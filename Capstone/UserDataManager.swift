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

    private init() {
        startNetworkMonitor()
        loadPendingUpdates()
        loadUserData()
    }

    private let db = Firestore.firestore()
    private let pendingUpdatesKey = "PendingUpdates"
    private var isOnline = false
    private var pendingUpdates: [[String: Any]] = []

    private func startNetworkMonitor() {
        let monitor = NWPathMonitor()
        monitor.pathUpdateHandler = { path in
            self.isOnline = path.status == .satisfied
            if self.isOnline {
                self.syncPendingUpdates()
            }
        }
        let queue = DispatchQueue(label: "NetworkMonitor")
        monitor.start(queue: queue)
    }

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

        let updates = pendingUpdates
        pendingUpdates.removeAll()
        UserDefaults.standard.removeObject(forKey: pendingUpdatesKey)

        for update in updates {
            db.collection("users").document(uid).setData(update, merge: true) { error in
                if let error = error {
                    print("Retrying sync failed: \(error.localizedDescription)")
                    self.savePendingUpdate(update)
                }
            }
        }
    }

    func saveTimeTrialScore(stage: Int, score: Int, completion: @escaping (Error?) -> Void) {
        let field = "TimeTrialStage\(stage)"
        saveScore(field: field, value: score, completion: completion)
    }

    func saveRoadmapScore(stage: Int, score: Int, completion: @escaping (Error?) -> Void) {
        let field = "RoadmapStage\(stage)"
        saveScore(field: field, value: score, completion: completion)
    }

    func updateUnlockedStages(to stage: Int, completion: @escaping (Error?) -> Void) {
        saveScore(field: "unlockedStages", value: stage, completion: completion)
    }

    private func saveScore(field: String, value: Any, completion: @escaping (Error?) -> Void) {
        guard let uid = Auth.auth().currentUser?.uid else {
            completion(NSError(domain: "UserNotLoggedIn", code: 401, userInfo: nil))
            return
        }

        let data = [field: value]

        if isOnline {
            db.collection("users").document(uid).setData(data, merge: true) { error in
                if error != nil {
                    self.savePendingUpdate(data)
                }
                completion(error)
            }
        } else {
            savePendingUpdate(data)
            completion(nil)
        }
    }

    // ✅ Dual-source and safe fetch
    func fetchTimeTrialScores(completion: @escaping ([String: Int]?, Error?) -> Void) {
        guard let uid = Auth.auth().currentUser?.uid else {
            completion(nil, NSError(domain: "UserNotLoggedIn", code: 401, userInfo: nil))
            return
        }

        db.collection("users").document(uid).getDocument(source: .cache) { snapshot, error in
            if let error = error {
                print("Cache fetch error (TimeTrial): \(error.localizedDescription)")
            }

            if let data = snapshot?.data() as? [String: Any] {
                let scores = data.filter { $0.key.starts(with: "TimeTrialStage") }
                    .compactMapValues { $0 as? Int }
                completion(scores, nil)
            } else {
                // Fallback to server fetch
                self.db.collection("users").document(uid).getDocument(source: .server) { snapshot, error in
                    if let error = error {
                        completion(nil, error)
                        return
                    }
                    let data = snapshot?.data() ?? [:]
                    let scores = data.filter { $0.key.starts(with: "TimeTrialStage") }
                        .compactMapValues { $0 as? Int }
                    completion(scores, nil)
                }
            }
        }
    }

    func fetchRoadmapScores(completion: @escaping ([String: Int]?, Error?) -> Void) {
        guard let uid = Auth.auth().currentUser?.uid else {
            completion(nil, NSError(domain: "UserNotLoggedIn", code: 401, userInfo: nil))
            return
        }

        db.collection("users").document(uid).getDocument(source: .cache) { snapshot, error in
            if let error = error {
                print("Cache fetch error (Roadmap): \(error.localizedDescription)")
            }

            if let data = snapshot?.data() as? [String: Any] {
                let scores = data.filter { $0.key.starts(with: "RoadmapStage") }
                    .compactMapValues { $0 as? Int }
                completion(scores, nil)
            } else {
                self.db.collection("users").document(uid).getDocument(source: .server) { snapshot, error in
                    if let error = error {
                        completion(nil, error)
                        return
                    }
                    let data = snapshot?.data() ?? [:]
                    let scores = data.filter { $0.key.starts(with: "RoadmapStage") }
                        .compactMapValues { $0 as? Int }
                    completion(scores, nil)
                }
            }
        }
    }

    func fetchUnlockedStages(completion: @escaping (Int?, Error?) -> Void) {
        guard let uid = Auth.auth().currentUser?.uid else {
            completion(nil, NSError(domain: "UserNotLoggedIn", code: 401, userInfo: nil))
            return
        }

        db.collection("users").document(uid).getDocument(source: .cache) { snapshot, error in
            if let error = error {
                print("Cache fetch error (UnlockedStages): \(error.localizedDescription)")
            }

            if let data = snapshot?.data(), let stage = data["unlockedStages"] as? Int {
                completion(stage, nil)
            } else {
                self.db.collection("users").document(uid).getDocument(source: .server) { snapshot, error in
                    if let error = error {
                        completion(nil, error)
                        return
                    }
                    let data = snapshot?.data() ?? [:]
                    let stage = data["unlockedStages"] as? Int ?? 0
                    completion(stage, nil)
                }
            }
        }
    }

    func loadUserData() {
        guard let uid = Auth.auth().currentUser?.uid else { return }

        db.collection("users").document(uid).getDocument(source: .cache) { snapshot, error in
            guard let data = snapshot?.data() else { return }

            self.roadmapScores = data
                .filter { $0.key.starts(with: "RoadmapStage") }
                .compactMapValues { $0 as? Int }

            self.timeTrialScores = data
                .filter { $0.key.starts(with: "TimeTrialStage") }
                .compactMapValues { $0 as? Int }

            self.unlockedStage = data["unlockedStages"] as? Int ?? 0
        }
    }
}
