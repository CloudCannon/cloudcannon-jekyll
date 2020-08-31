# frozen_string_literal: true

require "spec_helper"
require "json_schemer"
require "pathname"

describe CloudCannonJekyll::Generator do
  let(:site_data) { {} }
  let(:site) { make_site(site_data) }
  let(:details_raw) { File.read(dest_dir("_cloudcannon/details.json")) }
  let(:config_raw) { File.read(dest_dir("_cloudcannon/config.json")) }
  let(:config) { JSON.parse(config_raw) }
  let(:details) { JSON.parse(details_raw) }
  before { site.process }

  context "creates" do
    it "a details file" do
      expect(Pathname.new(dest_dir("_cloudcannon/details.json"))).to exist
    end

    it "details without data" do
      expect(details_raw.scan(%r!"data": {"!).length).to eq(0)
    end

    it "details without unsupported items" do
      expect(details_raw.scan(%r!UNSUPPORTED!).length).to eq(0)
    end
  end

  context "options" do
    let(:site_data) { { :cloudcannon => { "data" => true } } }

    it "allow details with data" do
      expect(details_raw.scan(%r!"data": {"!).length).to eq(1)
    end

    it "allow details with data without unsupported items" do
      expect(details_raw.scan(%r!UNSUPPORTED!).length).to eq(0)
    end
  end

  context "details" do
    let(:site_data) { { :cloudcannon => { "data" => true } } }


    it "contains valid time" do
      expect(details["time"]).to match(%r!\d{4}\-\d\d\-\d\d \d\d:\d\d:\d\d [+-]\d{4}!)
    end

    it "contains gem information" do
      expect(details["cloudcannon"]["name"]).to eq("cloudcannon-jekyll")
      expect(details["cloudcannon"]["version"]).to eq(CloudCannonJekyll::VERSION)
    end

    it "contains generator information" do
      expect(details["generator"]["name"]).to eq("jekyll")
      expect(details["generator"]["version"]).to match(%r![2-4]\.\d+\.\d+!)
      expect(details["generator"].key?("environment")).to eql(true)
      expect(details["generator"]["metadata"]["markdown"]).to eql("kramdown")
      expect(details["generator"]["metadata"]["kramdown"]).not_to be_nil
      expect(details["generator"]["metadata"]["commonmark"]).to be_nil
    end

    it "contains data" do
      expect(details["data"].keys.length).to eq(2)
      expect(details["data"]["company"]).not_to be_nil
      expect(details["data"]["footer"]).not_to be_nil
    end

    it "contains collections" do
      expect(details["collections"].keys.length).to eq(2)

      expect(details["collections"]["posts"]).not_to be_nil
      expect(details["collections"]["posts"][0]["tags"]).to eq(["hello"])
      expect(details["collections"]["posts"][0]["date"]).to(
        match(%r!\d{4}\-\d\d\-\d\d \d\d:\d\d:\d\d [+-]\d{4}!)
      )

      if Jekyll::VERSION.start_with? "2"
        expect(details["collections"]["posts"][0]["categories"]).to eq(["business"])
      else
        expect(details["collections"]["posts"][0]["categories"]).to eq(["Business"])
      end

      expect(details["collections"]["staff_members"]).not_to be_nil
      unless Jekyll::VERSION.start_with? "2"
        expect(details["collections"]["staff_members"][0]["id"]).not_to be_nil
      end
    end

    it "contains pages" do
      expect(details["pages"].length).to eq(8)
      page_urls = details["pages"].map { |page| page["url"] }.join(",")
      expect(page_urls).to(
        eq("/404.html,/about/,/contact-success/,/contact/,/,/robots.txt,/services/,/terms/")
      )
    end

    it "contains static files" do
      expect(details["static"].length).to eq(1)
      expect(details["static"][0]["path"]).to eq("/static-page.html")
      expect(details["static"][0]["extname"]).to eq(".html")

      unless Jekyll::VERSION.start_with? "2"
        expect(details["static"][0]["modified_time"]).to(
          match(%r!\d{4}\-\d\d\-\d\d \d\d:\d\d:\d\d [+-]\d{4}!)
        )
      end
    end
  end

  context "specific data" do
    let(:site_data) { { :cloudcannon => { "data" => { "company" => true } } } }

    it "contains a single data entry" do
      expect(details["data"].keys.length).to eq(1)
      expect(details["data"]["company"]).not_to be_nil
    end
  end

  def log_schema_error(v)
    puts
    puts "issue: Pointer '#{v["data_pointer"]}' doesn't match the schema:"
    puts "data: #{v["data"]}"
    puts "schema: #{v["schema"]}"
  end

  schema = Pathname.new("spec/build-configuration-schema.json")
  schemer = JSONSchemer.schema(schema, ref_resolver: "net/http")

  context "full config data" do
    it "matches the schema" do
      schemer.validate(config).each { |v| log_schema_error(v) }
      expect(schemer.valid?(config)).to eq(true)
    end

    it "has populated source" do
      expect(config["source"]).not_to be_nil
    end

    it "has populated timezone" do
      expect(config["timezone"]).to eq("Etc/UTC")
    end

    it "has populated include" do
      expect(config["include"].length).not_to eq(0)
    end

    it "has populated exclude" do
      expect(config["exclude"].length).not_to eq(0)
    end

    it "has populated base-url" do
      expect(config["base-url"]).to eq("basic")
    end

    it "has populated collections" do
      if Jekyll::VERSION.start_with? "2"
        expect(config["collections"].length).to eq(1)
      else
        expect(config["collections"].length).to eq(2)
        expect(config["collections"]["posts"]).not_to be_nil
        expect(config["collections"]["posts"]["output"]).to eq(true)
      end

      staff_members = config["collections"]["staff_members"];
      expect(staff_members).not_to be_nil
      expect(staff_members["output"]).to eq(false)
      expect(staff_members["_sort-key"]).to eq("name")
      expect(staff_members["_singular-name"]).to eq("staff_member")
    end

    it "has populated comments" do
      expect(config["comments"]).to eq({
        "heading_image" => "This image should be related to the content"
      })
    end

    it "has populated editor" do
      expect(config["editor"]).to eq({ "default-path" => "basic" })
    end

    it "has populated source-editor" do
      expect(config["source-editor"]).to eq({
        "tab-size" => 2,
        "show-gutter" => false,
        "theme" => "dawn"
      })
    end

    it "has populated explore" do
      expect(config["explore"]["groups"]).to eq([
        { "heading" => "Blogging", "collections" => ["posts", "drafts"] },
        { "heading" => "Other", "collections" => ["pages", "staff_members"] }
      ])
    end

    it "has populated paths" do
      expect(config["paths"]["uploads"]).to eq("uploads")

      if Jekyll::VERSION.start_with? "2"
        expect(config["paths"]["plugins"]).to be_nil
        expect(config["paths"]["data"]).to be_nil
        expect(config["paths"]["collections"]).to be_nil
        expect(config["paths"]["includes"]).to be_nil
        expect(config["paths"]["layouts"]).to be_nil
      elsif Jekyll::VERSION.match? %r!3\.[0-4]\.!
        expect(config["paths"]["plugins"]).to eq("_plugins")
        expect(config["paths"]["data"]).to eq("_data")
        expect(config["paths"]["collections"]).to be_nil
        expect(config["paths"]["includes"]).to eq("_includes")
        expect(config["paths"]["layouts"]).to eq("_layouts")
      else
        expect(config["paths"]["plugins"]).to eq("_plugins")
        expect(config["paths"]["data"]).to eq("_data")
        expect(config["paths"]["collections"]).to eq("")
        expect(config["paths"]["includes"]).to eq("_includes")
        expect(config["paths"]["layouts"]).to eq("_layouts")
      end

      expect(config["paths"].keys.length).to eq(6)
    end

    it "has populated array-structures" do
      expect(config["array-structures"]["gallery"]).to eq({
        "style" => "select",
        "values" => [
          {
            "label" => "Image",
            "image" => "/path/to/source-image.png",
            "value" => {
              "image" => "/placeholder.png",
              "caption" => nil
            }
          },
          {
            "label" => "External link",
            "icon" => "link",
            "value" => {
              "url" => nil,
              "title" => nil
            }
          }
        ]
      })

      expect(config["array-structures"].keys.length).to eq(1)
    end

    it "has populated select-data" do
      expect(config["select-data"]).to eq({
        "things" => ["hello", "there"],
        "staff" => ["jim", "bob"]
      })
    end
  end

  context "empty config data" do
    let(:site_data) {
      {
        :skip_config_files => true,
        :config => "spec/fixtures/_config-empty.yml"
      }
    }

    it "matches the schema" do
      schemer.validate(config).each { |v| log_schema_error(v) }
      expect(schemer.valid?(config)).to eq(true)
    end

    it "has no timezone" do
      expect(config).not_to have_key("timezone")
    end

    it "has no base-url" do
      if Jekyll::VERSION.start_with?("2") || Jekyll::VERSION.match?(%r!3\.[0-4]\.!)
        expect(config["base-url"]).to eq("")
      else
        expect(config).not_to have_key("base-url")
      end
    end

    it "has no non-default collections" do
      if Jekyll::VERSION.start_with? "2"
        expect(config["collections"].length).to eq(0)
      else
        expect(config["collections"].length).to eq(1)
        expect(config["collections"]["posts"]).not_to be_nil
        expect(config["collections"]["posts"]["output"]).to eq(true)
      end
    end

    it "has no comments" do
      expect(config).not_to have_key("comments")
    end

    it "has no editor" do
      expect(config).not_to have_key("editor")
    end

    it "has no source-editor" do
      expect(config).not_to have_key("source-editor")
    end

    it "has no explore" do
      expect(config).not_to have_key("explore")
    end

    it "has no uploads path" do
      expect(config["paths"]["uploads"]).to be_nil
      expect(config["paths"].keys.length).to eq(6)
    end

    it "has no array-structures" do
      expect(config).not_to have_key("array-structures")
    end

    it "has no select-data" do
      expect(config).not_to have_key("select-data")
    end
  end

  context "config data with _select_data key" do
    let(:site_data) { { :_select_data => {
      "news" => { "first" => "yes", "second" => "no" }
    } } }

    it "has select-data from new format" do
      expect(config["select-data"]).to eq({
        "news" => {
          "first" => "yes",
          "second" => "no"
        }
      })
    end
  end

  context "config data with custom collections_dir" do
    let(:site_data) { { :collections_dir => "collections" } }

    it "has collections path" do
      expect(config["paths"]["collections"]).to eq("collections")
    end
  end
end
