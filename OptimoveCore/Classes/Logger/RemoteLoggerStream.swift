//  Copyright © 2019 Optimove. All rights reserved.

import Foundation

final class RemoteLoggerStream: MutableLoggerStream {

    var policy: LoggerStreamPolicy = .all

    var tenantId: Int
    var endpoint: URL = Endpoints.Logger.defaultEndpint

    private let appNs: String
    private let platform: SdkPlatform = .ios

    init(tenantId: Int) {
        self.tenantId = tenantId
        self.appNs = Bundle.main.bundleIdentifier!
    }

    func log(level: LogLevel, fileName: String, methodName: String, logModule: String?, message: String) {
        let data = LogBody(
            tenantId: self.tenantId,
            appNs: self.appNs,
            sdkEnv: SDK.environment,
            sdkPlatform: platform,
            level: level,
            logModule: "",
            logFileName: fileName,
            logMethodName: methodName,
            message: message
        )
        if let request = self.buildLogRequest(data) {
            let task = URLSession.shared.dataTask(with: request) { (data, response, error) in
                // TODO: Add local logging.
            }
            task.resume()
        }
    }

    private func buildLogRequest(_ data: LogBody) -> URLRequest? {
        if let logBody = try? JSONEncoder().encode(data) {
            var request = URLRequest(url: self.endpoint)
            request.httpBody = logBody
            // FIXME: Move to local Constants.
            request.httpMethod = "POST"
            // FIXME: Move to local Constants.
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            return request
        } else {
            return nil
        }
    }
}
