import SwiftUI

struct ContentView: View {
    var body: some View {
        NavigationView {
            VStack(spacing: 30) {
                Text("MPI Driving Quiz")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .padding(.top)

                NavigationLink(destination: RoadmapView()) {
                    Text("Start Quiz (Roadmap Mode)")
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                        .padding(.horizontal)
                }

                NavigationLink(destination: TimeTrialsView()) {
                    Text("Time Trials")
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.red)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                        .padding(.horizontal)
                }

                Spacer()
            }
            .padding()
        }
    }
}
