diff --git a/ios/HanguCore/Sources/HanguCore/ReaderViewModel.swift b/ios/HanguCore/Sources/HanguCore/ReaderViewModel.swift
@@
-    // MARK: - Published values expected by ReaderView
-    @Published public private(set) var isPlaying: Bool = false
-
-
-
-    @Published var currentWordIndex: Int = 0
-
-    var isPlaying: Bool { ttsPlayer.isPlaying }
-
-
-    // MARK: - Published Properties
-    @Published public var attributed: AttributedString
-    @Published public var isPlaying: Bool = false
+    // MARK: - Published values expected by ReaderView
+    @Published public private(set) var isPlaying: Bool = false   // ① **single definition**
+    @Published public var attributed: AttributedString
+    @Published public var speechMarks: [SpeechMark] = []         // now only here
+    @Published public var currentWordIndex: Int = 0
@@
-    var speechMarks: [SpeechMark] = []
-    var currentWordIndex: Int = -1 {
-        didSet {
-            if oldValue != currentWordIndex {
-                updateAttributedString()
-            }
-        }
-    }
+    // Extra scratch-space versions (for highlight updates)
+    private var currentWordIndexScratch: Int = -1
@@
-        setupBindings()
+        setupBindings()
+        synthesizeText()     // kick off Polly once ViewModel exists
     }
 
-    // MARK: - UI actions
-    func togglePlay() {
-        if ttsPlayer.isPlaying {
-            ttsPlayer.pause()
-        } else if
-          let url = Bundle.main.url(forResource: "sample", withExtension: "mp3") {
-            ttsPlayer.play(url: url)
-        }
-    }
-
-
-    // MARK: - Public Methods
-    public func togglePlay() {
+    // MARK: - Public Methods --------------------------------------------------
+    public func togglePlay() {                                // ← **single version**
         guard let url = audioURL else { return }
 
         if ttsPlayer.isPlaying {
             ttsPlayer.pause()
         } else {
-            if ttsPlayer.currentTime > 0 {
-                ttsPlayer.resume()
-            } else if let url = self.audioURL {
-                ttsPlayer.play(url: url)
-            }
+            ttsPlayer.currentTime > 0 ? ttsPlayer.resume()
+                                      : ttsPlayer.play(url: url)
         }
     }
@@
-    // MARK: - Private & Internal Methods
-    private func setupBindings() {
-
-    // MARK: - UI actions
-    func togglePlay() {
-        if ttsPlayer.isPlaying {
-            ttsPlayer.pause()
-        } else {
-            ttsPlayer.play()
-        }
-    }
+    // MARK: - Private --------------------------------------------------------
+    private func setupBindings() {
         // When testing with a mock player, we might need to manually publish changes.
@@
         currentTimePublisher
             .receive(on: DispatchQueue.main)
             .sink { [weak self] newTime in
-                self?.updateHighlight(at: newTime)
+                self?.updateHighlight(at: newTime)
             }
             .store(in: &cancellables)
     }
@@
-    func updateHighlight(at time: TimeInterval) {
+    private func updateHighlight(at time: TimeInterval) {
@@
-        guard let newIndex = speechMarks.lastIndex(where: { $0.startMs <= timeInMs }) else {
-            if currentWordIndex != -1 {
-                currentWordIndex = -1
+        guard let newIndex = speechMarks.lastIndex(where: { $0.startMs <= timeInMs }) else {
+            if currentWordIndexScratch != -1 {
+                currentWordIndexScratch = -1
             }
             return
         }
 
-        if newIndex != currentWordIndex {
-            currentWordIndex = newIndex
+        if newIndex != currentWordIndexScratch {
+            currentWordIndexScratch = newIndex
         }
     }
@@
-fileprivate protocol TTSPlayerProtocol {
-    var isPlayingPublisher: AnyPublisher<Bool, Never> { get }
-    var currentTimePublisher: AnyPublisher<TimeInterval, Never> { get }
-}
-
-extension TTSPlayer: TTSPlayerProtocol {
-    var isPlayingPublisher: AnyPublisher<Bool, Never> { $isPlaying.eraseToAnyPublisher() }
-    var currentTimePublisher: AnyPublisher<TimeInterval, Never> { $currentTime.eraseToAnyPublisher() }
-}
+// (The test-only protocol/extension is no longer needed; TTSPlayer already
+//  exposes those @Published vars directly.)
