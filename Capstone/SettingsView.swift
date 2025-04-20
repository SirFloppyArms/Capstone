import SwiftUI
import Firebase
import FirebaseAuth
import FirebaseFirestore

struct SettingsView: View {
    @State private var showResetAlert = false
    @State private var password = ""
    @State private var errorMessage = ""

    var body: some View {
        Form {
            Section(header: Text("Account")) {
                Button("Sign Out", role: .destructive) {
                    try? Auth.auth().signOut()
                    UIApplication.shared.windows.first?.rootViewController = UIHostingController(rootView: AuthView())
                }
            }

            Section(header: Text("Data")) {
                Button("Reset All Scores", role: .destructive) {
                    showResetAlert = true
                }
            }
        }
        .alert("Reset Scores", isPresented: $showResetAlert) {
            SecureField("Enter your password", text: $password)
            Button("Confirm", role: .destructive) {
                verifyAndReset()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This will delete all your scores. Enter your password to confirm.")
        }
    }

    func verifyAndReset() {
        guard let user = Auth.auth().currentUser, let email = user.email else { return }
        let credential = EmailAuthProvider.credential(withEmail: email, password: password)

        user.reauthenticate(with: credential) { result, error in
            if let error = error {
                errorMessage = error.localizedDescription
            } else {
                let db = Firestore.firestore()
                db.collection("users").document(user.uid).setData([:], merge: true)
            }
        }
    }
}
