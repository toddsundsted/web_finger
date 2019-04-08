# A [WebFinger](https://tools.ietf.org/html/rfc7033)
# client for Crystal.
module WebFinger
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
  def self.query(address)
    WebFinger::Client.query(address)
  end
end

require "./web_finger/client"
require "./web_finger/result"
