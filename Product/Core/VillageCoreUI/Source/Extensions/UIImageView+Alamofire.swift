//
//  UIImageView+Alamofire.swift
//  VillageCoreUI
//
//  Created by Sasho Jadrovski on 10/26/20.
//  Copyright © 2020 Dynamit. All rights reserved.
//

import Alamofire
import AlamofireImage

extension UIImageView {
    func vlg_setImage(
        withURL url: URL,
        placeholderImage: UIImage? = nil,
        filter: ImageFilter? = nil,
        progress: ImageDownloader.ProgressHandler? = nil,
        progressQueue: DispatchQueue = DispatchQueue.main,
        imageTransition: ImageTransition = .noTransition,
        runImageTransitionIfCached: Bool = false,
        completion: ((DataResponse<UIImage>) -> Void)? = nil
    ) {
        var urlRequest = URLRequest(url: url)
        let cookieHeaders = HTTPCookieStorage.shared.cookies.map(HTTPCookie.requestHeaderFields)
        urlRequest.allHTTPHeaderFields = cookieHeaders
        af_setImage(
            withURLRequest: urlRequest,
            placeholderImage: placeholderImage,
            filter: filter,
            progress: progress,
            progressQueue: progressQueue,
            imageTransition: imageTransition,
            runImageTransitionIfCached: runImageTransitionIfCached,
            completion: completion
        )
    }
}
