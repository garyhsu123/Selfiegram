//
//  DataLoadingTests.swift
//  SelfiegramTests
//
//  Created by Yu-Chun Hsu on 2020/9/16.
//  Copyright © 2020 Yu-Chun Hsu. All rights reserved.
//

import XCTest
@testable import Selfiegram

class DataLoadingTests: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
        
        let cacheURL = OverlayManager.cacheDirectoryURL
        
        guard let contents = try? FileManager.default.contentsOfDirectory(at: cacheURL, includingPropertiesForKeys: nil, options: []) else {
            XCTFail("Failed to list contents of directory \(cacheURL)")
            return
        }
        
        var complete = true
        
        for file in contents {
            do {
                try FileManager.default.removeItem(at: file)
            } catch let error {
                NSLog("Test setup: failed to remove item \(file); \(error)")
                complete = false
            }
        }
        if !complete {
            XCTFail("Failed to delete contents of cache")
        }
        
    }

    func testNoOverlaysAvailable()
    {
        let availableOverlays = OverlayManager.shared.availableOverlays()
        
        XCTAssertEqual(availableOverlays.count, 0)
    }
    
    func testgettingOverlayInfo()
    {
        // Arrange
        let expectation = self.expectation(description: "Done downloading")
        // Act
        
        var loadedInfo : OverlayManager.OverlayList?
        var loadedError: Error?
        OverlayManager.shared.refreshOverlays { (info, error) in
            loadedInfo = info
            loadedError = error
            
            expectation.fulfill()
        }
        
        waitForExpectations(timeout: 5.0, handler: nil)
        // Assert
        XCTAssertNotNil(loadedInfo)
        XCTAssertNil(loadedError)
    }
    
    func testDownlaodingOverlays()
    {
        let loadingComplete = self.expectation(description: "Downlaod done")
        var availableOverlays : [Overlay] = []
        
        OverlayManager.shared.loadOverlayAssets(refresh: true) {
            availableOverlays = OverlayManager.shared.availableOverlays()
            loadingComplete.fulfill()
        }
        
        waitForExpectations(timeout: 10.0, handler: nil)
        
        XCTAssertNotEqual(availableOverlays.count, 0)
    }
    
    func testDownloadedOverlaysAreCached()
    {
        let downloadingOverlayManager = OverlayManager()
        let downloadedExpectation = self.expectation(description: "Data downloaded")
        
        downloadingOverlayManager.loadOverlayAssets(refresh: true) {
            downloadedExpectation.fulfill()
        }
        
        waitForExpectations(timeout: 10.0, handler: nil)
        
        let cacheTestOverlayManager = OverlayManager()
        XCTAssertNotEqual(cacheTestOverlayManager.availableOverlays().count, 0)
        XCTAssertEqual(cacheTestOverlayManager.availableOverlays().count, downloadingOverlayManager.availableOverlays().count)
    }
    
    
    
    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testExample() throws {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
    }

    func testPerformanceExample() throws {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }

}
