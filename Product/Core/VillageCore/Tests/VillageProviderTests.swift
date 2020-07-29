//
//  VillageProviderTests.swift
//  VillageCoreTests
//
//  Created by Rob Feldmann on 2/3/19.
//  Copyright © 2019 Dynamit. All rights reserved.
//

import XCTest
@testable import VillageCore

//class VillageProviderTests: XCTestCase {
//    
//    private var xsrfToken: String?
//    
//    lazy var reAuthenticationClosure: VillageProvider<VillageCoreAPI>.ReAuthenticationClosure = {
//        return { (reason, completion) in
//            switch reason {
//            case .unauthorized:
//                let login = VillageCoreAPI.login(licenseKey: "123456", identity: "rob@dynamit.com", password: "Testing1", prefetch: nil)
//                self.provider.request(login) { result in
//                    switch result {
//                    case .success(let response):
//                        do {
//                            _ = try response.filterSuccessfulStatusCodes()
//                            completion(true)
//                        } catch {
//                            completion(false)
//                        }
//                    
//                    case .failure(let error):
//                        completion(false)
//                    }
//                }
//                
//            case .xsrfToken:
//                self.provider.request(.me, ignoreReAuthentication: true) { result in
//                    switch result {
//                    case .success(let response):
//                        do {
//                            _ = try response.filterSuccessfulStatusCodes()
//                            completion(true)
//                        } catch {
//                            completion(false)
//                        }
//                        
//                    case .failure(let error):
//                        completion(false)
//                    }
//                }
//            }
//        }
//    }()
//    
//    lazy var provider: VillageProvider<VillageCoreAPI> = {
//        return VillageProvider<VillageCoreAPI>(
//            getToken: { return self.xsrfToken },
//            setToken: { (token) in self.xsrfToken = token },
//            reAuthenticate: self.reAuthenticationClosure
//        )
//    }()
//
//    override func setUp() {
//        // Put setup code here. This method is called before the invocation of each test method in the class.
//    }
//
//    override func tearDown() {
//        // Put teardown code here. This method is called after the invocation of each test method in the class.
//    }
//    
//    func testUnauthorized() {
//        let expect = expectation(description: "#function")
//        self.provider.request(.foundationSettings(licenseKey: "123456")) { (result) in
//            switch result {
//            case .success(let response):
//                do {
//                    _ = try response.filterSuccessfulStatusCodes()
//                    XCTAssert(true)
//                } catch {
//                    XCTAssert(false, error.localizedDescription)
//                }
//            case .failure(let error):
//                XCTAssert(false, error.localizedDescription)
//            }
//            expect.fulfill()
//        }
//        wait(for: [expect], timeout: 10)
//    }
//    
//    func testAuthorizedRetry() {
//        let expect = expectation(description: "#function")
//        
//        self.provider.request(VillageCoreAPI.securityPolicies(userId: "162")) { (result) in
//            switch result {
//            case .success(let response):
//                do {
//                    _ = try response.filterSuccessfulStatusCodes()
//                    XCTAssert(true)
//                } catch {
//                    XCTAssert(false, error.localizedDescription)
//                }
//            case .failure(let error):
//                XCTAssert(false, error.localizedDescription)
//            }
//            expect.fulfill()
//        }
//        wait(for: [expect], timeout: 10)
//    }
//    
//    func testAuthorizedXSRFTokenRefresh() {
//        let expect = expectation(description: "#function")
//        
//        let login = VillageCoreAPI.login(licenseKey: "123456", identity: "rob@dynamit.com", password: "Testing1", prefetch: nil)
//        self.provider.request(login) { (result) in
//            switch result {
//            case .success(let response):
//                do {
//                    _ = try response.filterSuccessfulStatusCodes()
//                    XCTAssertNil(self.xsrfToken)
//                    self.provider.request(.myAccount) { myAccountResult in
//                        switch myAccountResult {
//                        case .success(let myAccountResponse):
//                            XCTAssert(myAccountResponse.statusCode != 403)
//                            XCTAssertNotNil(self.xsrfToken)
//                        case .failure(let error):
//                            XCTAssert(false, error.localizedDescription)
//                        }
//                        expect.fulfill()
//                    }
//                } catch {
//                    XCTAssert(false, error.localizedDescription)
//                    expect.fulfill()
//                }
//            case .failure(let error):
//                XCTAssert(false, error.localizedDescription)
//                expect.fulfill()
//            }
//        }
//        
//        wait(for: [expect], timeout: 500)
//    }
//
//    
//}
