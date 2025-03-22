//
//  IRecordAudioUseCase.swift
//  Speech Transcriber
//
//  Created by Joshua Cleetus on 3/21/25.
//

import Foundation
import RxSwift

protocol IRecordAudioUseCase {
    func execute() -> Observable<Bool>
    func stop() -> Observable<URL>
}
