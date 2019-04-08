require "json"
require "xml"

module WebFinger
  # `Result` error.
  class ResultError < Exception
  end

  # A `WebFinger` query result.
  class Result
    class Link
      JSON.mapping(
        rel: String,
        type: String?,
        href: String?,
        properties: Hash(String, String?)?,
        titles: Hash(String, String)?
      )

      def initialize(
        @rel : String,
        @type : String?,
        @href : String?,
        @properties : Hash(String, String?)?,
        @titles : Hash(String, String)?
      )
      end

      def self.from_xml(xml, ns, xrd)
        if (nn = xml.xpath_nodes("./#{xrd}Property", ns)).size > 0
          properties =
            nn.reduce(Hash(String, String?).new) do |acc, n|
              acc[n["type"]] = n["nil"]? ? nil : n.content
              acc
            end
        end
        if (nn = xml.xpath_nodes("./#{xrd}Title", ns)).size > 0
          titles =
            nn.reduce(Hash(String, String).new) do |acc, n|
              acc[n["lang"]? || "default"] = n.content
              acc
            end
        end
        new(xml["rel"], xml["type"]?, xml["href"]?, properties, titles)
      end
    end

    JSON.mapping(
      subject: String?,
      aliases: Array(String)?,
      properties: Hash(String, String?)?,
      links: {
        type: Hash(String, Link),
        converter: Converter,
        nilable: true
      }
    )

    private class Converter
      def self.from_json(value : JSON::PullParser)
        Hash(String, Link).new.tap do |hash|
          value.read_array do
            link = Link.new(value)
            hash[link.rel] = link
          end
        end
      end
    end

    def initialize(
      @subject : String?,
      @aliases : Array(String)?,
      @properties : Hash(String, String?)?,
      @links : Hash(String, Link)?
    )
    end

    def self.from_xml(xml)
      xml = XML.parse(xml).first_element_child
      raise ResultError.new("empty result") unless xml
      ns = xml.namespaces
      xrd =
        begin
          key = ns.key_for?("http://docs.oasis-open.org/ns/xri/xrd-1.0").try(&.split(":")).try(&.last)
          key ? "#{key}:" : ""
        end
      if (nn = xml.xpath_nodes("./#{xrd}Subject", ns)).size > 0
        subject = nn.first.content
      end
      if (nn = xml.xpath_nodes("./#{xrd}Alias", ns)).size > 0
        aliases =
          nn.reduce(Array(String).new) do |acc, n|
            acc << n.content
            acc
          end
      end
      if (nn = xml.xpath_nodes("./#{xrd}Property", ns)).size > 0
        properties =
          nn.reduce(Hash(String, String?).new) do |acc, n|
            acc[n["type"]] = n["nil"]? ? nil : n.content
            acc
          end
      end
      if (nn = xml.xpath_nodes("./#{xrd}Link", ns)).size > 0
        links =
          nn.reduce(Hash(String, Link).new) do |acc, n|
            link = Link.from_xml(n, ns, xrd)
            acc[link.rel] = link
            acc
          end
      end
      new(subject, aliases, properties, links)
    end

    def property(key)
      unless (p = @properties)
        raise ResultError.new("No properties in result")
      end
      p[key]
    end

    def property?(key)
      if (p = @properties)
        p.has_key?(key)
      end
    end

    def link(key)
      unless (l = @links)
        raise ResultError.new("No links in result")
      end
      l[key]
    end

    def link?(key)
      if (l = @links)
        l.has_key?(key)
      end
    end
  end
end
