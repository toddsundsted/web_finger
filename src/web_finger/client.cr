require "http/client"
require "host_meta"

module WebFinger
  # General error.
  class Error < Exception
  end

  # Address not found error.
  class NotFoundError < Error
  end

  # The client.
  module Client
    # Returns the result of querying the specified address.
    #
    # The address should conform to the ['acct' URI
    # Scheme](https://tools.ietf.org/html/rfc7565).
    #
    #     w = WebFinger.query("acct:toddsundsted@epiktistes.com") # => #<WebFinger::Result:0x108d...>
    #     w.link("http://webfinger.net/rel/profile-page").href # => "https://epiktistes.com/@toddsundsted"
    #
    # Raises `WebFinger::NotFoundError` if the address does not
    # exist. Otherwise, returns `WebFinger::Result`.
    #
    def self.query(account)
      unless account =~ /^([^@]+)@([^@]+)$/
        raise Error.new("invalid account: #{account}")
      end
      _, _, host = $~.to_a

      template =
        begin
          HostMeta.query(host).links("lrdd").first.template.not_nil!
        rescue HostMeta::ResultError | NilAssertionError | IndexError
          "https://#{host}/.well-known/webfinger?resource={uri}"
        end

      url = template.gsub("{uri}", URI.escape(account))

      HTTP::Client.get(url) do |response|
        case (code = response.status_code)
        when 200
          mt = response.mime_type.try(&.media_type)
          if ["application/jrd+json", "application/json"].includes?(mt)
            Result.from_json(response.body_io)
          else
            # application/xrd+xml, application/xml, text/xml and everything else
            Result.from_xml(response.body_io)
          end
        when 404
          raise NotFoundError.new("not found [#{code}]: #{url}")
        else
          raise Error.new("error [#{code}]: #{url}")
        end
      end
    end
  end
end
