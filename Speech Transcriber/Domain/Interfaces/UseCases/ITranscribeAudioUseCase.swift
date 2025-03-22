//
//  ITranscribeAudioUseCase.swift
//  Speech Transcriber
//
//  Created by Joshua Cleetus on 3/21/25.
//

import Foundation
import RxSwift

protocol ITranscribeAudioUseCase {
    func execute(audioData: Data, sampleRate: Int) -> Observable<[TranscribedWord]>
}
