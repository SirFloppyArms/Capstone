import SwiftUI

struct ContentView: View {
    @Environment(\.colorScheme) private var colorScheme
    @Namespace private var animation

    var body: some View {
        NavigationView {
            GeometryReader { geo in
                ZStack {
                    background

                    VStack(spacing: 0) {
                        // Header - always at top
                        header
                            .padding(.top)
                            .padding(.horizontal)
                            .layoutPriority(1)

                        Spacer()

                        // Logo & Slogan - centered but slightly toward the top
                        VStack(spacing: geo.size.height * 0.02) {
                            logo
                                .frame(width: geo.size.width * 0.25, height: geo.size.width * 0.25)

                            Text("Master the road before you hit it.")
                                .font(.headline)
                                .foregroundColor(textColor.opacity(0.85))
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 24)
                                .minimumScaleFactor(0.5)
                        }
                        .layoutPriority(0)

                        Spacer()

                        // Feature Grid + Navigation Cards - anchored to bottom
                        VStack(spacing: 20) {
                            FeatureGrid()
                                .frame(maxWidth: 600)

                            VStack(spacing: 14) {
                                NavigationCard(
                                    icon: "road.lanes",
                                    title: "Freestyle",
                                    color: .orange,
                                    destination: FreestyleView()
                                )

                                NavigationCard(
                                    icon: "questionmark.circle.fill",
                                    title: "Daily Question",
                                    color: .purple,
                                    destination: DailyQuestionView()
                                )

                                NavigationCard(
                                    icon: "chart.bar.fill",
                                    title: "Leaderboard",
                                    color: .green,
                                    destination: LeaderboardView()
                                )

                                NavigationCard(
                                    icon: "book.fill",
                                    title: "Handbook",
                                    color: .blue,
                                    destination: HandbookPDFView()
                                )
                            }
                            .frame(maxWidth: 600)
                        }
                        .padding(.horizontal)
                        .padding(.bottom)
                        .layoutPriority(1)
                    }
                    .frame(width: geo.size.width, height: geo.size.height)
                }
            }
            .navigationBarHidden(true)
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }

    // MARK: - Background
    private var background: some View {
        LinearGradient(
            gradient: Gradient(colors: colorScheme == .dark
                               ? [Color(red: 0.07, green: 0.1, blue: 0.18), Color(red: 0.12, green: 0.14, blue: 0.22)]
                               : [Color(red: 0.95, green: 0.98, blue: 1.0), Color(red: 0.8, green: 0.9, blue: 1.0)]),
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
                .minimumScaleFactor(0.7)

            Spacer()

            NavigationLink(destination: SettingsView()) {
                Image(systemName: "gearshape.fill")
                    .font(.title2)
                    .foregroundColor(textColor)
            }
        }
    }

    // MARK: - Logo
    private var logo: some View {
        Image(colorScheme == .dark ? "AppLogoDark" : "AppLogoLight")
            .resizable()
            .scaledToFit()
            .clipShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
            .shadow(radius: 10)
            .matchedGeometryEffect(id: "app-logo", in: animation)
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

