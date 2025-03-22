//
//  ISpeechRecognitionRepository.swift
//  Speech Transcriber
//
//  Created by Joshua Cleetus on 3/21/25.
//

import Foundation
import RxSwift

protocol ISpeechRecognitionRepository {
    func recognizeSpeech(fromAudioData data: Data, sampleRate: Int) -> Observable<[TranscribedWord]>
}
