require "test_helper"

class KotlinBCVParserTest < Minitest::Test
  def parser(strip: true, normalize: false)
    ApiDiff::KotlinBCVParser.new "strip-packages": strip, normalize: normalize
  end

  def test_returns_api
    assert_instance_of ApiDiff::Api, parser.parse("")
  end

  def test_classes
    input = <<~EOF
      public class First {
      }
      public final class com/abc/Second {
      }
      public abstract class com/a/b/c/Third {
      }
      public final class com/a/Fourth : com/a/Parent {
      }
      public final class com/a/Fifth : com/a/Parent, java/io/Serializable {
      }
    EOF

    api = parser(strip: false).parse(input)
    classes = api.classes
    assert_equal 5, classes.size

    first = classes[0]
    assert_equal "First", first.name
    assert_equal "class First", first.declaration

    second = classes[1]
    assert_equal "com.abc.Second", second.name
    assert_equal "class com.abc.Second", second.declaration

    third = classes[2]
    assert_equal "com.a.b.c.Third", third.name
    assert_equal "class com.a.b.c.Third", third.declaration

    fourth = classes[3]
    assert_equal "com.a.Fourth", fourth.name
    assert_equal "class com.a.Fourth : com.a.Parent", fourth.declaration

    fifth = classes[4]
    assert_equal "com.a.Fifth", fifth.name
    assert_equal "class com.a.Fifth : com.a.Parent, java.io.Serializable", fifth.declaration
  end

  def test_functions
    input = <<~EOF
      public class FirstClass {
        public fun action ()V
        public final fun finalAction ()V
        public abstract fun abstractAction ()V
        public fun hashCode ()I
        public fun toString ()Ljava/lang/String;
        public fun check (Ljava/lang/String;)Z
        public fun <init> ()V
        public synthetic fun <init> (ILkotlin/jvm/internal/DefaultConstructorMarker;)V
        public static synthetic fun hide$default (Lcom/a/Second;ILjava/lang/Object;)V
      }
    EOF

    api = parser.parse(input)
    functions = api.classes.first.functions
    assert_equal 9, functions.size

    action = functions[0]
    assert_equal "action", action.name
    assert_equal "fun action () -> Void", action.full_signature

    final_action = functions[1]
    assert_equal "finalAction", final_action.name
    assert_equal "final fun finalAction () -> Void", final_action.full_signature

    abstract_action = functions[2]
    assert_equal "abstractAction", abstract_action.name
    assert_equal "abstract fun abstractAction () -> Void", abstract_action.full_signature

    hash_code = functions[3]
    assert_equal "hashCode", hash_code.name
    assert_equal "fun hashCode () -> Int", hash_code.full_signature

    to_string = functions[4]
    assert_equal "toString", to_string.name
    assert_equal "fun toString () -> String", to_string.full_signature

    check = functions[5]
    assert_equal "check", check.name
    assert_equal "fun check (String) -> Boolean", check.full_signature

    init = functions[6]
    assert_equal "init", init.name
    assert_equal "fun <init> ()", init.full_signature

    syn_init = functions[7]
    assert_equal "init", syn_init.name
    assert_equal "fun <init> (Int, DefaultConstructorMarker)", syn_init.full_signature
  end

  def test_omits_component_functions
    input = <<~EOF
      public class DataClass {
        public final fun component1 ()Ljava/lang/String;
        public final fun component2 ()Ljava/lang/String;
        public final fun component3 ()Ljava/lang/String;
        public final fun component4 ()Ljava/util/List;
      }
    EOF

    api = parser.parse(input)
    functions = api.classes.first.functions
    assert_equal 0, functions.size
  end

  def test_properties
    input = <<~EOF
      public class Properties {
        public fun getNumber ()I
        public final fun getId ()Ljava/lang/String;
        public final fun getName ()Ljava/lang/String;
        public final fun setName (Ljava/lang/String;)V
        public final fun getFQDN ()Ljava/lang/String;
      }
    EOF

    api = parser.parse(input)
    assert_equal 0, api.classes.first.functions.size
    properties = api.classes.first.properties
    assert_equal 4, properties.size

    number = properties[0]
    assert_equal "number", number.name
    assert_equal "Int", number.type
    assert !number.is_writable?

    id = properties[1]
    assert_equal "id", id.name
    assert_equal "String", id.type
    assert !id.is_writable?

    name = properties[2]
    assert_equal "name", name.name
    assert_equal "String", name.type
    assert name.is_writable?

    fqdn = properties[3]
    assert_equal "fqdn", fqdn.name
  end

  def test_companion_objects
    # TypeCode
    # Metadata
  end

  def test_enums
    input = <<~EOF
      public final class com/package/Reason : java/lang/Enum {
        public static final field GOOD Lcom/package/Reason;
        public static final field NOT_SO_GOOD Lcom/package/Reason;
        public static final field BAD Lcom/package/Reason;
        public static final field NONE Lcom/package/Reason;
        public static final field BFG1000_THING Lcom/package/Reason;

        public final fun getCode ()I;
        public final fun getName ()Ljava/lang/String;
        public static fun valueOf (Ljava/lang/String;)Lcom/package/Reason;
        public static fun values ()[LLcom/package/Reason;
      }
    EOF

    api = parser.parse(input)
    enums = api.enums
    assert_equal 1, enums.size

    reason = enums[0]
    assert_equal "Reason", reason.name
    assert_equal ["GOOD", "NOT_SO_GOOD", "BAD", "NONE", "BFG1000_THING"], reason.cases
    assert_equal 2, reason.functions.size
    assert_equal "static fun valueOf (String) -> Reason", reason.functions[0].full_signature
    assert_equal "static fun values () -> [Reason]", reason.functions[1].full_signature
    assert_equal 2, reason.properties.size
    assert_equal "val code: Int", reason.properties[0].to_s
    assert_equal "val name: String", reason.properties[1].to_s
  end

  def test_normalization
    input = <<~EOF
      public class FirstClass {
        public fun <init> ()V
        public final fun finalAction ()V
        public abstract fun abstractAction ()V
      }

      public final class com/package/Reason : java/lang/Enum {
        public static final field GOOD Lcom/package/Reason;
        public static final field NOT_SO_GOOD Lcom/package/Reason;
        public static final field REALLY__UNCONVENTIONAL Lcom/package/Reason;
      }
    EOF

    api = parser(normalize: true).parse(input)
    
    first_class = api.classes.first
    assert_equal 3, first_class.functions.size
    assert_equal "init()", first_class.functions[0].full_signature
    assert_equal "func finalAction() -> Void", first_class.functions[1].full_signature
    assert_equal "func abstractAction() -> Void", first_class.functions[2].full_signature

    reason = api.enums.first
    assert_equal ["good", "notSoGood", "really_Unconventional"], reason.cases
  end
end