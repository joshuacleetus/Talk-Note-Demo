//
//  TranscriptionViewModel.swift
//  Speech Transcriber
//
//  Created by Joshua Cleetus on 3/21/25.
//

import Foundation
import RxSwift
import RxCocoa
import Combine
import SwiftUI
import AVFoundation
import MediaPlayer
import AudioToolbox

class TranscriptionViewModel: NSObject, ObservableObject, AVAudioPlayerDelegate {
    // MARK: - Published properties (for SwiftUI)
    @Published var transcriptionText: String = ""
    @Published var recordingState: RecordingState = .idle
    @Published var highlightedWordIndex: Int? = nil
    
    // MARK: - Private RxSwift properties
    private let transcribedWords = BehaviorRelay<[TranscribedWord]>(value: [])
    private let disposeBag = DisposeBag()
    private var playbackTimer: Timer?
    
    // MARK: - Use cases
    private let recordAudioUseCase: IRecordAudioUseCase
    private let transcribeAudioUseCase: ITranscribeAudioUseCase
    private let playbackAudioUseCase: IPlaybackAudioUseCase
    private var alternativePlayer: AVAudioPlayer?
    
    init(
        recordAudioUseCase: IRecordAudioUseCase,
        transcribeAudioUseCase: ITranscribeAudioUseCase,
        playbackAudioUseCase: IPlaybackAudioUseCase
    ) {
        self.recordAudioUseCase = recordAudioUseCase
        self.transcribeAudioUseCase = transcribeAudioUseCase
        self.playbackAudioUseCase = playbackAudioUseCase
        
        // Call super.init before any other setup when inheriting from NSObject
        super.init()
        
        setupBindings()
    }
    
    // MARK: - Public methods for UI actions
    func toggleRecording() {
        switch recordingState {
        case .idle:
            startRecording()
        case .recording:
            stopRecording()
        default:
            break
        }
    }
    
    func togglePlayback() {
        switch recordingState {
        case .idle:
            if !transcribedWords.value.isEmpty {
                // Add diagnostic check before playback
                diagnosePotentialPlaybackIssues()
                startPlayback()
            }
        case .playing:
            stopPlayback()
        default:
            break
        }
    }
    
    // MARK: - Audio Diagnostic Function
    func diagnosePotentialPlaybackIssues() {
        print("🔍 STARTING AUDIO PLAYBACK DIAGNOSTICS")
        
        // Get audio service from dependency container
        let audioService = DependencyContainer.shared.audioService
        
        // Check recording file
        audioService.verifyRecordingPlayable()
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: { message in
                print("🔍 AUDIO RECORDING DIAGNOSIS:")
                print(message)
            }, onError: { error in
                print("❌ Error during diagnosis: \(error)")
            })
            .disposed(by: disposeBag)
        
        // Check audio session status
        let session = AVAudioSession.sharedInstance()
        print("🔊 AUDIO SESSION STATUS:")
        print("Category: \(session.category)")
        print("Mode: \(session.mode)")
        print("Sample Rate: \(session.sampleRate)")
        print("Output Volume: \(session.outputVolume)")
        print("Is Other Audio Playing: \(session.isOtherAudioPlaying)")
        
        // Check system volume
        let volumeView = MPVolumeView()
        if let slider = volumeView.subviews.first(where: { $0 is UISlider }) as? UISlider {
            print("System Volume: \(slider.value)")
            if slider.value < 0.1 {
                print("⚠️ WARNING: System volume is very low!")
            }
        }
        
        // Try to activate audio session with speaker
        do {
            try session.setCategory(.playback, mode: .default)
            try session.overrideOutputAudioPort(.speaker)
            try session.setActive(true, options: .notifyOthersOnDeactivation)
            print("✅ Successfully configured audio session for playback")
        } catch {
            print("❌ Failed to configure audio session: \(error)")
        }
        
        print("⚙️ Check physical device settings:")
        print("- Is device muted? (Cannot check programmatically)")
        print("- Are headphones connected?")
        print("- Is device in silent mode?")
        
        print("🔍 AUDIO DIAGNOSTICS COMPLETE")
    }
    
    // MARK: - Private methods
    private func setupBindings() {
        // Setup Rx bindings for state changes
        transcribedWords
            .map { words in
                words.map { $0.text }.joined(separator: " ")
            }
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: { [weak self] text in
                self?.transcriptionText = text
            })
            .disposed(by: disposeBag)
    }
    
    private func startRecording() {
        self.recordingState = .loading
        
        recordAudioUseCase.execute()
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: { [weak self] success in
                guard let self = self else { return }
                if success {
                    self.recordingState = .recording
                    self.transcribedWords.accept([])
                    self.transcriptionText = ""
                }
            }, onError: { [weak self] error in
                guard let self = self else { return }
                self.recordingState = .error(error.localizedDescription)
            })
            .disposed(by: disposeBag)
    }
    
    private func stopRecording() {
        self.recordingState = .loading
        
        recordAudioUseCase.stop()
            .flatMap { [weak self] _ -> Observable<Data> in
                if self == nil { return Observable.empty() }
                let audioRepository = DependencyContainer.shared.audioRepository
                return audioRepository.getRecordingData()
            }
            .do(onNext: { [weak self] _ in
                // Update state to show transcription is processing
                self?.recordingState = .processingTranscription
            })
            .flatMap { [weak self] audioData -> Observable<[TranscribedWord]> in
                guard let self = self else { return Observable.empty() }
                return self.transcribeAudioUseCase.execute(audioData: audioData, sampleRate: 22050)
            }
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: { [weak self] words in
                guard let self = self else { return }
                self.transcribedWords.accept(words)
                self.recordingState = .idle
            }, onError: { [weak self] error in
                guard let self = self else { return }
                self.recordingState = .error("Transcription failed: \(error.localizedDescription)")
            })
            .disposed(by: disposeBag)
    }
    
    private func startPlayback() {
        // First, check if we can play audio at all
        do {
            // Try deactivating first, this can solve many issues
            try AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
            
            // Create a new audio session specifically for playback
            let audioSession = AVAudioSession.sharedInstance()
            
            // This is critical - first set the category before trying to override port
            try audioSession.setCategory(.playback, options: [.duckOthers])
            
            // Then set active
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
            
            // Only then override the port - order matters!
            try audioSession.overrideOutputAudioPort(.speaker)
            
            print("✅ Playback session activated with explicit configuration")
        } catch {
            print("⚠️ Initial session setup warning (will try alternate method): \(error)")
            // Don't return - we'll try an alternate method below
        }
        
        // Continue with playback even if session setup had issues
        playbackAudioUseCase.setDelegate(self)
        playbackAudioUseCase.execute()
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: { [weak self] success in
                guard let self = self else { return }
                
                if success {
                    print("▶️ Playback started successfully")
                    self.recordingState = .playing
                    self.startWordHighlightTimer()
                    
                    // Double-check if system volume is too low and warn the user
                    if AVAudioSession.sharedInstance().outputVolume < 0.1 {
                        print("🔊 WARNING: System volume is very low, user may not hear audio")
                        // Consider showing a UI alert to the user here
                    }
                } else {
                    print("❌ Playback returned false")
                    self.recordingState = .error("Playback failed to start")
                    
                    // Try alternative playback as fallback
                    self.tryAlternativePlayback()
                }
            }, onError: { [weak self] error in
                guard let self = self else { return }
                print("❌ Playback error: \(error)")
                self.recordingState = .error("Playback failed: \(error.localizedDescription)")
                
                // Try alternative playback as fallback
                self.tryAlternativePlayback()
            })
            .disposed(by: disposeBag)
    }
    
    // Fallback method for problematic devices
    private func tryAlternativePlayback() {
        print("🔄 Attempting alternative playback method")
        
        guard let url = DependencyContainer.shared.audioRepository.getCurrentRecordingURL() else {
            print("❌ No recording URL available for alternative playback")
            return
        }
        
        // Try a direct approach with minimal configuration
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                // Reset audio session completely
                try AVAudioSession.sharedInstance().setActive(false)
                
                // Use a simpler configuration
                let session = AVAudioSession.sharedInstance()
                try session.setCategory(.playback)
                try session.setActive(true)
                
                // Create player directly
                let player = try AVAudioPlayer(contentsOf: url)
                player.delegate = self
                player.prepareToPlay()
                
                DispatchQueue.main.async {
                    if player.play() {
                        print("✅ Alternative playback started")
                        self.recordingState = .playing
                        
                        // Keep a reference to the player so it's not deallocated
                        self.alternativePlayer = player
                        
                        // Start word highlighting
                        self.startWordHighlightTimer()
                    } else {
                        print("❌ Alternative playback failed to start")
                        self.recordingState = .error("Alternative playback failed")
                    }
                }
            } catch {
                DispatchQueue.main.async {
                    print("❌ Alternative playback error: \(error)")
                    self.recordingState = .error("All playback methods failed")
                }
            }
        }
    }
    
    private func stopPlayback() {
        playbackAudioUseCase.stop()
        stopWordHighlightTimer()
        recordingState = .idle
        highlightedWordIndex = nil
    }
    
    private func startWordHighlightTimer() {
        playbackTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            guard let self = self, self.playbackAudioUseCase.isPlaying() else { return }
            
            let currentTime = self.playbackAudioUseCase.getCurrentTime()
            let words = self.transcribedWords.value
            
            for (index, word) in words.enumerated() {
                if currentTime >= word.startTime && currentTime <= word.endTime {
                    self.highlightedWordIndex = index
                    return
                }
            }
        }
    }
    
    private func stopWordHighlightTimer() {
        playbackTimer?.invalidate()
        playbackTimer = nil
    }
}

// MARK: - AVAudioPlayerDelegate
extension TranscriptionViewModel {
    @objc
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        print("🎬 Audio playback finished, success: \(flag)")
        recordingState = .idle
        highlightedWordIndex = nil
    }
    
    func testTranscriptionWithSampleAudio() {
        self.recordingState = .loading
        
        // Get sample audio and transcribe it
        let audioService = DependencyContainer.shared.audioService
        audioService.getTestAudioData()
            .flatMap { [weak self] audioData -> Observable<[TranscribedWord]> in
                guard let self = self else { return Observable.empty() }
                let speechRepository = DependencyContainer.shared.speechRepository
                if let speechRepository = speechRepository as? GoogleSpeechRepository {
                    return speechRepository.recognizeSpeech(fromAudioData: audioData, sampleRate: 44100)
                        .do(onError: { error in
                            print("⚠️ Repository error: \(error.localizedDescription)")
                            if let decodingError = error as? DecodingError {
                                print("⚠️ Decoding error details: \(decodingError)")
                            }
                        })
                } else {
                    return self.transcribeAudioUseCase.execute(audioData: audioData, sampleRate: 44100)
                }
            }
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: { [weak self] words in
                guard let self = self else { return }
                print("✅ Received \(words.count) transcribed words")
                self.transcribedWords.accept(words)
                self.recordingState = .idle
            }, onError: { [weak self] error in
                guard let self = self else { return }
                print("❌ Test transcription error: \(error)")
                self.recordingState = .error("Test transcription failed: \(error.localizedDescription)")
            })
            .disposed(by: disposeBag)
    }
    
    func playTestSound() {
        // This will play a system sound even in silent mode
        AudioServicesPlaySystemSound(1007) // Standard system sound
        
        // Also trigger vibration to confirm the function was called
        AudioServicesPlaySystemSound(kSystemSoundID_Vibrate)
        
        print("🔊 Test sound triggered")
    }
    
    // Add to your TranscriptionViewModel
    func dismissError() {
        if case .error = recordingState {
            recordingState = .idle
        }
    }
}
