require "../spec_helper"

XRD_ENV = <<-XRD
<?xml version='1.0'?>
<!-- This is the first child! -->
<XRD
  xmlns='http://docs.oasis-open.org/ns/xri/xrd-1.0'
  xmlns:xsi='http://www.w3.org/2001/XMLSchema-instance'>
%s
</XRD>
XRD

Spectator.describe WebFinger::Result do
  describe ".from_xml" do
    it "parses an application/xrd+xml result" do
      WebFinger::Result.from_xml("<XRD/>").should be_a(WebFinger::Result)
    end

    it "maps the subject" do
      result = XRD_ENV % "<Subject>acct:subject</Subject>"
      WebFinger::Result.from_xml(result).subject.should eq("acct:subject")
    end

    it "maps aliases" do
      result = XRD_ENV % "<Alias>one</Alias><Alias>two</Alias>"
      WebFinger::Result.from_xml(result).aliases.should eq(["one", "two"])
    end

    it "maps properties" do
      result = XRD_ENV % "<Property type='one'>1</Property><Property type='two' xsi:nil='true'/>"
      WebFinger::Result.from_xml(result).properties.should eq({"one" => "1", "two" => nil})
    end

    context "links" do
      it "parses links" do
        result = XRD_ENV % "<Link rel='one' href='1'/>"
        WebFinger::Result.from_xml(result).links.should be_a(Hash(String, WebFinger::Result::Link))
      end

      it "maps rel" do
        result = XRD_ENV % "<Link rel='self'/>"
        links = WebFinger::Result.from_xml(result).links
        links.try(&.size).should eq(1)
        links.try(&.first.last.rel).should eq("self")
      end

      it "maps type" do
        result = XRD_ENV % "<Link rel='self' type='text'/>"
        links = WebFinger::Result.from_xml(result).links
        links.try(&.size).should eq(1)
        links.try(&.first.last.type).should eq("text")
      end

      it "maps href" do
        result = XRD_ENV % "<Link rel='self' href='urn:xyz'/>"
        links = WebFinger::Result.from_xml(result).links
        links.try(&.size).should eq(1)
        links.try(&.first.last.href).should eq("urn:xyz")
      end

      it "maps properties" do
        result = XRD_ENV % "<Link rel='self'><Property type='one'>1</Property><Property type='two' xsi:nil='true'/></Link>"
        links = WebFinger::Result.from_xml(result).links
        links.try(&.size).should eq(1)
        links.try(&.first.last.properties).should eq({"one" => "1", "two" => nil})
      end

      it "maps titles" do
        result = XRD_ENV % "<Link rel='self'><Title xml:lang='en'>Test</Title><Title>Default</Title></Link>"
        links = WebFinger::Result.from_xml(result).links
        links.try(&.size).should eq(1)
        links.try(&.first.last.titles).should eq({"default" => "Default", "en" => "Test"})
      end
    end
  end

  describe ".from_json" do
    it "parses an application/jrd+json result" do
      WebFinger::Result.from_json("{}").should be_a(WebFinger::Result)
    end

    it "maps the subject" do
      result = %[{"subject":"acct:subject"}]
      WebFinger::Result.from_json(result).subject.should eq("acct:subject")
    end

    it "maps aliases" do
      result = %[{"aliases":["one","two"]}]
      WebFinger::Result.from_json(result).aliases.should eq(["one", "two"])
    end

    it "maps properties" do
      result = %[{"properties":{"one":"1","two":null}}]
      WebFinger::Result.from_json(result).properties.should eq({"one" => "1", "two" => nil})
    end

    context "links" do
      it "parses links" do
        result = %[{"links":[]}]
        WebFinger::Result.from_json(result).links.should be_a(Hash(String, WebFinger::Result::Link))
      end

      it "maps rel" do
        result = %[{"links":[{"rel":"self"}]}]
        links = WebFinger::Result.from_json(result).links
        links.try(&.size).should eq(1)
        links.try(&.first.last.rel).should eq("self")
      end

      it "maps type" do
        result = %[{"links":[{"rel":"self","type":"text"}]}]
        links = WebFinger::Result.from_json(result).links
        links.try(&.size).should eq(1)
        links.try(&.first.last.type).should eq("text")
      end

      it "maps href" do
        result = %[{"links":[{"rel":"self","href":"urn:xyz"}]}]
        links = WebFinger::Result.from_json(result).links
        links.try(&.size).should eq(1)
        links.try(&.first.last.href).should eq("urn:xyz")
      end

      it "maps properties" do
        result = %[{"links":[{"rel":"self","properties":{"one":"1","two":null}}]}]
        links = WebFinger::Result.from_json(result).links
        links.try(&.size).should eq(1)
        links.try(&.first.last.properties).should eq({"one" => "1", "two" => nil})
      end

      it "maps titles" do
        result = %[{"links":[{"rel":"self","titles":{"en":"Test"}}]}]
        links = WebFinger::Result.from_json(result).links
        links.try(&.size).should eq(1)
        links.try(&.first.last.titles).should eq({"en" => "Test"})
      end
    end
  end

  describe "#property" do
    it "returns the value of the key" do
      result = %[{"properties":{"one":"1","two":null}}]
      WebFinger::Result.from_json(result).property("one").should eq("1")
    end
  end

  describe "#property?" do
    it "returns true if the key has a value" do
      result = %[{"properties":{"one":"1","two":null}}]
      WebFinger::Result.from_json(result).property?("one").should be_true
    end
  end

  describe "#link" do
    it "returns the value of the key" do
      result = %[{"links":[{"rel":"next","href":"next/1"},{"rel":"prev","href":"prev/1"}]}]
      WebFinger::Result.from_json(result).link("next").href.should eq("next/1")
    end
  end

  describe "#link?" do
    it "returns true if the key has a value" do
      result = %[{"links":[{"rel":"next","href":"next/1"},{"rel":"prev","href":"prev/1"}]}]
      WebFinger::Result.from_json(result).link?("next").should be_true
    end
  end
end
