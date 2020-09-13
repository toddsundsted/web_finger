# A [WebFinger](https://tools.ietf.org/html/rfc7033)
# client for Crystal.
module WebFinger
  # Returns the result of querying for the specified account.
  #
  # The account should conform to the ['acct' URI
  # Scheme](https://tools.ietf.org/html/rfc7565).
  #
  #     w = WebFinger.query("acct:toddsundsted@epiktistes.com") # => #<WebFinger::Result:0x108d...>
  #     w.link("http://webfinger.net/rel/profile-page").href # => "https://epiktistes.com/@toddsundsted"
  #
  # Raises `WebFinger::NotFoundError` if the account does not exist and
  # `WebFinger::RedirectionError` if redirection fails.  Otherwise,
  # returns `WebFinger::Result`.
  #
  def self.query(account, *args)
    WebFinger::Client.query(account, *args)
  end
end

require "./web_finger/client"
require "./web_finger/result"
