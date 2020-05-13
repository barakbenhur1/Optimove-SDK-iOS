//  Copyright © 2019 Optimove. All rights reserved.

import Foundation
@testable import OptimoveCore

final class StubEvent: Event {

    struct Constnats {
        static let id = 2_000
        static let name = "stub_name"
        static let key = "stub_key"
        static let value = "stub_value"
    }

    init() {
        super.init(name: Constnats.name, context: [
            Constnats.key: Constnats.value
        ])
    }

}

public let StubOptistreamEvent = OptistreamEvent(
    uuid: UUID(),
    tenant: StubVariables.tenantID,
    category: "test",
    event: "stub",
    origin: "sdk",
    customer: nil,
    visitor: StubVariables.initialVisitorId,
    timestamp: Date(),
    context: [],
    metadata: OptistreamEvent.Metadata(channel: nil, realtime: true)
)
