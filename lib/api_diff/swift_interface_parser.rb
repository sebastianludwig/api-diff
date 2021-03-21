module ApiDiff
  class SwiftInterfaceParser < Parser
    def parse(content)
      api = Api.new

      sections = content.scan(/^.+?{$.*?^}$/m)
      sections.each do |section|
        first_line = section.split("\n")[0]
        if first_line.match?(/public class/)
          api.classes << parse_class(section)
        elsif first_line.match?(/public protocol/)
          api.interfaces << parse_interface(section)
        elsif first_line.match?(/extension/)
          parse_extension(api, section)
        elsif first_line.match?(/public enum/)
          api.enums << parse_enum(section)
        end
      end

      api
    end

    private

    def parse_class(class_content)
      name = class_content.match(/public class (\w+)/)[1]
      cls = Class.new(name)
      cls.parents = parse_parents(class_content)
      cls.properties = parse_properties(class_content)
      cls.functions = parse_functions(class_content)
      cls
    end

    def parse_interface(interface_content)
      name = interface_content.match(/public protocol (\w+)/)[1]
      interface = Interface.new(name)
      interface.parents = parse_parents(interface_content)
      interface.properties = parse_properties(interface_content)
      interface.functions = parse_functions(interface_content)
      interface
    end

    def parse_extension(api, content)
      name = content.match(/extension (\w+)/)[1]
      cls = api.class(named: name)
      cls ||= api.interface(named: name)
      raise Error.new "Unable to find base type for extension `#{name}`" if cls.nil?
      cls.parents.append(*parse_parents(content)).uniq!
      cls.properties.append(*parse_properties(content)).uniq!
      cls.functions.append(*parse_functions(content)).uniq!
    end

    def parse_enum(enum_content)
      name = enum_content.match(/public enum (\w+)/)[1]
      enum = Enum.new(name)
      enum.cases = parse_enum_cases(enum_content)
      enum.parents = parse_parents(enum_content)
      enum.properties = parse_properties(enum_content)
      enum.functions = parse_functions(enum_content)
      enum
    end

    def parse_parents(content)
      parents_match = content.match(/\A.+?: (.+?) \{$/)
      return [] if parents_match.nil?
      parents_match[1].split(",").map { |p| strip_packages(p.strip) }
    end

    def parse_properties(content)
      property_regexp = /(public )?(?<static>static )?(?<varlet>var|let) (?<name>\w+): (?<type>[^\s]+)( {\s+(?<get>get)?\s+(?<set>set)?\s*})?/m
      all_matches(content, property_regexp).map do |match|
        Property.new(
          name: match[:name],
          type: strip_packages(match[:type]),
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
          signature: strip_internal_parameter_names(strip_packages(match[:signature])).strip,
          return_type: strip_packages(match[:return_type]),
          static: !match[:static].nil?,
          constructor: (not match[:init].nil?)
        )
      end
    end

    def parse_enum_cases(content)
      case_regexp = /case (?<name>.+)$/
      all_matches(content, case_regexp).map do |match|
        match[:name]
      end
    end

    def strip_internal_parameter_names(signature)
      signature.gsub(/(\w+)\s\w+:/, "\\1:")
    end

  end
end
