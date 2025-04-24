import SwiftUI

struct AboutView: View {
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        ScrollView {
            VStack(spacing: 32) {

                // Hero Section
                VStack(spacing: 12) {
                    Image(colorScheme == .dark ? "AppLogoDark" : "AppLogoLight")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 100, height: 100)
                        .cornerRadius(20)
                        .shadow(radius: 10)
                        .padding(.top, 20)

                    Text("SmartDrive Pro")
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundColor(.primary)

                    Text("Master the road before you hit it.")
                        .font(.headline)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 30)
                        .fill(LinearGradient(
                            gradient: Gradient(colors: [Color.blue.opacity(0.40), Color.white.opacity(0.15)]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ))
                )
                .padding(.horizontal)
                .padding(.top, 8)

                // Description Card
                AboutCard {
                    Label("About the App", systemImage: "info.circle.fill")
                        .font(.title3.bold())

                    Text("SmartDrive Pro is a comprehensive tool designed to help you prepare for Manitoba's driving knowledge test. Whether you're a new driver or brushing up on the rules, you'll find an intuitive, engaging, and effective way to study.")
                        .font(.body)
                        .foregroundColor(.primary)
                }

                // Features Card
                AboutCard {
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Key Features")
                            .font(.title3)
                            .fontWeight(.semibold)

                        FeatureItem(icon: "car.fill", title: "Roadmap Mode", description: "15 stages with 20 questions each, covering all test topics.")
                        FeatureItem(icon: "clock.fill", title: "Time Trials Mode", description: "30 quick stages with 10 questions each for rapid review.")
                        FeatureItem(icon: "chart.bar.fill", title: "Progress Tracking", description: "Monitor your stats and see how you're improving.")
                        FeatureItem(icon: "globe", title: "Global Leaderboard", description: "Compete with others and see where you stand.")
                        FeatureItem(icon: "wifi.slash", title: "Offline Access", description: "Study anytime, anywhere, without needing an internet connection.")
                    }
                }

                // MPI Contact
                AboutCard {
                    Label("Manitoba Public Insurance", systemImage: "building.columns.fill")
                        .font(.title3.bold())

                    VStack(alignment: .leading, spacing: 8) {
                        Label("204-985-7000", systemImage: "phone.fill")
                        Label("1-800-665-2410", systemImage: "phone.arrow.up.right.fill")
                        Link(destination: URL(string: "https://www.mpi.mb.ca/driver-z/")!) {
                            Label("Driver Z Website", systemImage: "link")
                        }
                    }
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                }
                
                // Developer Info
                AboutCard {
                    Label("Developer", systemImage: "person.crop.circle")
                        .font(.title3.bold())

                    VStack(alignment: .leading, spacing: 8) {
                        Label("Nolan Law", systemImage: "person.fill")
                        Label("nolan.law@yahoo.com", systemImage: "envelope.fill")
                        Label("(204) 403-8767", systemImage: "phone.fill")
                    }
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                }

                Spacer(minLength: 2)
            }
            .padding(.horizontal)
        }
        .background(
            Color(.systemGroupedBackground)
                .ignoresSafeArea()
        )
        .navigationTitle("About")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct AboutCard<Content: View>: View {
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            content
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(.secondarySystemBackground))
                .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 4)
        )
    }
}

struct FeatureItem: View {
    let icon: String
    let title: String
    let description: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(.blue)
                .frame(width: 30)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.semibold)

                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
}
