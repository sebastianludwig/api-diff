module ApiDiff
  # Biggest Drawback: Does not support optionals :-/
  class KotlinBCVParser < Parser
    def parse(content)
      Property.readonly_keyword = "val"

      sections = content.scan(/^.+?{$.*?^}$/m)
      sections.each do |section|
        section.strip!
        first_line = section.split("\n")[0]
        if first_line.include?(" : java/lang/Enum")
          api.enums << parse_enum(section)
        elsif first_line.match?(/public.+class/)
          api.classes << parse_class(section)
        # elsif first_line.match?(/public protocol/)
        #   api.interfaces << parse_interface(section)
        # elsif first_line.match?(/extension/)
        #   parse_extension(api, section)
        end
      end

      normalize!(api) if @options[:normalize]
    end

    private

    def parse_class(class_content)
      fully_qualified_name = transform_package_path class_content.match(/public.+class ([^\s]+)/)[1]
      cls = Class.new(strip_packages(fully_qualified_name), fully_qualified_name)
      cls.parents = parse_parents(class_content)
      cls.functions = parse_functions(class_content)
      extract_properties(cls)
      cls
    end

    def parse_enum(enum_content)
      fully_qualified_name = transform_package_path enum_content.match(/public.+class ([^\s]+)/)[1]
      enum = Enum.new(strip_packages(fully_qualified_name), fully_qualified_name)
      enum.cases = parse_enum_cases(enum_content)
      enum.functions = parse_functions(enum_content)
      extract_properties(enum)
      enum
    end

    def parse_parents(content)
      parents_match = content.match(/\A.+?: (.+?) \{$/)
      return [] if parents_match.nil?
      parents_match[1].split(",").map { |p| strip_packages(transform_package_path(p.strip)) }
    end

    def parse_functions(content)
      method_regexp = /public (?<signature>(?<static>static )?.*fun (?:(<(?<init>init)>)|(?<name>[^\s]+)) \((?<params>.*)\))(?<return_type>.+)$/
      all_matches(content, method_regexp).map do |match|
        next if match[:name]&.start_with? "component" # don't add data class `componentX` methods
        params_range = ((match.begin(:params) - match.begin(:signature))...(match.end(:params) - match.begin(:signature)))
        signature = match[:signature]
        signature[params_range] = map_jvm_types(match[:params]).join(", ")
        signature.gsub!(/synthetic ?/, "") # synthetic or not, it's part of the API
        Function.new(
          name: (match[:name] || match[:init]),
          signature: signature,
          return_type: match[:init].nil? ? map_jvm_types(match[:return_type]).join : nil,
          static: !match[:static].nil?,
          constructor: (not match[:init].nil?)
        )
      end.compact
    end

    def parse_enum_cases(content)
      case_regexp = /public static final field (?<name>[A-Z_0-9]+)/
      all_matches(content, case_regexp).map do |match|
        match[:name]
      end
    end

    def extract_properties(type)
      getters = type.functions.select { |f| f.signature.match(/fun get[A-Z](\w+)? \(\)/) }
      getters.each do |getter|
        setter_name = getter.name.gsub(/^get/, "set")
        setter = type.functions.find { |f| f.signature.match(/fun #{setter_name} \(#{getter.return_type}\)/) }

        type.functions.delete getter
        type.functions.delete setter if setter

        name = getter.name.gsub(/^get/, "")
        if name == name.upcase  # complete uppercase -> complete lowercase
          name.downcase!
        else
          name[0] = name[0].downcase
        end
        type.properties << Property.new(
          name: name,
          type: getter.return_type,
          writable: (setter != nil),
          static: getter.is_static?
        )
      end
    end

    def transform_package_path(path)
      path.gsub("/", ".")
    end

    def map_jvm_types(types)
      mapping = {
        "Z" => "Boolean",
        "B" => "Byte",
        "C" => "Char",
        "S" => "Short",
        "I" => "Int",
        "J" => "Long",
        "F" => "Float",
        "D" => "Double",
        "V" => "Void"
      }
      vm_types_regexp = /(?<array>\[)?(?<type>Z|B|C|S|I|J|F|D|V|(L(?<class>[^;]+);))/
      all_matches(types, vm_types_regexp).map do |match|
        if match[:class]
          result = strip_packages(transform_package_path(match[:class]))
        else
          result = mapping[match[:type]]
        end
        result = "[#{result}]" if match[:array]
        result
      end
    end

    def normalize!(api)
      Property.readonly_keyword = "let"

      # remove abstract & final
      # fun -> func
      # <init> -> init
      # remove space before (
      (api.classes + api.enums).flat_map(&:functions).each do |f|
        f.signature.gsub!(/(?:abstract )?(?:final )?fun (<?\w+>?) \(/, "func \\1(")
        f.signature.gsub!("func <init>", "init")
      end

      # enum screaming case -> camel case
      api.enums.each do |e|
        e.cases = e.cases.map do |c|
          # supports double _ by preserving one of them
          c.scan(/_?[A-Z0-9]+_?/).map.with_index do |p, index|
            p.gsub(/_$/, "").downcase.gsub(/^_?\w/) { |m| index == 0 ? m : m.upcase }
          end.join
        end
      end

    end
  end
end
