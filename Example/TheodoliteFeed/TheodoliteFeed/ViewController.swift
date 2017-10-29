//
//  ViewController.swift
//  TheodoliteFeed
//
//  Created by Oliver Rickard on 10/28/17.
//  Copyright © 2017 Oliver Rickard. All rights reserved.
//

import UIKit

import Theodolite

struct Item {
  let string: String
}

final class TestItemHeader: TypedComponent {
  typealias PropType = String
  
  func render() -> [Component] {
    return [
      LabelComponent {
        (self.props(),
         LabelComponent.Options(textColor: UIColor.yellow,
                                isMultiline: true))
      }
    ]
  }
}

final class TestItemContent: TypedComponent {
  typealias PropType = String
  
  func render() -> [Component] {
    return [
      LabelComponent {
        (self.props(),
         LabelComponent.Options(textColor: UIColor.blue,
                                isMultiline: true))
      }
    ]
  }
}

final class TestItemFooter: TypedComponent {
  typealias PropType = String
  
  func render() -> [Component] {
    return [
      InsetComponent {(
        insets: UIEdgeInsets(top: 0, left: 0, bottom: 20, right: 0),
        component:
        LabelComponent {
          (self.props(),
           LabelComponent.Options(textColor: UIColor.red,
                                  isMultiline: true))
      })}
    ]
  }
}

final class TestItem: TypedComponent {
  typealias PropType = String
  typealias StateType = String
  
  func handler(gesture: UITapGestureRecognizer) {
    print("yay! props: \(self.props())")
    self.updateState(state: self.state() != nil ? nil : "Tapped!!!")
  }
  
  func render() -> [Component] {
    return [
      TapComponent {(
        action: Handler(self, TestItem.handler),
        component:
        FlexboxComponent {
          (options: FlexOptions(
            flexDirection: .column
            ),
           children:[
            FlexChild(TestItemHeader { self.state() ?? self.props() }),
            FlexChild(TestItemContent { self.state() ?? self.props() }),
            FlexChild(TestItemFooter { self.state() ?? self.props() })
            ]
          )}
        )}
    ]
  }
}

final class TestBatchComponent: TypedComponent {
  typealias PropType = Void?
  
  func render() -> [Component] {
    return [
      FlexboxComponent {
        (options: FlexOptions(
          flexDirection: .column
          ),
         children:
          (1...10)
            .map {(num: Int) -> FlexChild in
              return FlexChild(TestItem(key: num) { "Hello world" })
        })
      }
    ]
  }
}

final class TestChunkComponent: TypedComponent {
  typealias PropType = Void?
  
  func render() -> [Component] {
    return [
      FlexboxComponent {
        (options: FlexOptions(
          flexDirection: .column
          ),
         children:
          (1...10)
            .map {(num: Int) -> FlexChild in
              return FlexChild(TestBatchComponent(key: num) { nil })
        })
      }
    ]
  }
}

final class TestComponent: TypedComponent {
  typealias PropType = Void?
  
  func render() -> [Component] {
    return [
      ScrollComponent {
        (FlexboxComponent {
          (options: FlexOptions(
            flexDirection: .column
            ),
           children:
            (1...10)
              .map {(num: Int) -> FlexChild in
                return FlexChild(TestChunkComponent(key: num) { nil })
          })},
         direction: .vertical,
         attributes: [])
      }
    ]
  }
}

class ViewController: UIViewController {
  
  override func loadView() {
    let hostingView = ComponentHostingView { () -> Component in
      return TestComponent {nil}
    }
    hostingView.backgroundColor = .white
    
    self.view = hostingView
  }

  override func viewDidLoad() {
    super.viewDidLoad()
  }

  override func didReceiveMemoryWarning() {
    super.didReceiveMemoryWarning()
    // Dispose of any resources that can be recreated.
  }
}

