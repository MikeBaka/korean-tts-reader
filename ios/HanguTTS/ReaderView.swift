import SwiftUI
import HanguCore
import Combine

struct ReaderView: View {
    @StateObject private var viewModel: ReaderViewModel

    // A longer sample text to demonstrate scrolling behavior effectively.
    private static let sampleText = """
    안녕하세요, 만나서 반갑습니다. 제 이름은 루입니다.
    이것은 스크롤 테스트를 위한 긴 텍스트입니다.
    자동 스크롤 기능이 하이라이트된 단어를 화면의 상단 1/3 지점에 유지하는지 확인해 보겠습니다.
    뷰가 업데이트될 때 스크롤이 부드럽게 이동해야 합니다.
    이 기능은 사용자가 텍스트를 편안하게 따라 읽을 수 있도록 도와줍니다.
    마지막 줄까지 테스트해 보겠습니다.
    """

    init() {
        // In a real app, you might inject this dependency. For this implementation,
        // we create the ViewModel directly, using the HanguCore package.
        _viewModel = StateObject(wrappedValue: ReaderViewModel(text: Self.sampleText))
    }

    var body: some View {
        NavigationStack {
            // The custom UIViewRepresentable handles the complex text layout and scrolling logic
            // that is not easily achievable in pure SwiftUI.
            ScrollableTextView(
                attributedString: $viewModel.attributed,
                highlightedWordIndex: $viewModel.currentWordIndex,
                speechMarks: $viewModel.speechMarks
            )
            .ignoresSafeArea(edges: .bottom)
            .navigationTitle("Hangu TTS Reader")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: viewModel.togglePlay) {
                        Image(systemName: viewModel.isPlaying ? "pause.fill" : "play.fill")
                            .font(.body)
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Export", action: viewModel.exportVocab)
                }
            }
        }
    }
}

/// A `UIViewRepresentable` that wraps a `UITextView` to provide advanced features like
/// precise animated scrolling based on text layout information.
private struct ScrollableTextView: UIViewRepresentable {
    @Binding var attributedString: AttributedString
    @Binding var highlightedWordIndex: Int
    @Binding var speechMarks: [SpeechMark]

    func makeUIView(context: Context) -> UITextView {
        let textView = UITextView()
        textView.isEditable = false
        textView.isSelectable = true
        textView.backgroundColor = .clear
        return textView
    }

    func updateUIView(_ uiView: UITextView, context: Context) {
        // 1. Apply styling to the attributed string.
        let nsAttributedString = NSMutableAttributedString(attributedString)
        let fullRange = NSRange(location: 0, length: nsAttributedString.length)
        
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineSpacing = 6
        
        nsAttributedString.addAttribute(.paragraphStyle, value: paragraphStyle, range: fullRange)
        nsAttributedString.addAttribute(.font, value: UIFont.preferredFont(forTextStyle: .largeTitle), range: fullRange)
        
        uiView.attributedText = nsAttributedString

        // 2. Scroll to the currently highlighted word.
        guard highlightedWordIndex >= 0, highlightedWordIndex < speechMarks.count else { return }

        let mark = speechMarks[highlightedWordIndex]
        let range = NSRange(location: mark.charStart, length: mark.charEnd - mark.charStart)

        // We must ensure layout is complete before we can get the word's bounding box.
        uiView.layoutManager.ensureLayout(for: uiView.textContainer)
        let glyphRange = uiView.layoutManager.glyphRange(forCharacterRange: range, actualCharacterRange: nil)
        let wordRect = uiView.layoutManager.boundingRect(forGlyphRange: glyphRange, in: uiView.textContainer)

        guard !wordRect.isNull, !wordRect.isInfinite else { return }

        // 3. Calculate the target scroll offset to position the word 1/3 from the top.
        let viewHeight = uiView.bounds.height
        let desiredY = wordRect.origin.y - (viewHeight / 3)
        let maxOffset = uiView.contentSize.height - viewHeight
        let newOffset = max(0, min(desiredY, maxOffset))

        // 4. Animate the scroll if the offset has changed significantly.
        if abs(uiView.contentOffset.y - newOffset) > 5 { // Tolerance to prevent jitter
            UIView.animate(withDuration: 0.3, delay: 0, options: .curveEaseInOut, animations: {
                uiView.contentOffset = CGPoint(x: 0, y: newOffset)
            })
        }
    }
}

struct ReaderView_Previews: PreviewProvider {
    static var previews: some View {
        ReaderView()
    }
}