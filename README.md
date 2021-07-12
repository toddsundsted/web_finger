# web_finger

[![GitHub Release](https://img.shields.io/github/release/toddsundsted/web_finger.svg)](https://github.com/toddsundsted/web_finger/releases)
[![Build Status](https://github.com/toddsundsted/web_finger/actions/workflows/ci.yml/badge.svg)](https://github.com/toddsundsted/web_finger/actions)
[![Documentation](https://img.shields.io/badge/docs-available-brightgreen.svg)](https://toddsundsted.github.io/web_finger/)

A [WebFinger](https://tools.ietf.org/html/rfc7033) client for Crystal.

## Installation

1. Add the dependency to your `shard.yml`:

```yaml
dependencies:
  web_finger:
    github: toddsundsted/web_finger
```

2. Run `shards install`

## Usage

```crystal
require "web_finger"

w = WebFinger.query("acct:toddsundsted@epiktistes.com") # => #<WebFinger::Result:0x108d...>
w.link("http://webfinger.net/rel/profile-page").href # => "https://epiktistes.com/@toddsundsted"
```

## Contributors

- [Todd Sundsted](https://github.com/toddsundsted) - creator and maintainer
