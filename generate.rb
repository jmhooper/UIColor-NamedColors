require 'active_support/inflector'
require 'json'

def hex_to_rgb(hex)
  hex = hex.gsub('#', '')
  {
    red: hex[0..1].hex,
    green: hex[2..3].hex,
    blue: hex[4..5].hex,
  }
end

extension_header = <<-TERMINATOR
import UIKit

public extension UIColor {
TERMINATOR

extension_footer = <<-TERMINATOR
}
TERMINATOR

color_names_header = <<-TERMINATOR
  
    // MARK: Named Colors

TERMINATOR

color_aliases_header = <<-TERMINATOR

    // MARK: Named Color Aliases

TERMINATOR

def swift_from_hex(name, hex)
  rgb = hex_to_rgb(hex)
  method_name = "#{name.camelize(:lower)}Color"
  <<-TERMINATOR
    public class func #{method_name}() -> UIColor {
      return UIColor(
          red: #{rgb[:red]}.0 / 255.0,
          green: #{rgb[:green]}.0 / 255.0,
          blue: #{rgb[:blue]}.0 / 255.0,
          alpha: 1.0
      )
    }
  TERMINATOR
end

def swift_from_alias(name, aliased_name)
  method_name = "#{name.camelize(:lower)}Color"
  aliased_method_name = "#{aliased_name.camelize(:lower)}Color"
  <<-TERMINATOR
    public class func #{method_name}() -> UIColor {
        return #{aliased_method_name}()
    }
  TERMINATOR
end

color_names = JSON.parse(File.read('color_names.json'))

color_names_swift = color_names.map do |name, hex|
  swift_from_hex(name, hex)
end.join("\n")

color_aliases = JSON.parse(File.read('color_aliases.json'))

color_aliases_swift = color_aliases.map do |name, aliased_name|
  swift_from_alias(name, aliased_name)
end.join("\n")

swift = [
  extension_header,
  color_names_header,
  color_names_swift,
  color_aliases_header,
  color_aliases_swift,
  extension_footer,
].join

File.open('UIColor+NamedColors.swift', 'w') do |file|
  file.write(swift)
end
