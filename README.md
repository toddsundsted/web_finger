# web_finger

A [WebFinger](https://tools.ietf.org/html/rfc7033) client for Crystal.

## Installation

1. Add the dependency to your `shard.yml`:

```
dependencies:
  web_finger:
    github: toddsundsted/web_finger
```

2. Run `shards install`

## Usage

```
require "web_finger"

w = WebFinger.query("acct:toddsundsted@epiktistes.com") # => #<WebFinger::Result:0x108d...>
w.link("http://webfinger.net/rel/profile-page").href # => "https://epiktistes.com/@toddsundsted"
```

## Contributors

- [Todd Sundsted](https://github.com/toddsundsted) - creator and maintainer
