//
//  InsetComponentSnapshotTests.swift
//  TheodoliteTests
//
//  Created by Oliver Rickard on 10/28/17.
//  Copyright © 2017 Oliver Rickard. All rights reserved.
//

import FBSnapshotTestCase
import Flexbox
@testable import Theodolite

class LabelComponentSnapshotTests: FBSnapshotTestCase {
  override func setUp() {
    super.setUp()
    recordMode = false
  }
  
  func test_singleString() {
    snapshotTestComponent(self, CGSize(width: 100, height: 100), #function) {() -> Component in
      return LabelComponent {
        ("hello",
         LabelComponent.Options())
      }
    }
  }
}

