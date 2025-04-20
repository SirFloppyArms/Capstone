import Firebase
import FirebaseFirestore
import FirebaseAuth

class UserDataManager: ObservableObject {
    static let shared = UserDataManager()
    private init() {}

    private let db = Firestore.firestore()

    func saveTimeTrialScore(stage: Int, score: Int, completion: @escaping (Error?) -> Void) {
        guard let uid = Auth.auth().currentUser?.uid else {
            completion(NSError(domain: "UserNotLoggedIn", code: 401, userInfo: nil))
            return
        }

        let field = "TimeTrialStage\(stage)"
        db.collection("users").document(uid).updateData([field: score], completion: completion)
    }
    
    func saveRoadmapScore(stage: Int, score: Int, completion: @escaping (Error?) -> Void) {
        guard let uid = Auth.auth().currentUser?.uid else {
            completion(NSError(domain: "UserNotLoggedIn", code: 401, userInfo: nil))
            return
        }

        let field = "RoadmapStage\(stage)"
        db.collection("users").document(uid).updateData([field: score], completion: completion)
    }

    func fetchTimeTrialScores(completion: @escaping ([String: Int]?, Error?) -> Void) {
        guard let uid = Auth.auth().currentUser?.uid else {
            completion(nil, NSError(domain: "UserNotLoggedIn", code: 401, userInfo: nil))
            return
        }

        db.collection("users").document(uid).getDocument { snapshot, error in
            if let data = snapshot?.data() as? [String: Any] {
                let scores = data.filter { $0.key.starts(with: "TimeTrialStage") }
                    .compactMapValues { $0 as? Int }
                completion(scores, nil)
            } else {
                completion(nil, error)
            }
        }
    }
    
    func fetchRoadmapScores(completion: @escaping ([String: Int]?, Error?) -> Void) {
        guard let uid = Auth.auth().currentUser?.uid else {
            completion(nil, NSError(domain: "UserNotLoggedIn", code: 401, userInfo: nil))
            return
        }

        db.collection("users").document(uid).getDocument { snapshot, error in
            if let data = snapshot?.data() as? [String: Any] {
                let scores = data.filter { $0.key.starts(with: "RoadmapStage") }
                    .compactMapValues { $0 as? Int }
                completion(scores, nil)
            } else {
                completion(nil, error)
            }
        }
    }
    
    func updateUnlockedStages(to stage: Int, completion: @escaping (Error?) -> Void) {
        guard let uid = Auth.auth().currentUser?.uid else {
            completion(NSError(domain: "UserNotLoggedIn", code: 401, userInfo: nil))
            return
        }

        db.collection("users").document(uid).updateData(["unlockedStages": stage], completion: completion)
    }

    func fetchUnlockedStages(completion: @escaping (Int?, Error?) -> Void) {
        guard let uid = Auth.auth().currentUser?.uid else {
            completion(nil, NSError(domain: "UserNotLoggedIn", code: 401, userInfo: nil))
            return
        }

        db.collection("users").document(uid).getDocument { snapshot, error in
            if let data = snapshot?.data(), let stage = data["unlockedStages"] as? Int {
                completion(stage, nil)
            } else {
                completion(nil, error)
            }
        }
    }
}
