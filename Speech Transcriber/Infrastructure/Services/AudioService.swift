//
//  AudioService.swift
//  Speech Transcriber
//
//  Created by Joshua Cleetus on 3/21/25.
//

import Foundation
import AVFoundation
import RxSwift

class AudioService: NSObject, AVAudioRecorderDelegate {
    // MARK: - Properties
    private var audioRecorder: AVAudioRecorder?
    private var audioPlayer: AVAudioPlayer?
    private weak var playbackDelegate: AVAudioPlayerDelegate?
    private var recordingStartTime: Date?
    
    private let audioSettings: [String: Any] = [
        AVFormatIDKey: Int(kAudioFormatLinearPCM),  // Use LINEAR16 for Google
        AVSampleRateKey: 16000.0,                   // 16kHz is preferred by Google
        AVNumberOfChannelsKey: 1,                   // Mono
        AVLinearPCMBitDepthKey: 16,                 // 16-bit
        AVLinearPCMIsBigEndianKey: false,
        AVLinearPCMIsFloatKey: false,
        AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
    ]
    
    private var currentRecordingURL: URL?
    
    private func generateRecordingURL() -> URL {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyyMMdd_HHmmss"
        let timestamp = dateFormatter.string(from: Date())
        return FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("recording_\(timestamp).wav")
    }
    
    // MARK: - Public Methods
    
    /// Starts recording audio with the specified duration.
    /// - Parameter duration: Optional duration in seconds. If nil, records indefinitely until stopped.
    /// - Returns: An Observable emitting `true` if recording starts successfully, or an error if it fails.
    func startRecording(duration: TimeInterval? = nil) -> Observable<Bool> {
        // Generate a new URL for this recording
        currentRecordingURL = generateRecordingURL()
        
        return requestPermissions()
            .flatMap { [weak self] granted -> Observable<Bool> in
                guard let self = self, granted else {
                    return Observable.error(NSError(domain: "AudioService", code: -1,
                        userInfo: [NSLocalizedDescriptionKey: "Permission denied"]))
                }
                
                return Observable.create { observer in
                    do {
                        try self.setupAudioSession()
                        
                        guard let url = self.currentRecordingURL else {
                            throw NSError(domain: "AudioService", code: -1,
                                userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])
                        }
                        
                        // Remove any existing file
                        if FileManager.default.fileExists(atPath: url.path) {
                            try FileManager.default.removeItem(at: url)
                        }
                        
                        // Create recorder
                        self.audioRecorder = try AVAudioRecorder(url: url, settings: self.audioSettings)
                        self.audioRecorder?.delegate = self
                        self.audioRecorder?.isMeteringEnabled = true
                        self.audioRecorder?.prepareToRecord()
                        
                        // Start with a forced minimum recording time approach
                        self.audioRecorder?.record()
                        print("⏺️ Recording started")
                        
                        // Signal success immediately
                        observer.onNext(true)
                        observer.onCompleted()
                        
                    } catch {
                        print("❌ Recording setup error: \(error)")
                        observer.onError(error)
                    }
                    
                    return Disposables.create()
                }
            }
    }
    
    /// Stops the current recording and returns its file URL.
    /// - Returns: An Observable emitting the URL of the recorded file, or an error if no recording is active.
    func stopRecording() -> Observable<URL> {
        return Observable.create { [weak self] observer in
            guard let self = self,
                  let recorder = self.audioRecorder,
                  let url = self.currentRecordingURL else {
                observer.onError(NSError(domain: "AudioService", code: -1,
                    userInfo: [NSLocalizedDescriptionKey: "No active recording found"]))
                return Disposables.create()
            }
            
            // Log duration before stopping
            print("📊 Pre-stop recording duration: \(recorder.currentTime) seconds")
            
            // Stop recording immediately - removing the delay
            recorder.stop()
            
            // Reset the audio session to make the file available
            try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
            
            // Verify file exists and has content
            if FileManager.default.fileExists(atPath: url.path),
               let attrs = try? FileManager.default.attributesOfItem(atPath: url.path),
               let size = attrs[.size] as? Int {
                
                print("📁 Recording file, size: \(size) bytes")
                
                if size > 1000 { // Some arbitrary minimum size for a valid recording
                    print("✅ Valid recording saved at: \(url.path)")
                    self.logRecordingStats(url: url)
                    observer.onNext(url)
                    observer.onCompleted()
                } else {
                    print("⚠️ Recording appears too small: \(size) bytes")
                    observer.onError(NSError(domain: "AudioService", code: -1,
                        userInfo: [NSLocalizedDescriptionKey: "Recording is too small to be valid"]))
                }
            } else {
                print("❌ Recording file is missing or unreadable")
                observer.onError(NSError(domain: "AudioService", code: -1,
                    userInfo: [NSLocalizedDescriptionKey: "Recording file is missing or unreadable"]))
            }
            
            // Clean up
            self.audioRecorder = nil
            
            return Disposables.create()
        }
    }
    
    /// Retrieves the data of the most recent recording.
    /// - Returns: An Observable emitting the recording data, or an error if the file is missing.
    func getRecordingData() -> Observable<Data> {
        guard let url = currentRecordingURL, FileManager.default.fileExists(atPath: url.path) else {
            return Observable.error(NSError(domain: "AudioService", code: -1,
                                           userInfo: [NSLocalizedDescriptionKey: "Recording file missing"]))
        }
        
        do {
            let data = try Data(contentsOf: url)
            #if DEBUG
            print("✅ Successfully read \(data.count) bytes from recording")
            #endif
            return Observable.just(data)
        } catch {
            return Observable.error(error)
        }
    }
    
    /// Starts playback of the most recent recording.
    /// - Returns: An Observable emitting `true` if playback starts successfully, or an error if it fails.
    // In AudioService.swift
    func startPlayback() -> Observable<Bool> {
        return Observable.create { [weak self] observer in
            guard let self = self, let url = self.currentRecordingURL else {
                observer.onError(NSError(domain: "AudioService", code: -1,
                    userInfo: [NSLocalizedDescriptionKey: "No recording URL available"]))
                return Disposables.create()
            }
            
            // First check if file exists
            if !FileManager.default.fileExists(atPath: url.path) {
                print("❌ Audio file not found at path: \(url.path)")
                observer.onError(NSError(domain: "AudioService", code: -1,
                    userInfo: [NSLocalizedDescriptionKey: "Audio file not found"]))
                return Disposables.create()
            }
            
            // Check file size
            do {
                let attributes = try FileManager.default.attributesOfItem(atPath: url.path)
                if let size = attributes[.size] as? Int {
                    print("📁 Audio file size for playback: \(size) bytes")
                    if size < 1000 {  // Arbitrary small size check
                        print("⚠️ Warning: Audio file is very small, may not contain valid audio")
                    }
                }
            } catch {
                print("⚠️ Unable to check audio file attributes: \(error)")
            }
            
            DispatchQueue.main.async {
                do {
                    // Configure audio session for playback - don't deactivate first
                    let audioSession = AVAudioSession.sharedInstance()
                    try audioSession.setCategory(.playback, mode: .default)
                    
                    // Force output to speaker - important for device playback
                    try audioSession.overrideOutputAudioPort(.speaker)
                    try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
                    
                    print("✅ Audio session configured for playback")
                    
                    // Create the audio player
                    self.audioPlayer = try AVAudioPlayer(contentsOf: url)
                    guard let player = self.audioPlayer else {
                        throw NSError(domain: "AudioService", code: -1,
                            userInfo: [NSLocalizedDescriptionKey: "Failed to create audio player"])
                    }
                    
                    // Configure the player
                    player.delegate = self
                    player.volume = 1.0
                    
                    print("ℹ️ Created player: duration=\(player.duration)s, format=\(player.format)")
                    
                    // Prepare and play
                    if player.prepareToPlay() {
                        let playing = player.play()
                        print("▶️ Playback \(playing ? "started" : "failed")")
                        
                        observer.onNext(playing)
                        observer.onCompleted()
                    } else {
                        let error = NSError(domain: "AudioService", code: -1,
                            userInfo: [NSLocalizedDescriptionKey: "Failed to prepare audio for playback"])
                        print("❌ \(error.localizedDescription)")
                        observer.onError(error)
                    }
                } catch {
                    print("❌ Playback error: \(error.localizedDescription)")
                    observer.onError(error)
                }
            }
            
            return Disposables.create {
                self.audioPlayer?.stop()
                self.audioPlayer = nil
                
                // Do not deactivate audio session when disposing,
                // as it might interfere with other audio operations
            }
        }
    }
    
    /// Stops the current playback.
    func stopPlayback() {
        audioPlayer?.stop()
        audioPlayer = nil
        try? AVAudioSession.sharedInstance().setActive(false)
    }
    
    /// Gets the current playback time in seconds.
    func getCurrentPlaybackTime() -> TimeInterval {
        return audioPlayer?.currentTime ?? 0
    }
    
    /// Checks if audio is currently playing.
    func isPlaying() -> Bool {
        return audioPlayer?.isPlaying ?? false
    }
    
    /// Sets a delegate to receive playback events.
    func setPlaybackDelegate(_ delegate: AVAudioPlayerDelegate) {
        playbackDelegate = delegate
        audioPlayer?.delegate = delegate
    }
    
    // MARK: - Private Helpers
    private func setupRecording(duration: TimeInterval?) -> Observable<Bool> {
        return Observable.create { [weak self] observer in
            guard let self = self, let url = self.currentRecordingURL else {
                observer.onError(NSError(domain: "AudioService", code: -1,
                                        userInfo: [NSLocalizedDescriptionKey: "Invalid URL"]))
                return Disposables.create()
            }
            
            do {
                try self.setupAudioSession()
                
                if FileManager.default.fileExists(atPath: url.path) {
                    try FileManager.default.removeItem(at: url)
                }
                
                print("📊 Audio settings: \(self.audioSettings)")
                
                self.audioRecorder = try AVAudioRecorder(url: url, settings: self.audioSettings)
                self.audioRecorder?.delegate = self
                self.audioRecorder?.isMeteringEnabled = true
                self.audioRecorder?.prepareToRecord()
                
                // Store recording start time
                self.recordingStartTime = Date()
                
                // Start recording
                if let duration = duration {
                    self.audioRecorder?.record(forDuration: duration)
                    print("⏺️ Recording started with duration limit of \(duration) seconds")
                } else {
                    self.audioRecorder?.record()
                    print("⏺️ Recording started without duration limit")
                }
                
                // Setup audio level monitoring
                self.startAudioMonitoring()
                
                observer.onNext(true)
                observer.onCompleted()
            } catch {
                print("❌ Error setting up recording: \(error.localizedDescription)")
                observer.onError(error)
            }
            
            return Disposables.create {
                self.audioRecorder?.stop()
                try? AVAudioSession.sharedInstance().setActive(false)
            }
        }
    }
    
    private func startAudioMonitoring() {
        Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] timer in
            guard let self = self, let recorder = self.audioRecorder, recorder.isRecording else {
                timer.invalidate()
                return
            }
            
            recorder.updateMeters()
            let averagePower = recorder.averagePower(forChannel: 0)
            let peakPower = recorder.peakPower(forChannel: 0)
            print("🎤 Microphone levels - Avg: \(averagePower) dB, Peak: \(peakPower) dB")
            
            if let startTime = self.recordingStartTime {
                let currentDuration = Date().timeIntervalSince(startTime)
                print("⏱️ Current recording duration: \(currentDuration) seconds")
            }
        }
    }
    
    private func logRecordingStats(url: URL) {
        #if DEBUG
        do {
            let attributes = try FileManager.default.attributesOfItem(atPath: url.path)
            if let size = attributes[.size] as? Int {
                print("📁 Recording file size: \(size) bytes")
            }
            
            // Log information about settings rather than unavailable recorder properties
            if let sampleRate = audioSettings[AVSampleRateKey] as? Double {
                print("📊 Sample rate: \(sampleRate) Hz")
            }
            if let channels = audioSettings[AVNumberOfChannelsKey] as? Int {
                print("📊 Channels: \(channels)")
            }
            if let formatKey = audioSettings[AVFormatIDKey] as? Int {
                print("📊 Format ID: \(formatKey)")
            }
        } catch {
            print("⚠️ Error getting file attributes: \(error)")
        }
        #endif
    }
    
    func setupAudioSession() throws {
        let audioSession = AVAudioSession.sharedInstance()
        try audioSession.setCategory(.playAndRecord, mode: .spokenAudio, options: [.defaultToSpeaker, .allowBluetooth])
        try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
        print("✅ Audio session activated with category: \(audioSession.category), mode: \(audioSession.mode)")
    }
    
    private func setupPlaybackSession() throws {
        let audioSession = AVAudioSession.sharedInstance()
        try audioSession.setCategory(.playback, mode: .default, options: [.duckOthers])
        try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
    }
    
    private func requestPermissions() -> Observable<Bool> {
        return Observable.create { observer in
            if #available(iOS 17.0, *) {
                AVAudioApplication.requestRecordPermission { granted in
                    print("🎤 Microphone permission granted: \(granted)")
                    observer.onNext(granted)
                    observer.onCompleted()
                }
            } else {
                AVAudioSession.sharedInstance().requestRecordPermission { granted in
                    print("🎤 Microphone permission granted: \(granted)")
                    observer.onNext(granted)
                    observer.onCompleted()
                }
            }
            return Disposables.create()
        }
    }
    
    // MARK: - AVAudioRecorderDelegate Methods
    func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
        print("🎬 Recording finished, success: \(flag), duration: \(recorder.currentTime)")
    }
    
    func audioRecorderEncodeErrorDidOccur(_ recorder: AVAudioRecorder, error: Error?) {
        print("❌ Recording error: \(String(describing: error))")
    }
}

// MARK: - AVAudioPlayerDelegate
extension AudioService: AVAudioPlayerDelegate {
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        playbackDelegate?.audioPlayerDidFinishPlaying?(player, successfully: flag)
        try? AVAudioSession.sharedInstance().setActive(false)
    }
    
    func audioPlayerDecodeErrorDidOccur(_ player: AVAudioPlayer, error: Error?) {
        playbackDelegate?.audioPlayerDecodeErrorDidOccur?(player, error: error)
    }
    
    func getTestAudioData() -> Observable<Data> {
        return Observable.create { observer in
            if let audioPath = Bundle.main.path(forResource: "test_audio", ofType: "wav") {
                do {
                    let audioData = try Data(contentsOf: URL(fileURLWithPath: audioPath))
                    print("✅ Test audio file loaded: \(audioData.count) bytes")
                    observer.onNext(audioData)
                    observer.onCompleted()
                } catch {
                    observer.onError(error)
                }
            } else {
                observer.onError(NSError(domain: "TestAudio", code: -1,
                    userInfo: [NSLocalizedDescriptionKey: "Test audio file not found"]))
            }
            return Disposables.create()
        }
    }
    
    // Add this to your AudioService class for testing
    func verifyRecordingPlayable() -> Observable<String> {
        return Observable.create { [weak self] observer in
            guard let self = self, let url = self.currentRecordingURL else {
                observer.onNext("No recording URL available")
                observer.onCompleted()
                return Disposables.create()
            }
            
            if !FileManager.default.fileExists(atPath: url.path) {
                observer.onNext("Recording file doesn't exist at path: \(url.path)")
                observer.onCompleted()
                return Disposables.create()
            }
            
            do {
                let data = try Data(contentsOf: url)
                var message = "File size: \(data.count) bytes\n"
                
                // Try creating player without configuring session
                do {
                    let player = try AVAudioPlayer(contentsOf: url)
                    message += "Player created successfully\n"
                    message += "Duration: \(player.duration) seconds\n"
                    message += "Format: \(player.format.description)\n"
                    
                    // See if we can prepare to play
                    if player.prepareToPlay() {
                        message += "Prepare to play succeeded\n"
                    } else {
                        message += "Prepare to play failed\n"
                    }
                } catch {
                    message += "Failed to create player: \(error.localizedDescription)\n"
                }
                
                observer.onNext(message)
                observer.onCompleted()
            } catch {
                observer.onNext("Error reading file: \(error.localizedDescription)")
                observer.onCompleted()
            }
            
            return Disposables.create()
        }
    }
    
    func getCurrentRecordingURL() -> URL? {
        return currentRecordingURL
    }
}
