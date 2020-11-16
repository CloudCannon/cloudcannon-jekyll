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

  def log_schema_error(error)
    # Expecting here rather than logging means it get output in the test results
    log = "'#{error["data_pointer"]}' schema mismatch: (data: #{error["data"]})"\
      " (schema: #{error["schema"]})"
    expect(log).to be_nil
  end

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

    details_schema = Pathname.new("spec/build-details-schema.json")
    details_schemer = JSONSchemer.schema(details_schema, :ref_resolver => "net/http")

    it "matches the schema" do
      details_schemer.validate(details).each { |v| log_schema_error(v) }
      expect(details_schemer.valid?(details)).to eq(true)
    end

    it "contains valid time" do
      expect(details["time"]).to match(%r!\d{4}\-\d\d\-\d\dT\d\d:\d\d:\d\d[+-]\d\d:\d\d!)
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
      expect(details["collections"]["posts"]).not_to be_nil
      expect(details["collections"]["staff_members"]).not_to be_nil
      expect(details["collections"]["drafts"]).not_to be_nil
      expect(details["collections"].length).to eq(3)

      first_post = details["collections"]["posts"][0]
      expect(first_post.key?("content")).to eql(false)
      expect(first_post.key?("output")).to eql(false)
      expect(first_post.key?("next")).to eql(false)
      expect(first_post.key?("previous")).to eql(false)
      expect(first_post.key?("excerpt")).to eql(false)
      expect(first_post["tags"]).to eq(["hello"])
      expect(first_post["date"]).to(
        match(%r!\d{4}\-\d\d\-\d\d \d\d:\d\d:\d\d [+-]\d{4}!)
      )

      if Jekyll::VERSION.start_with? "2."
        expect(first_post["categories"]).to eq(["business"])
      else
        expect(first_post["categories"]).to eq(["Business"])
      end

      first_staff_member = details["collections"]["staff_members"][0]
      expect(first_staff_member["path"]).not_to be_nil
      expect(first_staff_member["name"]).to eql("Jane Doe")

      first_draft = details["collections"]["drafts"][0]
      expect(first_draft["path"]).to eql("_drafts/incomplete.md")
      expect(first_draft["title"]).to eql("WIP")

      second_draft = details["collections"]["drafts"][1]
      expect(second_draft["path"]).to eql("other/_drafts/testing-for-category.md")
      expect(second_draft["title"]).to eql("Testing for category drafts")

      expect(details["collections"]["drafts"].length).to eql(2)
    end

    it "contains pages" do
      expect(details["pages"].length).to eq(8)
      page_urls = details["pages"].map { |page| page["url"] }.join(",")
      expect(page_urls).to(
        eq("/404.html,/about/,/contact-success/,/contact/,/,/robots.txt,/services/,/terms/")
      )
    end

    it "contains static files" do
      expect(details["static-pages"].length).to eq(1)
      expect(details["static-pages"][0]["path"]).to eq("static-page.html")
      expect(details["static-pages"][0]["url"]).to eq("/static-page.html")
    end
  end

  context "specific data" do
    let(:site_data) { { :cloudcannon => { "data" => { "company" => true } } } }

    it "contains a single data entry" do
      expect(details["data"].keys.length).to eq(1)
      expect(details["data"]["company"]).not_to be_nil
    end
  end

  # Tests for the config file

  config_schema = Pathname.new("spec/build-configuration-schema.json")
  config_schemer = JSONSchemer.schema(config_schema, :ref_resolver => "net/http")

  context "full config data" do
    it "matches the schema" do
      config_schemer.validate(config).each { |v| log_schema_error(v) }
      expect(config_schemer.valid?(config)).to eq(true)
    end

    it "contains valid time" do
      expect(details["time"]).to match(%r!\d{4}\-\d\d\-\d\dT\d\d:\d\d:\d\d[+-]\d\d:\d\d!)
    end

    it "contains gem information" do
      expect(details["cloudcannon"]["name"]).to eq("cloudcannon-jekyll")
      expect(details["cloudcannon"]["version"]).to eq(CloudCannonJekyll::VERSION)
    end

    it "has populated source" do
      # Usually this would be output without a trailing slash, but spec_helper.rb
      # does some overwriting which doesn't fully replicate a normal build.
      expect(config["source"]).to eq("/spec/fixtures")
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
      collections = config["collections"]

      posts = collections["posts"]
      expect(posts).not_to be_nil
      expect(posts["output"]).to eq(true)
      expect(posts["_path"]).to eq("_posts")

      category_other_posts = collections["other/posts"]
      expect(category_other_posts).not_to be_nil
      expect(category_other_posts["output"]).to eq(true)
      expect(category_other_posts["_path"]).to eq("other/_posts")

      category_other_drafts = collections["other/drafts"]
      expect(category_other_drafts).not_to be_nil
      expect(category_other_drafts["output"]).to eq(true)
      expect(category_other_drafts["_path"]).to eq("other/_drafts")

      drafts = collections["drafts"]
      expect(drafts).not_to be_nil
      expect(drafts["_path"]).to eq("_drafts")

      data = collections["data"]
      expect(data).not_to be_nil
      expect(data["_path"]).to eq("_data")

      staff_members = collections["staff_members"]
      expect(staff_members).not_to be_nil
      expect(staff_members["output"]).to eq(false)
      expect(staff_members["_path"]).to eq("_staff_members")
      expect(staff_members["_sort-key"]).to eq("name")
      expect(staff_members["_singular-name"]).to eq("staff_member")

      expect(collections.length).to eq(6)
    end

    it "has populated comments" do
      expect(config["comments"]).to eq({
        "heading_image" => "This image should be related to the content",
      })
    end

    it "has populated editor" do
      expect(config["editor"]).to eq({ "default-path" => "basic" })
    end

    it "has populated source-editor" do
      expect(config["source-editor"]).to eq({
        "tab-size"    => 2,
        "show-gutter" => false,
        "theme"       => "dawn",
      })
    end

    it "has populated explore" do
      expect(config["explore"]["groups"]).to eq([
        { "heading" => "Blogging", "collections" => %w(posts drafts) },
        { "heading" => "Other", "collections" => %w(pages staff_members) },
      ])
    end

    it "has populated paths" do
      expect(config["paths"]["uploads"]).to eq("uploads")
      expect(config["paths"]["pages"]).to eq("")

      if Jekyll::VERSION.start_with? "2."
        expect(config["paths"]["plugins"]).to be_nil
        expect(config["paths"]["data"]).to be_nil
        expect(config["paths"]["collections"]).to be_nil
        expect(config["paths"]["includes"]).to be_nil
        expect(config["paths"]["layouts"]).to be_nil
      elsif %r!3\.[0-5]\.! =~ Jekyll::VERSION
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

      expect(config["paths"].keys.length).to eq(7)
    end

    it "has populated array-structures" do
      expect(config["array-structures"]["gallery"]).to eq({
        "style"  => "select",
        "values" => [
          {
            "label" => "Image",
            "image" => "/path/to/source-image.png",
            "value" => {
              "image"   => "/placeholder.png",
              "caption" => nil,
              "nested"  => {
                "thing" => {
                  "which" => {
                    "keeps" => {
                      "nesting" => {
                        "beyond" => {
                          "what" => {
                            "would" => {
                              "is" => {
                                "likely" => {
                                  "usually" => "hello",
                                },
                              },
                            },
                          },
                        },
                      },
                    },
                  },
                },
              },
            },
          },
          {
            "label" => "External link",
            "icon"  => "link",
            "value" => {
              "url"   => nil,
              "title" => nil,
            },
          },
        ],
      })

      expect(config["array-structures"].keys.length).to eq(1)
    end

    it "has populated select-data" do
      expect(config["select-data"]).to eq({
        "cards_per_rows" => {
          "2" => "Two",
          "3" => "Three",
          "4" => "Four",
          "6" => "Six",
        },
        "categories"     => %w(forever strings),
        "things"         => %w(hello there),
        "staff"          => %w(jim bob),
      })
    end

    it "has populated input-options" do
      expect(config["input-options"]).to eq({
        "content" => { "image" => true, "bold" => true },
        "my_html" => {
          "italic" => true,
          "bold"   => true,
          "styles" => "hello.css",
        },
      })
    end

    it "has populated defaults" do
      expect(config["defaults"]).to eq([
        {
          "scope"  => { "path" => "" },
          "values" => { "layout" => "page" },
        },
        {
          "scope"  => { "path" => "", "type" => "posts" },
          "values" => { "layout" => "post" },
        },
      ])
    end
  end

  # Tests for when the config file is almost empty
  context "empty config data" do
    let(:site_data) do
      {
        :skip_config_files => true,
        :config            => "spec/fixtures/_config-almost-empty.yml",
      }
    end

    it "matches the schema" do
      config_schemer.validate(config).each { |v| log_schema_error(v) }
      expect(config_schemer.valid?(config)).to eq(true)
    end

    it "has no timezone" do
      expect(config).not_to have_key("timezone")
    end

    it "has no base-url" do
      if Jekyll::VERSION.start_with?("2.") || (%r!3\.[0-4]\.! =~ Jekyll::VERSION)
        expect(config["base-url"]).to eq("")
      else
        expect(config).not_to have_key("base-url")
      end
    end

    it "has no non-default collections" do
      expected_collections = %w(posts drafts data other/posts other/drafts)
      expected_collections.each do |collection|
        expect(config["collections"][collection]).not_to be_nil
      end
      expect(config["collections"].length).to eq(expected_collections.length)
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
      expect(config["paths"].keys.length).to eq(7)
    end

    it "has no array-structures" do
      expect(config).not_to have_key("array-structures")
    end

    it "has no select-data" do
      expect(config).not_to have_key("select-data")
    end

    it "has no input-options" do
      expect(config).not_to have_key("input-options")
    end

    it "has no defaults" do
      expect(config["defaults"]).to eq([])
    end
  end

  context "config data with _select_data key" do
    let(:site_data) do
      {
        :_select_data => { "news" => { "first" => "yes", "second" => "no" } },
      }
    end

    it "has select-data from new format" do
      expect(config["select-data"]).to eq({
        "news" => {
          "first"  => "yes",
          "second" => "no",
        },
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
