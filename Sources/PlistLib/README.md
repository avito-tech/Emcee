#  PlistLib

Class `Plist` provides a little DSL around the property lists, avoiding you to query it without casting it to `NSArray` or `NSDictionary` and dealing with casting of leaf values and optionality.
This class also allows you to compose the plist:

## Creating Plist

```swift
let plist = Plist(rootPlistEntry: .array([
    .string("first object in array"),
    .dict(["key": .bool(true)])
]))
```

For convenience, `array` and `dict` entries accept optional values, which will be ommited when actual Plist data will be generated:

```
.dict([
    "key": .bool(true),
    "optional_key": nil,
])
```

## Querying Plist

Basic query:

```swift
try plist.root.plistEntry.entry(atIndex: 0).stringValue()  // "first object in array"

try plist.root.plistEntry.entry(atIndex: 1).entry(forKey: "key").boolValue()  // true

try plist.root.plistEntry.dataValue()  // throws an error, because plist entry is array.
```

If you want to cast array to a Swift generic Array:

```
let plist = Plist(rootPlistEntry: .array([
    .string("first object"),
    .string("second object"),
]))

let array = try plist.root.plistEntry.typedArray(String.self)  // ["first object", "second object"] 
```

Same for dicts:

```
let plist = Plist(rootPlistEntry: .dict([
    "key": .string("value"),
    "another_key": .string("one more"),
]))

let dict = try plist.root.plistEntry.typedDict(String.self)  // [key" : "value", "another_key" : "one more"] 
```
