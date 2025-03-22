//
//  DependencyInjection.swift
//  Speech Transcriber
//
//  Created by Joshua Cleetus on 3/21/25.
//

import Foundation

// A simple dependency container for the app
class DependencyContainer {
    // Singleton instance
    static let shared = DependencyContainer()
    
    private init() {
        // Private initializer to enforce singleton
    }
    
    // MARK: - Services
    
    lazy var apiClient: APIClient = {
        return APIClient()
    }()
    
    lazy var audioService: AudioService = {
        return AudioService()
    }()
    
    lazy var googleSpeechService: GoogleSpeechService = {
        return GoogleSpeechService(
            apiKey: "AIzaSyBPy-YA6a0x755OcYDiNHejHIyxeA4E1pY",
            apiClient: apiClient
        )
    }()
    
    // MARK: - Repositories
    
    lazy var audioRepository: IAudioRepository = {
        return AudioRepository(audioService: audioService)
    }()
    
    lazy var speechRepository: ISpeechRecognitionRepository = {
        return GoogleSpeechRepository(googleSpeechService: googleSpeechService)
    }()
    
    // MARK: - Use Cases
    
    lazy var recordAudioUseCase: IRecordAudioUseCase = {
        return RecordAudioUseCase(audioRepository: audioRepository)
    }()
    
    lazy var transcribeAudioUseCase: ITranscribeAudioUseCase = {
        return TranscribeAudioUseCase(speechRepository: speechRepository)
    }()
    
    lazy var playbackAudioUseCase: IPlaybackAudioUseCase = {
        return PlaybackAudioUseCase(audioRepository: audioRepository)
    }()
    
    // MARK: - View Models
    
    func makeTranscriptionViewModel() -> TranscriptionViewModel {
        return TranscriptionViewModel(
            recordAudioUseCase: recordAudioUseCase,
            transcribeAudioUseCase: transcribeAudioUseCase,
            playbackAudioUseCase: playbackAudioUseCase
        )
    }
}
