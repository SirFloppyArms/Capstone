import SwiftUI
import PDFKit

struct HandbookPDFView: View {
    @State private var searchText = ""
    @State private var results: [PDFSelection] = []
    @State private var currentMatchIndex = 0
    @State private var currentPage: Int = 1
    @State private var totalPages: Int = 0

    private let pdfView = PDFView()

    var body: some View {
        VStack(spacing: 0) {
            SearchBar(
                text: $searchText,
                onSearch: performSearch,
                onNext: showNextMatch,
                onPrev: showPreviousMatch
            )

            PDFKitView(pdfView: pdfView)
                .onAppear {
                    if let url = Bundle.main.url(forResource: "CompleteHandbook", withExtension: "pdf"),
                       let document = PDFDocument(url: url) {
                        pdfView.document = document
                        pdfView.autoScales = true
                        pdfView.displayMode = .singlePageContinuous
                        pdfView.displayDirection = .horizontal
                        pdfView.usePageViewController(true, withViewOptions: nil)
                        pdfView.displaysPageBreaks = true
                        pdfView.backgroundColor = .systemBackground

                        totalPages = document.pageCount
                        currentPage = 1

                        NotificationCenter.default.addObserver(forName: .PDFViewPageChanged, object: pdfView, queue: .main) { _ in
                            if let page = pdfView.currentPage,
                               let index = pdfView.document?.index(for: page) {
                                currentPage = index + 1
                            }
                        }
                    }
                }

            HStack {
                if totalPages >= 1 {
                    HStack {
                        Text("Page \(currentPage) / \(totalPages)")
                            .font(.caption)
                            .foregroundColor(.secondary)

                        Slider(
                            value: Binding(
                                get: { Double(currentPage) },
                                set: { newValue in
                                    currentPage = Int(newValue)
                                    if let page = pdfView.document?.page(at: currentPage - 1) {
                                        pdfView.go(to: page)
                                    }
                                }
                            ),
                            in: 1...Double(totalPages),
                            step: 1
                        )
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 6)
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 6)
        }
        .navigationTitle("MPI Handbook")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func performSearch(_ query: String) {
        guard let doc = pdfView.document else { return }
        results.removeAll()

        let matches = doc.findString(query, withOptions: .caseInsensitive)
        results = matches

        pdfView.highlightedSelections = results.map { selection in
            selection.color = .yellow
            return selection
        }

        if let firstMatch = results.first {
            pdfView.setCurrentSelection(firstMatch, animate: true)
            pdfView.go(to: firstMatch)
        }
    }

    private func showCurrentMatch() {
        guard results.indices.contains(currentMatchIndex) else { return }
        let selection = results[currentMatchIndex]
        pdfView.setCurrentSelection(selection, animate: true)
        pdfView.go(to: selection)
    }

    private func showNextMatch() {
        guard !results.isEmpty else { return }
        currentMatchIndex = (currentMatchIndex + 1) % results.count
        showCurrentMatch()
    }

    private func showPreviousMatch() {
        guard !results.isEmpty else { return }
        currentMatchIndex = (currentMatchIndex - 1 + results.count) % results.count
        showCurrentMatch()
    }
}

// MARK: - PDFKitView
struct PDFKitView: UIViewRepresentable {
    let pdfView: PDFView

    func makeUIView(context: Context) -> PDFView {
        if let scrollView = pdfView.subviews.first(where: { $0 is UIScrollView }) as? UIScrollView {
            scrollView.showsVerticalScrollIndicator = false
            scrollView.showsHorizontalScrollIndicator = false
            scrollView.indicatorStyle = .default
            scrollView.isPagingEnabled = true
        }
        return pdfView
    }

    func updateUIView(_ uiView: PDFView, context: Context) {}
}
// MARK: - SearchBar

struct SearchBar: View {
    @Binding var text: String
    var onSearch: (String) -> Void
    var onNext: () -> Void
    var onPrev: () -> Void

    var body: some View {
        HStack(spacing: 8) {
            TextField("Search handbook...", text: $text)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .onSubmit {
                    onSearch(text)
                }

            Button(action: { onSearch(text) }) {
                Image(systemName: "magnifyingglass")
            }

            Button(action: onPrev) {
                Image(systemName: "chevron.up")
            }

            Button(action: onNext) {
                Image(systemName: "chevron.down")
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 6)
    }
}
