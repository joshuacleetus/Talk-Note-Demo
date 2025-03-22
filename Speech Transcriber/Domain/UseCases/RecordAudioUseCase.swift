//
//  RecordAudioUseCase.swift
//  Speech Transcriber
//
//  Created by Joshua Cleetus on 3/21/25.
//

import Foundation
import RxSwift

class RecordAudioUseCase: IRecordAudioUseCase {
    private let audioRepository: IAudioRepository
    
    init(audioRepository: IAudioRepository) {
        self.audioRepository = audioRepository
    }
    
    func execute() -> Observable<Bool> {
        return audioRepository.startRecording()
    }
    
    func stop() -> Observable<URL> {
        return audioRepository.stopRecording()
    }
}
