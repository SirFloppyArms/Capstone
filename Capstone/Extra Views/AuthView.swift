import SwiftUI
import Firebase
import FirebaseAuth
import FirebaseFirestore

struct AuthView: View {
    @State private var username = ""
    @State private var password = ""
    @State private var isSignUp = false
    @State private var staySignedIn = false
    @State private var errorMessage: String?

    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text(isSignUp ? "Sign Up" : "Sign In")
                    .font(.largeTitle.bold())

                TextField("Username", text: $username)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .autocapitalization(.none)

                SecureField("Password", text: $password)
                    .textFieldStyle(RoundedBorderTextFieldStyle())

                Toggle("Stay Signed In", isOn: $staySignedIn)
                    .padding(.horizontal)

                if let error = errorMessage {
                    Text(error)
                        .foregroundColor(.red)
                        .multilineTextAlignment(.center)
                }

                Button(action: handleAuth) {
                    Text(isSignUp ? "Create Account" : "Log In")
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                }

                Button(action: { isSignUp.toggle() }) {
                    Text(isSignUp ? "Already have an account? Sign In" : "Don't have an account? Sign Up")
                        .foregroundColor(.gray)
                }
            }
            .padding()
            .onAppear {
                autoLoginIfEligible()
            }
        }
    }

    func autoLoginIfEligible() {
        let staySignedInPref = UserDefaults.standard.bool(forKey: "staySignedIn")
        if let user = Auth.auth().currentUser, staySignedInPref {
            navigateToMain()
        }
    }

    func handleAuth() {
        errorMessage = nil
        let fakeEmail = "\(username.lowercased())@app.com"

        if isSignUp {
            Auth.auth().createUser(withEmail: fakeEmail, password: password) { result, error in
                if let error = error {
                    self.errorMessage = error.localizedDescription
                    return
                }

                guard let uid = result?.user.uid else { return }
                createUserProfile(uid: uid)
            }
        } else {
            Auth.auth().signIn(withEmail: fakeEmail, password: password) { result, error in
                if let error = error {
                    self.errorMessage = error.localizedDescription
                    return
                }

                UserDefaults.standard.set(staySignedIn, forKey: "staySignedIn")
                navigateToMain()
            }
        }
    }

    func createUserProfile(uid: String) {
        let db = Firestore.firestore()
        let userData: [String: Any] = [
            "username": username
        ]

        db.collection("users").document(uid).setData(userData, merge: true) { error in
            if let error = error {
                self.errorMessage = "Failed to create profile: \(error.localizedDescription)"
            } else {
                UserDefaults.standard.set(staySignedIn, forKey: "staySignedIn")
                navigateToMain()
            }
        }
    }

    func navigateToMain() {
        UIApplication.shared.windows.first?.rootViewController = UIHostingController(rootView: ContentView())
    }
}
