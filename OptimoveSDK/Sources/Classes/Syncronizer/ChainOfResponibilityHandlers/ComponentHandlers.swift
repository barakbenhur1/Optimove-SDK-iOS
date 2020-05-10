//  Copyright © 2019 Optimove. All rights reserved.

import Foundation
import OptimoveCore

class ComponentHandler: Node {
    private let commonComponents: [CommonComponent]
    private let optistreamComponents: [OptistreamComponent]
    private let optirstreamEventBuilder: OptistreamEventBuilder

    init(commonComponents: [CommonComponent],
         optistreamComponents: [OptistreamComponent],
         optirstreamEventBuilder: OptistreamEventBuilder
    ) {
        self.commonComponents = commonComponents
        self.optistreamComponents = optistreamComponents
        self.optirstreamEventBuilder = optirstreamEventBuilder
    }

    override func execute(_ operation: Operation) throws {
        sendToCommonComponents(operation)
        sendToStreamComponents(operation)
    }

    private func sendToCommonComponents(_ operation: Operation) {
        commonComponents.forEach { component in
            tryCatch {
                try component.handle(operation)
            }
        }
    }

    private func sendToStreamComponents(_ operation: Operation) {
        switch operation {
        case .report(events: let events):
            let streamEvents: [OptistreamEvent] = events.compactMap { event in
                do {
                   return try optirstreamEventBuilder.build(event: event)
                } catch {
                    Logger.error(error.localizedDescription)
                    return nil
                }
            }
            optistreamComponents.forEach { (component) in
                tryCatch {
                    try component.handle(.report(events: streamEvents))
                }
            }
        case .dispatchNow:
            optistreamComponents.forEach { (component) in
                tryCatch {
                    try component.handle(.dispatchNow)
                }
            }
        default:
            break
        }
    }
}

//final class OptistreamEventComponentDecider {
//
//    private let configuration: Configuration
//
//    init(configuration: Configuration) {
//        self.configuration = configuration
//    }
//
//    func isAllowToPassEvent(_ event: Event, to component: OptistreamComponentType) -> Bool {
//        switch component {
//        case .realtime:
//            return configuration.isEnableRealtime && !configuration.optitrack.isEnableRealtimeThroughOptistream &&
//                event.isRealtime
//        case .track:
//            return true
//        }
//    }
//
//}
