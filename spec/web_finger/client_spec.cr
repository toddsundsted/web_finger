require "uri"
require "../spec_helper"

module HostMeta
  def self.query(host)
    # intentionally use non-standard values here to ensure
    # examples below don't test the fall-back template.
    HostMeta::Result.new(properties: nil, links: [
      HostMeta::Result::Link.new("lrdd", "application/xrd+xml", "https://example.com/webfinger?r={uri}", nil)
    ])
  end
end

class HTTP::Client
  @@history = [] of URI

  @@next_response : {Int32, HTTP::Headers, String}? = nil

  def self.history
    @@history
  end

  def self.clear_history
    @@history = [] of URI
  end

  def self.set_next_response(status, headers : HTTP::Headers, body : String)
    @@next_response = {status, headers, body}
  end

  def self.get(url : String | URI, h : HTTP::Headers? = nil, b : BodyType = nil, t = nil)
    url = url.is_a?(String) ? URI.parse(url) : url
    @@history << url
    case url.query || url.path
    when /not-found/
      yield HTTP::Client::Response.new(404)
    when /internal-server-error/
      yield HTTP::Client::Response.new(500)
    else
      if (next_response = @@next_response)
        code, headers, body = next_response
        @@next_response = nil
      else
        code = 200
        headers = HTTP::Headers.new
        body = <<-XML
          <?xml version="1.0"?>
          <XRD xmlns="http://docs.oasis-open.org/ns/xri/xrd-1.0"/>
          XML
      end
      yield HTTP::Client::Response.new(code, headers: headers, body_io: IO::Memory.new(body))
    end
  end
end

def with_json
  HTTP::Client.set_next_response(
    200,
    HTTP::Headers{"Content-Type" => "application/jrd+json"},
    "{}"
  )
  yield
end

def with_xml
  HTTP::Client.set_next_response(
    200,
    HTTP::Headers{"Content-Type" => "application/xrd+xml"},
    <<-XML
      <?xml version="1.0"?>
      <XRD xmlns="http://docs.oasis-open.org/ns/xri/xrd-1.0"/>
      XML
  )
  yield
end

def with_no_content_type
  HTTP::Client.set_next_response(
    200,
    HTTP::Headers.new,
    "{}"
  )
  yield
end

Spectator.describe WebFinger::Client do
  before_each do
    HTTP::Client.clear_history
  end

  describe ".query" do
    it "raises an error if account doesn't exist" do
      expect_raises(WebFinger::NotFoundError) do
        WebFinger::Client.query("acct:not-found@example.com")
      end
    end

    it "raises an error if request fails for any reason" do
      expect_raises(WebFinger::Error) do
        WebFinger::Client.query("acct:internal-server-error@example.com")
      end
    end

    it "returns a result" do
      with_json do
        expect(WebFinger::Client.query("acct:foobar@example.com")).to be_a(WebFinger::Result)
      end
    end

    it "returns a result" do
      with_xml do
        expect(WebFinger::Client.query("acct:foobar@example.com")).to be_a(WebFinger::Result)
      end
    end

    it "returns a result" do
      with_no_content_type do
        expect(WebFinger::Client.query("acct:foobar@example.com")).to be_a(WebFinger::Result)
      end
    end

    it "makes an HTTP request to the account domain" do
      WebFinger::Client.query("acct:foobar@example.com")
      expect(HTTP::Client.history.map(&.host)).to contain("example.com")
    end

    it "makes an HTTP request with the webfinger path" do
      WebFinger::Client.query("acct:foobar@example.com")
      expect(HTTP::Client.history.map(&.path)).to contain("/webfinger")
    end

    it "encodes the account as a resource query parameter" do
      WebFinger::Client.query("acct:foobar@example.com")
      expect(HTTP::Client.history.map(&.query)).to contain("r=acct%3Afoobar%40example.com")
    end
  end
end
