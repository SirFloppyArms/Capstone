import SwiftUI

struct ContentView: View {
    @Environment(\.colorScheme) private var colorScheme
    @Namespace private var animation

    var body: some View {
        NavigationView {
            ZStack {
                background

                VStack(spacing: 24) {
                    header

                    Spacer(minLength: 20)

                    logo

                    Text("Master the road before you hit it.")
                        .font(.headline)
                        .foregroundColor(textColor.opacity(0.85))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 24)
                        .minimumScaleFactor(0.8)

                    Spacer()

                    VStack(spacing: 20) {
                        FeatureGrid()
                        NavigationCard(
                            icon: "chart.bar.fill",
                            title: "Leaderboard",
                            color: .green,
                            destination: LeaderboardView()
                        )
                    }
                    .padding(.horizontal)
                    .frame(maxWidth: 600)

                    Spacer(minLength: 32)
                }
                .padding(.top, 20)
                .padding(.bottom, 20)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .animation(.easeInOut(duration: 0.3), value: colorScheme)
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }

    // MARK: - Background
    private var background: some View {
        LinearGradient(
            gradient: Gradient(colors: colorScheme == .dark
                               ? [Color(red: 0.07, green: 0.1, blue: 0.18), Color(red: 0.12, green: 0.14, blue: 0.22)]
                               : [Color(red: 0.75, green: 0.88, blue: 1.0), Color(red: 0.6, green: 0.84, blue: 1.0)]),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
    }

    // MARK: - Header
    private var header: some View {
        HStack {
            NavigationLink(destination: AboutView()) {
                Image(systemName: "info.circle")
                    .font(.title2)
                    .foregroundColor(textColor)
            }

            Spacer()

            Text("SmartDrive Pro")
                .font(.system(size: 26, weight: .bold, design: .rounded))
                .foregroundColor(textColor)
                .minimumScaleFactor(0.8)

            Spacer()

            NavigationLink(destination: SettingsView()) {
                Image(systemName: "gearshape.fill")
                    .font(.title2)
                    .foregroundColor(textColor)
            }
        }
        .padding(.horizontal)
    }

    // MARK: - Logo
    private var logo: some View {
        Image(colorScheme == .dark ? "AppLogoDark" : "AppLogoLight")
            .resizable()
            .scaledToFit()
            .frame(width: 110, height: 110)
            .clipShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
            .shadow(radius: 10)
            .matchedGeometryEffect(id: "app-logo", in: animation)
            .padding(.bottom, 8)
    }

    private var textColor: Color {
        colorScheme == .dark ? .white : .black
    }
}

// MARK: - Feature Grid
struct FeatureGrid: View {
    var body: some View {
        HStack(spacing: 20) {
            FeatureCard(
                icon: "map.fill",
                title: "Roadmap",
                description: "Travel the road to answer questions!",
                color: .blue,
                destination: RoadmapView()
            )
            FeatureCard(
                icon: "timer",
                title: "Time Trials",
                description: "Race the clock to answer questions!",
                color: .red,
                destination: TimeTrialsView()
            )
        }
    }
}

// MARK: - Feature Card
struct FeatureCard<Destination: View>: View {
    let icon: String
    let title: String
    let description: String
    let color: Color
    let destination: Destination

    var body: some View {
        NavigationLink(destination: destination) {
            VStack(alignment: .leading, spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 26))
                    .foregroundColor(.white)

                Text(title)
                    .font(.headline)
                    .foregroundColor(.white)

                Text(description)
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.85))
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
            }
            .padding()
            .frame(minHeight: 130)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .fill(color.opacity(0.9))
                    .shadow(color: color.opacity(0.3), radius: 6, x: 0, y: 4)
            )
        }
    }
}

// MARK: - Navigation Card
struct NavigationCard<Destination: View>: View {
    let icon: String
    let title: String
    let color: Color
    let destination: Destination

    var body: some View {
        NavigationLink(destination: destination) {
            HStack(spacing: 16) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(.white)

                Text(title)
                    .font(.headline)
                    .foregroundColor(.white)

                Spacer()

                Image(systemName: "chevron.right")
                    .foregroundColor(.white.opacity(0.8))
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(color.opacity(0.9))
                    .shadow(color: color.opacity(0.25), radius: 4, x: 0, y: 3)
            )
        }
    }
}

