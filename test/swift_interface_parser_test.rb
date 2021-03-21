require "test_helper"

class SwiftInterfaceParserTest < Minitest::Test
  def parser
    ApiDiff::SwiftInterfaceParser.new "strip-packages": true
  end

  def test_returns_api
    assert_instance_of ApiDiff::Api, parser.parse("")
  end

  def test_classes
    input = <<~EOF
      public class First {
      }
      @_hasMissingDesignatedInitializers public class Second {
      }
      public class Third : Package.Parent {
      }
      public class Fourth : Swift.Codable, Swift.Hashable {
      }
    EOF
    api = parser.parse(input)
    classes = api.classes
    assert_equal 4, classes.size

    first = classes[0]
    assert_equal "First", first.name
    assert_equal "class First", first.declaration

    second = classes[1]
    assert_equal "Second", second.name
    assert_equal "class Second", second.declaration

    third = classes[2]
    assert_equal "Third", third.name
    assert_equal "class Third : Parent", third.declaration

    fourth = classes[3]
    assert_equal "Fourth", fourth.name
    assert_equal "class Fourth : Codable, Hashable", fourth.declaration
  end

  def test_properties
    input = <<~EOF
      public class FirstClass {
        public var name: Swift.String?
        public let number: Swift.Int
        public var data: Foundation.Data {
          get
        }
        public var detailed: [Swift.String] {
          get
          set
        }
      }
    EOF
    api = parser.parse(input)
    properties = api.classes.first.properties
    assert_equal 4, properties.size
    
    name = properties[0]
    assert_equal "name", name.name
    assert_equal "String?", name.type
    assert name.is_writable?

    number = properties[1]
    assert_equal "number", number.name
    assert_equal "Int", number.type
    assert !number.is_writable?

    data = properties[2]
    assert_equal "data", data.name
    assert_equal "Data", data.type
    assert !data.is_writable?

    detailed = properties[3]
    assert_equal "detailed", detailed.name
    assert_equal "[String]", detailed.type
    assert detailed.is_writable?
  end

  def test_functions
    input = <<~EOF
      public class FirstClass {
        public func reset() -> PromiseKit.Promise<Swift.Void>
        public func hash(into hasher: inout Swift.Hasher)
        @available(iOS 13, *)
        public func encode(to encoder: Swift.Encoder) throws
        public init(identifier: Swift.String? = nil, name: Swift.String? = nil)
        public static func == (lhs: Package.FirstClass, rhs: Package.FirstClass) -> Swift.Bool
        public func collect(from source: Package.Source, progress progressHandler: ((Swift.Double) -> Swift.Void)?, completion completionHandler: @escaping (Swift.Error?) -> Swift.Void) -> Swift.Int
      }
    EOF

    api = parser.parse(input)
    functions = api.classes.first.functions
    assert_equal 6, functions.size

    reset = functions[0]
    assert_equal "reset", reset.name
    assert_equal "func reset() -> Promise<Void>", reset.full_signature

    hash = functions[1]
    assert_equal "hash", hash.name
    assert_equal "func hash(into: inout Hasher)", hash.full_signature

    encode = functions[2]
    assert_equal "encode", encode.name
    assert_equal "func encode(to: Encoder) throws", encode.full_signature

    init = functions[3]
    assert_equal "init", init.name
    assert_equal "init(identifier: String? = nil, name: String? = nil)", init.full_signature

    equals = functions[4]
    assert_equal "==", equals.name
    assert_equal "static func == (lhs: FirstClass, rhs: FirstClass) -> Bool", equals.full_signature

    collect = functions[5]
    assert_equal "collect", collect.name
    assert_equal "func collect(from: Source, progress: ((Double) -> Void)?, completion: @escaping (Error?) -> Void) -> Int", collect.full_signature
  end

  def test_class_extensions
    input = <<~EOF
      public class ExtFunction {
      }
      extension ExtFunction {
        public static func == (lhs: ExtFunction, rhs: ExtFunction) -> Swift.Bool
        @available(iOS 13, *)
        public func hash(into hasher: inout Swift.Hasher)
      }
      public class ExtProperty {
      }
      extension ExtProperty {
        public var number: Swift.Int {
          get
        }
      }
      public class ExtParent {
      }
      extension ExtParent : Swift.Hashable {
      }
    EOF

    api = parser.parse(input)
    classes = api.classes
    assert_equal 3, classes.size

    ext_function = classes[0]
    assert_equal 2, ext_function.functions.size
    assert_equal "==", ext_function.functions[0].name
    assert_equal "hash", ext_function.functions[1].name

    ext_property = classes[1]
    assert_equal 1, ext_property.properties.size
    assert_equal "number", ext_property.properties[0].name
    assert !ext_property.properties[0].is_writable?

    ext_parent = classes[2]
    assert_equal 1, ext_parent.parents.size
    assert_equal "Hashable", ext_parent.parents[0]
  end

  def test_interfaces
    input = <<~EOF
      public protocol WithFunctions {
        func action(name: Swift.String)
        @available(iOS 13, *)
        func query(_ query: Query) -> PromiseKit.Promise<[Document]>
      }
      public protocol WithProperties {
        static var prop: [Self] { get }
      }
    EOF

    api = parser.parse(input)
    interfaces = api.interfaces
    assert_equal 2, interfaces.size

    with_functions = interfaces[0]
    assert_equal 2, with_functions.functions.size
    assert_equal "action", with_functions.functions[0].name
    assert_equal "query", with_functions.functions[1].name

    with_properties = interfaces[1]
    assert_equal 1, with_properties.properties.size
    prop = with_properties.properties[0]
    assert_equal "prop", prop.name
    assert_equal "[Self]", prop.type
    assert prop.is_static?
    assert !prop.is_writable?
  end

  def test_interface_extensions
    input = <<~EOF
      public protocol WithFunctions {
      }
      extension WithFunctions : Swift.Hashable {
        public static func == (lhs: WithFunctions, rhs: WithFunctions) -> Swift.Bool
        public func hash(into hasher: inout Swift.Hasher)
      }
      public protocol WithProperties {
      }
      extension WithProperties {
        public var hashValue: Swift.Int {
          get
        }
      }
      public protocol Delegate : AnyObject {
        func deactivate()
      }
      extension Delegate {
        public func deactivate()
      }
    EOF

    api = parser.parse(input)
    interfaces = api.interfaces
    assert_equal 3, interfaces.size

    with_functions = interfaces[0]
    assert_equal ["Hashable"], with_functions.parents
    assert_equal 2, with_functions.functions.size
    assert_equal "==", with_functions.functions[0].name
    assert_equal "hash", with_functions.functions[1].name

    with_properties = interfaces[1]
    assert_equal 1, with_properties.properties.size
    assert_equal "hashValue", with_properties.properties[0].name

    delegate = interfaces[2]
    assert_equal 1, delegate.functions.size
    assert_equal "deactivate", delegate.functions[0].name
  end

  def test_enums
    input = <<~EOF
      public enum Alpha {
        case a
      }
      @frozen public enum Beta {
        case c
        case d
      }
      @frozen public enum Gamma : Swift.String, Swift.CaseIterable {
        case e
        case f
        case g
      }
    EOF

    api = parser.parse(input)
    enums = api.enums
    assert_equal 3, enums.size

    alpha = enums[0]
    assert_equal "Alpha", alpha.name
    assert_equal ["a"], alpha.cases

    beta = enums[1]
    assert_equal "Beta", beta.name
    assert_equal ["c", "d"], beta.cases

    gamma = enums[2]
    assert_equal "Gamma", gamma.name
    assert_equal 3, gamma.cases.size
    assert_equal ["e", "f", "g"], gamma.cases
    assert_equal ["String", "CaseIterable"], gamma.parents
  end
end
