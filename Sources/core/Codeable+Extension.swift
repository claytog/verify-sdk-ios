//
// Copyright contributors to the IBM Security Verify Core SDK for iOS project
//

import Foundation

/// A structure that provides suport for the `Codable` protocol based an the `Any` type.
/// - SeeAlso: ``AnyEncodable``
/// - SeeAlso: ``AnyDecodable``
@frozen public struct AnyCodable: Codable {
    /// The value of an `Codable` type.
    public let value: Any

    /// Initialize the structure with a given type.
    /// - Parameters:
    ///   - value: An optional value of a `Codable` type.
    public init<T>(_ value: T?) {
        self.value = value ?? ()
    }
}

// MARK: AnyCodable Extensions

extension AnyCodable: _AnyEncodable, _AnyDecodable {
}

extension AnyCodable: Equatable {
    public static func == (lhs: AnyCodable, rhs: AnyCodable) -> Bool {
        switch (lhs.value, rhs.value) {
        case is (Void, Void):
            return true
        case let (lhs as Bool, rhs as Bool):
            return lhs == rhs
        case let (lhs as Int, rhs as Int):
            return lhs == rhs
        case let (lhs as Int8, rhs as Int8):
            return lhs == rhs
        case let (lhs as Int16, rhs as Int16):
            return lhs == rhs
        case let (lhs as Int32, rhs as Int32):
            return lhs == rhs
        case let (lhs as Int64, rhs as Int64):
            return lhs == rhs
        case let (lhs as UInt, rhs as UInt):
            return lhs == rhs
        case let (lhs as UInt8, rhs as UInt8):
            return lhs == rhs
        case let (lhs as UInt16, rhs as UInt16):
            return lhs == rhs
        case let (lhs as UInt32, rhs as UInt32):
            return lhs == rhs
        case let (lhs as UInt64, rhs as UInt64):
            return lhs == rhs
        case let (lhs as Float, rhs as Float):
            return lhs == rhs
        case let (lhs as Double, rhs as Double):
            return lhs == rhs
        case let (lhs as String, rhs as String):
            return lhs == rhs
        case let (lhs as [String: AnyCodable], rhs as [String: AnyCodable]):
            return lhs == rhs
        case let (lhs as [AnyCodable], rhs as [AnyCodable]):
            return lhs == rhs
        case let (lhs as [String: Any], rhs as [String: Any]):
            return NSDictionary(dictionary: lhs) == NSDictionary(dictionary: rhs)
        case let (lhs as [Any], rhs as [Any]):
            return NSArray(array: lhs) == NSArray(array: rhs)
        case is (NSNull, NSNull):
            return true
        default:
            return false
        }
    }
}

extension AnyCodable: CustomStringConvertible {
    public var description: String {
        switch value {
        case is Void:
            return String(describing: nil as Any?)
        case let value as CustomStringConvertible:
            return value.description
        default:
            return String(describing: value)
        }
    }
}

extension AnyCodable: CustomDebugStringConvertible {
    public var debugDescription: String {
        switch value {
        case let value as CustomDebugStringConvertible:
            return "AnyCodable(\(value.debugDescription))"
        default:
            return "AnyCodable(\(description))"
        }
    }
}

extension AnyCodable: ExpressibleByNilLiteral {
}

extension AnyCodable: ExpressibleByBooleanLiteral {
}

extension AnyCodable: ExpressibleByIntegerLiteral {
}

extension AnyCodable: ExpressibleByFloatLiteral {
}

extension AnyCodable: ExpressibleByStringLiteral {
}

extension AnyCodable: ExpressibleByStringInterpolation {
}

extension AnyCodable: ExpressibleByArrayLiteral {
}

extension AnyCodable: ExpressibleByDictionaryLiteral {
}

extension AnyCodable: Hashable {
    public func hash(into hasher: inout Hasher) {
        switch value {
        case let value as Bool:
            hasher.combine(value)
        case let value as Int:
            hasher.combine(value)
        case let value as Int8:
            hasher.combine(value)
        case let value as Int16:
            hasher.combine(value)
        case let value as Int32:
            hasher.combine(value)
        case let value as Int64:
            hasher.combine(value)
        case let value as UInt:
            hasher.combine(value)
        case let value as UInt8:
            hasher.combine(value)
        case let value as UInt16:
            hasher.combine(value)
        case let value as UInt32:
            hasher.combine(value)
        case let value as UInt64:
            hasher.combine(value)
        case let value as Float:
            hasher.combine(value)
        case let value as Double:
            hasher.combine(value)
        case let value as String:
            hasher.combine(value)
        case let value as [String: AnyCodable]:
            hasher.combine(value)
        case let value as [AnyCodable]:
            hasher.combine(value)
        default:
            break
        }
    }
}

// MARK: AnyDecodable

/// A structure that provides suport for the `Decodable` protocol based an the `Any` type.
///
/// ```swift
/// let json = """
/// {
///    "boolean": true,
///    "integer": 99,
///    "double": 21.5,
///    "string": "hello world",
///    "array": [1, 2, 3],
///    "dict": {
///       "1": "tic",
///       "2": "tac",
///       "3": "toe"
///    },
///    "null": null
/// }
/// """.data(using: .utf8)!
///
/// let decoder = JSONDecoder()
/// let result = try! decoder.decode([String: AnyDecodable].self, from: json)
/// ```
@frozen public struct AnyDecodable: Decodable {
    public let value: Any

    public init<T>(_ value: T?) {
        self.value = value ?? ()
    }
}

// MARK: AnyDecoable Protocol

/// A type that can decode itself from an external representation.
@usableFromInline protocol _AnyDecodable {
    /// The value of an `Decodable` type.
    var value: Any {
        get
    }
    
    /// Creates a new decodable value usiing a placeholder type.
    /// - Parameters:
    ///   - value: An optional value of a `Decodable` type.
    init<T>(_ value: T?)
}

// MARK: AnyDecoable Extensions

extension AnyDecodable: _AnyDecodable {
}

extension _AnyDecodable {
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()

        if container.decodeNil() {
            #if canImport(Foundation)
                self.init(NSNull())
            #else
                self.init(Optional<Self>.none)
            #endif
        }
        else if let bool = try? container.decode(Bool.self) {
            self.init(bool)
        }
        else if let int = try? container.decode(Int.self) {
            self.init(int)
        }
        else if let uint = try? container.decode(UInt.self) {
            self.init(uint)
        }
        else if let double = try? container.decode(Double.self) {
            self.init(double)
        }
        else if let string = try? container.decode(String.self) {
            self.init(string)
        }
        else if let array = try? container.decode([AnyDecodable].self) {
            self.init(array.map { $0.value })
        }
        else if let dictionary = try? container.decode([String: AnyDecodable].self) {
            self.init(dictionary.mapValues { $0.value })
        }
        else {
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Unable to decode the AnyDecodable value.")
        }
    }
}

extension AnyDecodable: Equatable {
    public static func == (lhs: AnyDecodable, rhs: AnyDecodable) -> Bool {
        switch (lhs.value, rhs.value) {
        #if canImport(Foundation)
        case is (NSNull, NSNull), is (Void, Void):
            return true
        #endif
        case let (lhs as Bool, rhs as Bool):
            return lhs == rhs
        case let (lhs as Int, rhs as Int):
            return lhs == rhs
        case let (lhs as Int8, rhs as Int8):
            return lhs == rhs
        case let (lhs as Int16, rhs as Int16):
            return lhs == rhs
        case let (lhs as Int32, rhs as Int32):
            return lhs == rhs
        case let (lhs as Int64, rhs as Int64):
            return lhs == rhs
        case let (lhs as UInt, rhs as UInt):
            return lhs == rhs
        case let (lhs as UInt8, rhs as UInt8):
            return lhs == rhs
        case let (lhs as UInt16, rhs as UInt16):
            return lhs == rhs
        case let (lhs as UInt32, rhs as UInt32):
            return lhs == rhs
        case let (lhs as UInt64, rhs as UInt64):
            return lhs == rhs
        case let (lhs as Float, rhs as Float):
            return lhs == rhs
        case let (lhs as Double, rhs as Double):
            return lhs == rhs
        case let (lhs as String, rhs as String):
            return lhs == rhs
        case let (lhs as [String: AnyDecodable], rhs as [String: AnyDecodable]):
            return lhs == rhs
        case let (lhs as [String: AnyHashable], rhs as [String: AnyHashable]):
            return lhs == rhs
        case let (lhs as [AnyDecodable], rhs as [AnyDecodable]):
            return lhs == rhs
        default:
            return false
        }
    }
}

extension AnyDecodable: CustomStringConvertible {
    public var description: String {
        switch value {
        case is Void:
            return String(describing: nil as Any?)
        case let value as CustomStringConvertible:
            return value.description
        default:
            return String(describing: value)
        }
    }
}

extension AnyDecodable: CustomDebugStringConvertible {
    public var debugDescription: String {
        switch value {
        case let value as CustomDebugStringConvertible:
            return "AnyDecodable(\(value.debugDescription))"
        default:
            return "AnyDecodable(\(description))"
        }
    }
}

extension AnyDecodable: Hashable {
    public func hash(into hasher: inout Hasher) {
        switch value {
        case let value as Bool:
            hasher.combine(value)
        case let value as Int:
            hasher.combine(value)
        case let value as Int8:
            hasher.combine(value)
        case let value as Int16:
            hasher.combine(value)
        case let value as Int32:
            hasher.combine(value)
        case let value as Int64:
            hasher.combine(value)
        case let value as UInt:
            hasher.combine(value)
        case let value as UInt8:
            hasher.combine(value)
        case let value as UInt16:
            hasher.combine(value)
        case let value as UInt32:
            hasher.combine(value)
        case let value as UInt64:
            hasher.combine(value)
        case let value as Float:
            hasher.combine(value)
        case let value as Double:
            hasher.combine(value)
        case let value as String:
            hasher.combine(value)
        case let value as [String: AnyDecodable]:
            hasher.combine(value)
        case let value as [AnyDecodable]:
            hasher.combine(value)
        default:
            break
        }
    }
}

// MARK: AnyEncodable

/// A structure that provides suport for the `Encodabe` protocol based an the `Any` type.
/// ```swift
/// let value: [String: AnyEncodable] = [
///    "boolean": true,
///    "integer": 99,
///    "double": 21.5,
///    "string": "hello world",
///    "array": [1, 2, 3],
///    "dict": {
///       "1": "tic",
///       "2": "tac",
///       "3": "toe"
///    },
///    "null": null
/// ]
/// 
/// let encoder = JSONEncoder()
/// let result = try! encoder.encode(value)
/// ```
@frozen public struct AnyEncodable: Encodable {
    public let value: Any

    public init<T>(_ value: T?) {
        self.value = value ?? ()
    }
}

// MARK: AnyEncodable Protocol

/// A type that can encode itself to an external representation.
@usableFromInline protocol _AnyEncodable {
    /// The value of an `Encodable` type.
    var value: Any {
        get
    }
    
    /// Creates a new encodable value using a placeholder type.
    /// - Parameters:
    ///   - value: An optional value of a `Encodable` type.
    init<T>(_ value: T?)
}

extension AnyEncodable: _AnyEncodable {}

// MARK: AnyEncodable Extensions

extension _AnyEncodable {
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()

        switch value {
        #if canImport(Foundation)
        case is NSNull:
            try container.encodeNil()
        case let number as NSNumber:
            try encode(nsnumber: number, into: &container)
        #endif
        case is Void:
            try container.encodeNil()
        case let bool as Bool:
            try container.encode(bool)
        case let int as Int:
            try container.encode(int)
        case let int8 as Int8:
            try container.encode(int8)
        case let int16 as Int16:
            try container.encode(int16)
        case let int32 as Int32:
            try container.encode(int32)
        case let int64 as Int64:
            try container.encode(int64)
        case let uint as UInt:
            try container.encode(uint)
        case let uint8 as UInt8:
            try container.encode(uint8)
        case let uint16 as UInt16:
            try container.encode(uint16)
        case let uint32 as UInt32:
            try container.encode(uint32)
        case let uint64 as UInt64:
            try container.encode(uint64)
        case let float as Float:
            try container.encode(float)
        case let double as Double:
            try container.encode(double)
        case let string as String:
            try container.encode(string)
        #if canImport(Foundation)
        case let date as Date:
            try container.encode(date)
        case let url as URL:
            try container.encode(url)
        #endif
        case let array as [Any?]:
            try container.encode(array.map { AnyEncodable($0) })
        case let dictionary as [String: Any?]:
            try container.encode(dictionary.mapValues { AnyEncodable($0) })
        case let encodable as Encodable:
            try encodable.encode(to: encoder)
        default:
            let context = EncodingError.Context(codingPath: container.codingPath, debugDescription: "AnyEncodable value cannot be encoded.")
            throw EncodingError.invalidValue(value, context)
        }
    }

    #if canImport(Foundation)
    private func encode(nsnumber: NSNumber, into container: inout SingleValueEncodingContainer) throws {
        switch Character(Unicode.Scalar(UInt8(nsnumber.objCType.pointee)))  {
        case "B":
            try container.encode(nsnumber.boolValue)
        case "c":
            try container.encode(nsnumber.int8Value)
        case "s":
            try container.encode(nsnumber.int16Value)
        case "i", "l":
            try container.encode(nsnumber.int32Value)
        case "q":
            try container.encode(nsnumber.int64Value)
        case "C":
            try container.encode(nsnumber.uint8Value)
        case "S":
            try container.encode(nsnumber.uint16Value)
        case "I", "L":
            try container.encode(nsnumber.uint32Value)
        case "Q":
            try container.encode(nsnumber.uint64Value)
        case "f":
            try container.encode(nsnumber.floatValue)
        case "d":
            try container.encode(nsnumber.doubleValue)
        default:
            let context = EncodingError.Context(codingPath: container.codingPath, debugDescription: "NSNumber cannot be encoded because its type is not handled.")
            throw EncodingError.invalidValue(nsnumber, context)
        }
    }
    #endif
}

// MARK: AnyCodable Extensions

extension AnyEncodable: Equatable {
    public static func == (lhs: AnyEncodable, rhs: AnyEncodable) -> Bool {
        switch (lhs.value, rhs.value) {
        case is (Void, Void):
            return true
        case let (lhs as Bool, rhs as Bool):
            return lhs == rhs
        case let (lhs as Int, rhs as Int):
            return lhs == rhs
        case let (lhs as Int8, rhs as Int8):
            return lhs == rhs
        case let (lhs as Int16, rhs as Int16):
            return lhs == rhs
        case let (lhs as Int32, rhs as Int32):
            return lhs == rhs
        case let (lhs as Int64, rhs as Int64):
            return lhs == rhs
        case let (lhs as UInt, rhs as UInt):
            return lhs == rhs
        case let (lhs as UInt8, rhs as UInt8):
            return lhs == rhs
        case let (lhs as UInt16, rhs as UInt16):
            return lhs == rhs
        case let (lhs as UInt32, rhs as UInt32):
            return lhs == rhs
        case let (lhs as UInt64, rhs as UInt64):
            return lhs == rhs
        case let (lhs as Float, rhs as Float):
            return lhs == rhs
        case let (lhs as Double, rhs as Double):
            return lhs == rhs
        case let (lhs as String, rhs as String):
            return lhs == rhs
        case let (lhs as [String: AnyEncodable], rhs as [String: AnyEncodable]):
            return lhs == rhs
        case let (lhs as [String: AnyHashable], rhs as [String: AnyHashable]):
            return lhs == rhs
        case let (lhs as [AnyEncodable], rhs as [AnyEncodable]):
            return lhs == rhs
        default:
            return false
        }
    }
}

extension AnyEncodable: CustomStringConvertible {
    public var description: String {
        switch value {
        case is Void:
            return String(describing: nil as Any?)
        case let value as CustomStringConvertible:
            return value.description
        default:
            return String(describing: value)
        }
    }
}

extension AnyEncodable: CustomDebugStringConvertible {
    public var debugDescription: String {
        switch value {
        case let value as CustomDebugStringConvertible:
            return "AnyEncodable(\(value.debugDescription))"
        default:
            return "AnyEncodable(\(description))"
        }
    }
}

extension AnyEncodable: ExpressibleByNilLiteral {
}

extension AnyEncodable: ExpressibleByBooleanLiteral {
}

extension AnyEncodable: ExpressibleByIntegerLiteral {
}

extension AnyEncodable: ExpressibleByFloatLiteral {
}

extension AnyEncodable: ExpressibleByStringLiteral {
}

extension AnyEncodable: ExpressibleByStringInterpolation {
}

extension AnyEncodable: ExpressibleByArrayLiteral {
}

extension AnyEncodable: ExpressibleByDictionaryLiteral {
}

extension _AnyEncodable {
    public init(nilLiteral _: ()) {
        self.init(nil as Any?)
    }

    public init(booleanLiteral value: Bool) {
        self.init(value)
    }

    public init(integerLiteral value: Int) {
        self.init(value)
    }

    public init(floatLiteral value: Double) {
        self.init(value)
    }

    public init(extendedGraphemeClusterLiteral value: String) {
        self.init(value)
    }

    public init(stringLiteral value: String) {
        self.init(value)
    }

    public init(arrayLiteral elements: Any...) {
        self.init(elements)
    }

    public init(dictionaryLiteral elements: (AnyHashable, Any)...) {
        self.init([AnyHashable: Any](elements, uniquingKeysWith: { first, _ in first }))
    }
}

extension AnyEncodable: Hashable {
    public func hash(into hasher: inout Hasher) {
        switch value {
        case let value as Bool:
            hasher.combine(value)
        case let value as Int:
            hasher.combine(value)
        case let value as Int8:
            hasher.combine(value)
        case let value as Int16:
            hasher.combine(value)
        case let value as Int32:
            hasher.combine(value)
        case let value as Int64:
            hasher.combine(value)
        case let value as UInt:
            hasher.combine(value)
        case let value as UInt8:
            hasher.combine(value)
        case let value as UInt16:
            hasher.combine(value)
        case let value as UInt32:
            hasher.combine(value)
        case let value as UInt64:
            hasher.combine(value)
        case let value as Float:
            hasher.combine(value)
        case let value as Double:
            hasher.combine(value)
        case let value as String:
            hasher.combine(value)
        case let value as [String: AnyEncodable]:
            hasher.combine(value)
        case let value as [AnyEncodable]:
            hasher.combine(value)
        default:
            break
        }
    }
}
