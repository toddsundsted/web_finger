require "http/client"
require "host_meta"

module WebFinger
  # General error.
  class Error < Exception
  end

  # Account not found error.
  class NotFoundError < Error
  end

  # Redirection failed.
  class RedirectionError < Error
  end

  # The client.
  module Client
    ACCOUNT_REGEX = %r<
      ^https://(?<host>[^/]+)(/.*)?$|
      ^([^@]+)@(?<host>[^@]+)$|
      ^(?<host>.+)$
    >mx

    # Returns the result of querying for the specified account.
    #
    # The account should conform to the ['acct' URI Scheme](https://tools.ietf.org/html/rfc7565).
    # Liberal validation of this format eases federation with other popular servers.
    #
    #     w = WebFinger.query("acct:toddsundsted@epiktistes.com") # => #<WebFinger::Result:0x108d...>
    #     w.link("http://webfinger.net/rel/profile-page").href # => "https://epiktistes.com/@toddsundsted"
    #
    # Raises `WebFinger::NotFoundError` if the account does not exist
    # and `WebFinger::RedirectionError` if redirection failed.
    # Otherwise, returns `WebFinger::Result`.
    #
    def self.query(account, attempts = 10)
      unless account =~ ACCOUNT_REGEX
        raise Error.new("invalid account: #{account}")
      end

      host = $~["host"]?

      template =
        begin
          HostMeta.query(host).links("lrdd").first.template.not_nil!
        rescue HostMeta::Error | NilAssertionError | IndexError
          "https://#{host}/.well-known/webfinger?resource={uri}"
        end

      url = template.gsub("{uri}", URI.encode_www_form(account))

      attempts.times do |i|
        HTTP::Client.get(url) do |response|
          case (code = response.status_code)
          when 200
            mt = response.mime_type.try(&.media_type)
            result =
              if mt =~ /xml/
                Result.from_xml(response.body_io)
              elsif mt =~ /json/
                Result.from_json(response.body_io)
              elsif response.body_io.peek.try(&.first) == 123 # sniff for '{'
                Result.from_json(response.body_io)
              else
                Result.from_xml(response.body_io)
              end
            return result
          when 300, 301, 302, 303, 307, 308
            if (tmp = response.headers["Location"]?) && (url = tmp)
              next
            else
              break
            end
          when 404
            raise NotFoundError.new("not found [#{code}]: #{url}")
          else
            raise Error.new("error [#{code}]: #{url}")
          end
        end
      end
      raise RedirectionError.new("redirection failed: #{url}")
    rescue err : JSON::ParseException
      raise ResultError.new(err.message)
    rescue err : IO::Error | OpenSSL::Error | Compress::Deflate::Error | Compress::Gzip::Error
      raise NotFoundError.new(err.message)
    end
  end
end
