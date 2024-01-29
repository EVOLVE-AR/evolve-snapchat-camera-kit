//  Copyright Snap Inc. All rights reserved.
//  CameraKitSample

import Foundation
import SCSDKCameraKit

// Example implementation of [LensRemoteApiService] which receives requests from lenses that use the
// [Remote Service Module](https://docs.snap.com/lens-studio/references/guides/lens-features/remote-apis/remote-service-module)
// feature. The remote API spec ID is provided for demo and testing purposes -
// CameraKit user applications are expected to define their own specs for any remote API that they are interested to
// communicate with. Please reach out to CameraKit support team at https://docs.snap.com/snap-kit/support
// to find out more on how to define and use this feature.
class NFTRemoteApiServiceProvider: NSObject, LensRemoteApiServiceProvider {

    var supportedApiSpecIds: Set<String> = ["dc5d8c50-2b26-428e-9193-76d43c68f0c1", "f087b118-6c8a-4a2d-9691-ffd0009d8ab3", "738e0ff8-b94d-48d1-8ab4-4e2693baae64"]

    func remoteApiService(for lens: Lens) -> LensRemoteApiService {
        return NFTRemoteApiService()
    }
}

class NFTRemoteApiService: NSObject, LensRemoteApiService {

    private enum Constants {
        static let scheme = "https"
        static let host = "evolve-test-app.herokuapp.com"
    }

    private let urlSession: URLSession = .shared

    func processRequest(
        _ request: LensRemoteApiRequest,
        responseHandler: @escaping (LensRemoteApiServiceCallStatus, LensRemoteApiResponseProtocol) -> Void
    ) -> LensRemoteApiServiceCall {
        guard let url = url(request: request) else {
            return IgnoredRemoteApiServiceCall()
        }

        let task = urlSession.dataTask(with: url) { data, urlResponse, error in
            let apiResponse = LensRemoteApiResponse(
                request: request,
                status: error != nil ? .badRequest : .success,
                metadata: [:],
                body: data)

            responseHandler(.answered, apiResponse)
        }

        task.resume()

        return URLRequestRemoteApiServiceCall(task: task)
    }

    private func url(request: LensRemoteApiRequest) -> URL? {
        var components = URLComponents()
        components.host = Constants.host
      
      if (request.endpointId == "get_image") {
        components.path = "/image"
      } else {
        components.path = "/image/3d"
      }
        components.scheme = Constants.scheme
      let parameters = request.parameters
      var queryItems = [URLQueryItem]()
      for (key,value) in parameters {
        queryItems.append(URLQueryItem(name: key, value: value))
      }
      components.queryItems = queryItems
        return components.url
    }

}

class URLRequestRemoteApiServiceCall: NSObject, LensRemoteApiServiceCall {

    let task: URLSessionDataTask

    let status: LensRemoteApiServiceCallStatus = .ongoing

    init(task: URLSessionDataTask) {
        self.task = task
        super.init()
    }

    func cancelRequest() {
        task.cancel()
    }

}

class IgnoredRemoteApiServiceCall: NSObject, LensRemoteApiServiceCall {
    let status: LensRemoteApiServiceCallStatus = .ignored

    func cancelRequest() {
        // no-op
    }
}
