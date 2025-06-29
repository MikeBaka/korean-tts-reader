```swift
// PASTE THIS CORRECTED CODE INTO ReaderView.swift

import SwiftUI
import HanguCore
import Combine

struct ReaderView: View {
    @StateObject private var viewModel: ReaderViewModel

    private static let sampleText = "안녕하세요, 만나서 반갑습니다. 제 이름은 루입니다."

    init() {
        _viewModel = StateObject(wrappedValue: ReaderViewModel(text: Self.sampleText))
    }

    var body: some View {
        // FIX: Replaced NavigationStack with NavigationView for iOS 15 compatibility.
        NavigationView {
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
                    Button(action: { viewModel.togglePlay() }) {
                        Image(systemName: viewModel.isPlaying ? "pause.fill" : "play.fill")
                            .font(.body)
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Export", action: { viewModel.exportVocab() })
                }
            }
        }
    }
}

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
        let nsAttributedString = NSMutableAttributedString(attributedString)
        let fullRange = NSRange(location: 0, length: nsAttributedString.length)
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineSpacing = 6
        nsAttributedString.addAttribute(.paragraphStyle, value: paragraphStyle, range: fullRange)
        nsAttributedString.addAttribute(.font, value: UIFont.preferredFont(forTextStyle: .largeTitle), range: fullRange)
        uiView.attributedText = nsAttributedString
        guard highlightedWordIndex >= 0, highlightedWordIndex < speechMarks.count else { return }
        let mark = speechMarks[highlightedWordIndex]
        let range = NSRange(location: mark.charStart, length: mark.charEnd - mark.charStart)
        uiView.layoutManager.ensureLayout(for: uiView.textContainer)
        let glyphRange = uiView.layoutManager.glyphRange(forCharacterRange: range, actualCharacterRange: nil)
        let wordRect = uiView.layoutManager.boundingRect(forGlyphRange: glyphRange, in: uiView.textContainer)
        guard !wordRect.isNull, !wordRect.isInfinite else { return }
        let viewHeight = uiView.bounds.height
        let desiredY = wordRect.origin.y - (viewHeight / 3)
        let maxOffset = uiView.contentSize.height - viewHeight
        let newOffset = max(0, min(desiredY, maxOffset))
        if abs(uiView.contentOffset.y - newOffset) > 5 {
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
```
