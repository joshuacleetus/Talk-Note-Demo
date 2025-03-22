//
//  TranscribeAudioUseCase.swift
//  Speech Transcriber
//
//  Created by Joshua Cleetus on 3/21/25.
//

import Foundation
import RxSwift

class TranscribeAudioUseCase: ITranscribeAudioUseCase {
    private let speechRepository: ISpeechRecognitionRepository
    
    init(speechRepository: ISpeechRecognitionRepository) {
        self.speechRepository = speechRepository
    }
    
    func execute(audioData: Data, sampleRate: Int) -> Observable<[TranscribedWord]> {
        return speechRepository.recognizeSpeech(fromAudioData: audioData, sampleRate: sampleRate)
            .timeout(.seconds(30), scheduler: ConcurrentDispatchQueueScheduler(qos: .userInitiated))
            .catch { error -> Observable<[TranscribedWord]> in
                if error is RxError {
                    // Convert timeout to AppError
                    return Observable.error(AppError.timeout("Transcription timed out. Please try again."))
                } else {
                    // Convert other errors
                    return Observable.error(AppError.transcriptionFailed(error.localizedDescription))
                }
            }
    }
}
