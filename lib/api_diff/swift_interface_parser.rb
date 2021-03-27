module ApiDiff
  class SwiftInterfaceParser < Parser
    def parse(content)
      module_name_match = content.match(/@_exported import (\w+)/)
      container_types = module_name_match ? module_name_match[1] : []
      parse_blocks(content, container_types)
      parse_one_line_extensions(content)
    end

    private

    def parse_blocks(content, container_types = [])
      sections = content.scan(/^[^\n]+?{$.*?^}$/m)
      sections.each do |section|
        first_line = section.split("\n")[0]
        if first_line.match? "public class"
          parse_class(section, container_types)
        elsif first_line.match? "public protocol"
          parse_ptotocol(section, container_types)
        elsif first_line.match? "extension"
          parse_extension(section, container_types)
        elsif first_line.match? "public enum"
          parse_enum(section, container_types)
        end
      end
    end

    def parse_one_line_extensions(content)
      one_line_extensions = content.scan(/^extension.+\{\}$/)
      one_line_extensions.each do |extension|
        parse_extension(extension, [])
      end
    end

    def parse_class(class_content, container_types)
      name = class_content.match(/public class (\w+)/)[1]

      cls = Class.new(name, qualified_name(name, container_types))
      cls.parents = parse_parents(class_content)
      cls.properties = parse_properties(class_content)
      cls.functions = parse_functions(class_content)
      api.classes << cls

      parse_nested_types(class_content, [*container_types, name])
    end

    def parse_ptotocol(protocol_content, container_types)
      name = protocol_content.match(/public protocol (\w+)/)[1]

      protocol = Interface.new(name, qualified_name(name, container_types))
      protocol.parents = parse_parents(protocol_content)
      protocol.properties = parse_properties(protocol_content)
      protocol.functions = parse_functions(protocol_content)
      api.interfaces << protocol

      parse_nested_types(protocol_content, [*container_types, name])
    end

    def parse_extension(content, container_types)
      name = content.match(/extension ([\w\.]+)/)[1]

      base_type = api.class(fully_qualified_name: qualified_name(name, container_types))
      base_type ||= api.interface(fully_qualified_name: qualified_name(name, container_types))
      base_type ||= api.enum(fully_qualified_name: qualified_name(name, container_types))
      raise Error.new "Unable to find base type for extension `#{name}`" if base_type.nil?
      base_type.parents.append(*parse_parents(content)).uniq!
      base_type.properties.append(*parse_properties(content)).uniq!
      base_type.functions.append(*parse_functions(content)).uniq!

      parse_nested_types(content, [*container_types, name])
    end

    def parse_enum(enum_content, container_types)
      name = enum_content.match(/public enum (\w+)/)[1]

      enum = Enum.new(name, qualified_name(name, container_types))
      enum.cases = parse_enum_cases(enum_content)
      enum.parents = parse_parents(enum_content)
      enum.properties = parse_properties(enum_content)
      enum.functions = parse_functions(enum_content)
      api.enums << enum

      parse_nested_types(enum_content, [*container_types, name])
    end

    def parse_nested_types(outer_content, container_types)
      # remove first and last line and un-indent the inner lines
      inner_content = outer_content.split("\n")[1..-2].map { |l| l.gsub(/^\s{,2}/, "") }.join("\n")

      parse_blocks(inner_content, container_types)
    end

    def parse_parents(content)
      parents_match = content.match(/\A.+?: (.+?) \{\}?$/)
      return [] if parents_match.nil?
      parents_match[1].split(",").map { |p| unqualify(p.strip) }
    end

    def parse_properties(content)
      property_regexp = /(public )?(?<static>static )?(?<varlet>var|let) (?<name>\w+): (?<type>[^\s]+)( {\s+(?<get>get)?\s+(?<set>set)?\s*})?/m
      all_matches(content, property_regexp).map do |match|
        Property.new(
          name: match[:name],
          type: unqualify(match[:type]),
          writable: (match[:varlet] == "var" && (match[:get] == nil || match[:set] != nil)),
          static: !match[:static].nil?
        )
      end
    end

    def parse_functions(content)
      method_regexp = /(?<signature>(?<static>static )?((func (?<name>[^\s\(]+))|(?<init>init))\s?\((?<params>.*)\).*?)(-> (?<return_type>.+))?$/
      all_matches(content, method_regexp).map do |match|
        Function.new(
          name: (match[:name] || match[:init]),
          signature: strip_internal_parameter_names(unqualify(match[:signature])).strip,
          return_type: unqualify(match[:return_type]),
          static: !match[:static].nil?,
          constructor: (not match[:init].nil?)
        )
      end
    end

    def parse_enum_cases(content)
      case_regexp = /case (?<name>.+)$/
      all_matches(content, case_regexp).map do |match|
        unqualify(match[:name])
      end
    end

    def qualified_name(name, container_types)
      [*container_types, name].join(".")
    end

    def strip_internal_parameter_names(signature)
      signature.gsub(/(\w+)\s\w+:/, "\\1:")
    end

  end
end
