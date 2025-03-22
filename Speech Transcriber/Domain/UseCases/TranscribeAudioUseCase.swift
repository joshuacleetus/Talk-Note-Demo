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
    
    func execute(audioData: Data, sampleRate: Int = 44100) -> Observable<[TranscribedWord]> {
        return speechRepository.recognizeSpeech(fromAudioData: audioData, sampleRate: sampleRate)
    }
}
