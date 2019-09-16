//  Copyright © 2019 Optimove. All rights reserved.

import Foundation
import OptimoveCore

final class ParametersDecorator: EventableNode {

    private let configuration: Configuration

    init(configuration: Configuration) {
        self.configuration = configuration
    }

    override func execute(_ context: EventableOperationContext) throws {
        let decorationFunction = { [configuration] () -> EventableOperationContext in
            switch context.operation {
            case let .report(event: event):
                return EventableOperationContext(
                    .report(event:
                        OptimoveEventDecorator(
                            event: event,
                            config: try event.matchConfiguration(with: configuration.events)
                        )
                    ),
                    timestamp: context.timestamp
                )
            default:
                return context
            }
        }
        try next?.execute(decorationFunction())
    }

}
