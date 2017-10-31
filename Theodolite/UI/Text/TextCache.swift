//
//  TextCache.swift
//  Theodolite
//
//  Cloned from https://github.com/apple/swift-corelibs-foundation/blob/master/Foundation/NSCache.swift
//  to fix a bug in NSCache.
//

import Foundation

private class TextCacheEntry<KeyType : AnyObject, ObjectType : AnyObject> {
  var key: KeyType
  var value: ObjectType
  var cost: Int
  var prevByCost: TextCacheEntry?
  var nextByCost: TextCacheEntry?
  init(key: KeyType, value: ObjectType, cost: Int) {
    self.key = key
    self.value = value
    self.cost = cost
  }
}

fileprivate class TextCacheKey: NSObject {

  var value: AnyObject

  init(_ value: AnyObject) {
    self.value = value
    super.init()
  }

  override var hashValue: Int {
    switch self.value {
    case let nsObject as NSObject:
      return nsObject.hashValue
    case let hashable as AnyHashable:
      return hashable.hashValue
    default: return 0
    }
  }

  override func isEqual(_ object: Any?) -> Bool {
    guard let other = (object as? TextCacheKey) else { return false }

    if self.value === other.value {
      return true
    } else {
      guard let left = self.value as? NSObject,
        let right = other.value as? NSObject else { return false }

      return left.isEqual(right)
    }
  }
}

open class TextCache<KeyType : AnyObject, ObjectType : AnyObject> : NSObject {

  private var _entries = Dictionary<TextCacheKey, TextCacheEntry<KeyType, ObjectType>>()
  private let _lock = NSLock()
  private var _totalCost = 0
  private var _head: TextCacheEntry<KeyType, ObjectType>?

  open var name: String = ""
  open var totalCostLimit: Int = 0 // limits are imprecise/not strict
  open var countLimit: Int = 0 // limits are imprecise/not strict
  open var evictsObjectsWithDiscardedContent: Bool = false

  public override init() {}

  open weak var delegate: TextCacheDelegate?

  open func object(forKey key: KeyType) -> ObjectType? {
    var object: ObjectType?

    let key = TextCacheKey(key)

    _lock.lock()
    if let entry = _entries[key] {
      object = entry.value
    }
    _lock.unlock()

    return object
  }

  open func setObject(_ obj: ObjectType, forKey key: KeyType) {
    setObject(obj, forKey: key, cost: 0)
  }

  private func remove(_ entry: TextCacheEntry<KeyType, ObjectType>) {
    let oldPrev = entry.prevByCost
    let oldNext = entry.nextByCost

    oldPrev?.nextByCost = oldNext
    oldNext?.prevByCost = oldPrev

    if entry === _head {
      _head = oldNext
    }
  }

  private func insert(_ entry: TextCacheEntry<KeyType, ObjectType>) {
    guard var currentElement = _head else {
      // The cache is empty
      entry.prevByCost = nil
      entry.nextByCost = nil

      _head = entry
      return
    }

    guard entry.cost > currentElement.cost else {
      // Insert entry at the head
      entry.prevByCost = nil
      entry.nextByCost = currentElement
      currentElement.prevByCost = entry

      _head = entry
      return
    }

    while currentElement.nextByCost != nil && currentElement.nextByCost!.cost < entry.cost {
      currentElement = currentElement.nextByCost!
    }

    // Insert entry between currentElement and nextElement
    let nextElement = currentElement.nextByCost

    currentElement.nextByCost = entry
    entry.prevByCost = currentElement

    entry.nextByCost = nextElement
    nextElement?.prevByCost = entry
  }

  open func setObject(_ obj: ObjectType, forKey key: KeyType, cost g: Int) {
    let g = max(g, 0)
    let keyRef = TextCacheKey(key)

    _lock.lock()

    let costDiff: Int

    if let entry = _entries[keyRef] {
      costDiff = g - entry.cost
      entry.cost = g

      entry.value = obj

      if costDiff != 0 {
        remove(entry)
        insert(entry)
      }
    } else {
      let entry = TextCacheEntry(key: key, value: obj, cost: g)
      _entries[keyRef] = entry
      insert(entry)

      costDiff = g
    }

    _totalCost += costDiff

    var purgeAmount = (totalCostLimit > 0) ? (_totalCost - totalCostLimit) : 0
    while purgeAmount > 0 {
      if let entry = _head {
        delegate?.cache(unsafeDowncast(self, to:TextCache<AnyObject, AnyObject>.self), willEvictObject: entry.value)

        _totalCost -= entry.cost
        purgeAmount -= entry.cost

        remove(entry) // _head will be changed to next entry in remove(_:)
        _entries[TextCacheKey(entry.key)] = nil
      } else {
        break
      }
    }

    var purgeCount = (countLimit > 0) ? (_entries.count - countLimit) : 0
    while purgeCount > 0 {
      if let entry = _head {
        delegate?.cache(unsafeDowncast(self, to:TextCache<AnyObject, AnyObject>.self), willEvictObject: entry.value)

        _totalCost -= entry.cost
        purgeCount -= 1

        remove(entry) // _head will be changed to next entry in remove(_:)
        _entries[TextCacheKey(entry.key)] = nil
      } else {
        break
      }
    }

    _lock.unlock()
  }

  open func removeObject(forKey key: KeyType) {
    let keyRef = TextCacheKey(key)

    _lock.lock()
    if let entry = _entries.removeValue(forKey: keyRef) {
      _totalCost -= entry.cost
      remove(entry)
    }
    _lock.unlock()
  }

  open func removeAllObjects() {
    _lock.lock()
    _entries.removeAll()

    while let currentElement = _head {
      let nextElement = currentElement.nextByCost

      currentElement.prevByCost = nil
      currentElement.nextByCost = nil

      _head = nextElement
    }

    _totalCost = 0
    _lock.unlock()
  }
}

public protocol TextCacheDelegate : NSObjectProtocol {
  func cache(_ cache: TextCache<AnyObject, AnyObject>, willEvictObject obj: Any)
}

extension TextCacheDelegate {
  func cache(_ cache: TextCache<AnyObject, AnyObject>, willEvictObject obj: Any) {
    // Default implementation does nothing
  }
}
