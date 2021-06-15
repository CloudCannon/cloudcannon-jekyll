# frozen_string_literal: true

require "spec_helper"
require "json_schemer"
require "pathname"

describe CloudCannonJekyll::Generator do
  # Tests for the generator

  let(:fixture) { "standard" }
  let(:site_data) { {} }
  let(:site) { make_site(site_data, fixture) }
  let(:info_raw) { File.read(dest_dir("_cloudcannon/info.json")) }
  let(:info) { JSON.parse(info_raw) }
  before { site.process }

  schema = Pathname.new("spec/build-info-schema.json")
  schemer = JSONSchemer.schema(schema, :ref_resolver => "net/http")

  context "info" do
    it "exists" do
      expect(Pathname.new(dest_dir("_cloudcannon/info.json"))).to exist
    end

    it "has no data" do
      expect(info["data"]).to be_nil
    end

    it "has no unsupported items" do
      expect(info_raw.scan(%r!UNSUPPORTED!).length).to eq(0)
    end

    it "has valid time" do
      expect(info["time"]).to match(%r!\d{4}\-\d\d\-\d\dT\d\d:\d\d:\d\d[+-]\d\d:\d\d!)
    end

    it "has gem information" do
      expect(info["cloudcannon"]["name"]).to eq("cloudcannon-jekyll")
      expect(info["cloudcannon"]["version"]).to eq(CloudCannonJekyll::VERSION)
    end

    it "has generator information" do
      expect(info["generator"]["name"]).to eq("jekyll")
      expect(info["generator"]["version"]).to match(%r![2-4]\.\d+\.\d+!)
      expect(info["generator"].key?("environment")).to eq(true)
      expect(info["generator"]["metadata"]["markdown"]).to eq("kramdown")
      expect(info["generator"]["metadata"]["kramdown"]).not_to be_nil
      expect(info["generator"]["metadata"]["commonmark"]).to be_nil
    end

    it "has collections" do
      expect(info["collections"]["posts"]).not_to be_nil
      expect(info["collections"]["staff_members"]).not_to be_nil
      expect(info["collections"]["drafts"]).not_to be_nil
      expect(info["collections"]["empty"]).not_to be_nil
      expect(info["collections"]["pages"]).not_to be_nil
      expect(info["collections"].length).to eq(5)

      first_post = info["collections"]["posts"][0]
      expect(first_post.key?("content")).to eq(false)
      expect(first_post.key?("output")).to eq(false)
      expect(first_post.key?("next")).to eq(false)
      expect(first_post.key?("previous")).to eq(false)
      expect(first_post.key?("excerpt")).to eq(false)
      expect(first_post["id"]).to eq("/business/2016/08/10/business-mergers")
      expect(first_post["url"]).to eq("/business/2016/08/10/business-mergers/")
      expect(first_post["path"]).to eq("_posts/2016-08-10-business-mergers.md")
      expect(first_post["tags"]).to eq(["hello"])
      expect(first_post["date"]).to(
        match(%r!\d{4}\-\d\d\-\d\d \d\d:\d\d:\d\d [+-]\d{4}!)
      )

      if Jekyll::VERSION.start_with? "2."
        expect(first_post["categories"]).to eq(["business"])
      else
        expect(first_post["categories"]).to eq(["Business"])
      end

      first_staff_member = info["collections"]["staff_members"][0]
      expect(first_staff_member["path"]).to eq("_staff_members/jane-doe.md")
      expect(first_staff_member["name"]).to eq("Jane Doe")

      first_draft = info["collections"]["drafts"][0]
      expect(first_draft["path"]).to eq("_drafts/incomplete.md")
      expect(first_draft["title"]).to eq("WIP")

      second_draft = info["collections"]["drafts"][1]
      expect(second_draft["path"]).to eq("other/_drafts/testing-for-category.md")
      expect(second_draft["title"]).to eq("Testing for category drafts")

      expect(info["collections"]["drafts"].length).to eq(2)

      first_collection_page = info["collections"]["pages"][0]
      expect(first_collection_page["title"]).to eq("Page Item")
      expect(first_collection_page["path"]).to eq("_pages/page-item.md")
      expect(first_collection_page["_array_structures"]).to eq({
        "gallery" => {
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
        },
      })

      expect(info["collections"]["pages"].length).to eq(1)
    end

    it "has pages" do
      page_urls = info["pages"].map { |page| page["url"] }.join(",")
      expect(page_urls).to(
        eq("/404.html,/about/,/contact-success/,/contact/,/,/services/,/terms/")
      )
      expect(info["pages"].length).to eq(7)
    end

    it "has static files" do
      expect(info["static-pages"].length).to eq(1)
      expect(info["static-pages"][0]["path"]).to eq("static-page.html")
      expect(info["static-pages"][0]["url"]).to eq("/static-page.html")
    end
  end

  context "custom collections_dir" do
    let(:fixture) { "collections-dir" }

    it "has collections" do
      # collections_dir was introduced in version 3.5
      unless Jekyll::VERSION.start_with?("2.") || (%r!3\.[0-4]\.! =~ Jekyll::VERSION)
        first_post = info["collections"]["posts"][0]
        expect(first_post["path"]).to eq("collections/_posts/2016-08-10-business-mergers.md")

        first_staff_member = info["collections"]["staff_members"][0]
        expect(first_staff_member["path"]).to eq("collections/_staff_members/jane-doe.md")

        first_draft = info["collections"]["drafts"][0]
        expect(first_draft["path"]).to eq("collections/_drafts/incomplete.md")

        # This doesn't seem to be supported when using a collections_dir, perhaps it should be?
        # second_draft = info["collections"]["drafts"][1]
        # expect(second_draft["path"]).to eq("collections/other/_drafts/testing-for-category.md")
        # expect(info["collections"]["drafts"].length).to eq(2)

        first_collection_page = info["collections"]["pages"][0]
        expect(first_collection_page["path"]).to eq("collections/_pages/page-item.md")
        expect(info["collections"]["pages"].length).to eq(1)

        expect(info["collections"].length).to eq(5)
      end
    end
  end

  context "data enabled" do
    let(:site_data) { { :cloudcannon => { "data" => true } } }

    it "has data" do
      expect(info["data"]).to eq({
        "company" => {
          "title"                 => "Example",
          "description"           => "Testing things",
          "contact_email_address" => "contact@example.com",
          "contact_phone_number"  => "(03) 123 4567",
          "address"               => "123 Example Street, Gooseburb, 9876, Ducktown, New Zealand",
          "postal_address"        => "PO Box 123, Ducktown, New Zealand",
        },
        "footer"  => [
          {
            "title" => "Pages",
            "links" => [
              {
                "name" => "Home",
                "link" => "/",
              },
              {
                "name" => "About",
                "link" => "/about/",
              },
              {
                "name" => "Services",
                "link" => "/services/",
              },
              {
                "name" => "Contact",
                "link" => "/contact/",
              },
              {
                "name" => "Advice",
                "link" => "/advice/",
              },
            ],
          },
          {
            "title" => "Social",
            "links" => [
              {
                "name"        => "Facebook",
                "link"        => "http://facebook.com",
                "social_icon" => "Facebook",
                "new_window"  => true,
              },
              {
                "name"        => "Twitter",
                "link"        => "http://twitter.com",
                "social_icon" => "Twitter",
                "new_window"  => true,
              },
              {
                "name"        => "Instagram",
                "link"        => "http://instagram.com/",
                "social_icon" => "Instagram",
                "new_window"  => true,
              },
              {
                "name"        => "LinkedIn",
                "link"        => "https://linkedin.com",
                "social_icon" => "LinkedIn",
                "new_window"  => true,
              },
            ],
          },
        ],
      })

      expect(info_raw.scan(%r!UNSUPPORTED!).length).to eq(0)

      expect(info["data"]["company"]).not_to be_nil
      expect(info["data"]["footer"]).not_to be_nil
      expect(info["data"].keys.length).to eq(2)
    end

    it "matches the schema" do
      schemer.validate(info).each { |v| log_schema_error(v) }
      expect(schemer.valid?(info)).to eq(true)
    end

    it "has source" do
      # Usually this would be output without a leading slash, but spec_helper.rb
      # does some overwriting which doesn't fully replicate a normal build.
      expect(info["source"]).to eq("/spec/fixtures/standard")
    end

    it "has timezone" do
      expect(info["timezone"]).to eq("Etc/UTC")
    end

    it "has base-url" do
      expect(info["base-url"]).to eq("basic")
    end

    it "has collections-config" do
      collections = info["collections-config"]

      posts = collections["posts"]
      expect(posts).not_to be_nil
      expect(posts["output"]).to eq(true)
      expect(posts["path"]).to eq("_posts")

      category_other_posts = collections["other/posts"]
      expect(category_other_posts).not_to be_nil
      expect(category_other_posts["output"]).to eq(true)
      expect(category_other_posts["path"]).to eq("other/_posts")

      category_other_drafts = collections["other/drafts"]
      expect(category_other_drafts).not_to be_nil
      expect(category_other_drafts["output"]).to eq(true)
      expect(category_other_drafts["path"]).to eq("other/_drafts")

      drafts = collections["drafts"]
      expect(drafts).not_to be_nil
      expect(drafts["path"]).to eq("_drafts")
      expect(drafts["title"]).to be_nil

      pages = collections["pages"]
      expect(pages).not_to be_nil
      expect(pages["path"]).to eq("_pages")
      expect(pages["title"]).to be_nil
      expect(pages["output"]).to eq(true)

      data = collections["data"]
      expect(data).not_to be_nil
      expect(data["path"]).to eq("_data")

      staff_members = collections["staff_members"]
      expect(staff_members).not_to be_nil
      expect(staff_members["output"]).to eq(false)
      expect(staff_members["path"]).to eq("_staff_members")
      expect(staff_members["_sort-key"]).to eq("name")
      expect(staff_members["_singular-name"]).to eq("staff_member")

      empty = collections["empty"]
      expect(empty).not_to be_nil
      expect(empty["path"]).to eq("_empty")

      expect(collections.length).to eq(8)
    end

    it "has comments" do
      expect(info["_comments"]).to eq({
        "heading_image" => "This image should be related to the content",
      })
    end

    it "has editor" do
      expect(info["_editor"]).to eq({ "default_path" => "basic" })
    end

    it "has source editor" do
      expect(info["_source_editor"]).to eq({
        "tab_size"    => 2,
        "show_gutter" => false,
        "theme"       => "dawn",
      })
    end

    it "has collection groups" do
      expect(info["_collection_groups"]).to eq([
        {
          "heading"     => "Blogging",
          "collections" => %w(posts drafts),
        },
        {
          "heading"     => "Other",
          "collections" => %w(pages staff_members),
        },
      ])
    end

    it "has paths" do
      expect(info["paths"]["uploads"]).to eq("uploads")
      expect(info["paths"]["pages"]).to eq("")

      if Jekyll::VERSION.start_with? "2."
        expect(info["paths"]["data"]).to be_nil
        expect(info["paths"]["collections"]).to be_nil
        expect(info["paths"]["includes"]).to be_nil
        expect(info["paths"]["layouts"]).to be_nil
      elsif %r!3\.[0-5]\.! =~ Jekyll::VERSION
        expect(info["paths"]["data"]).to eq("_data")
        expect(info["paths"]["collections"]).to be_nil
        expect(info["paths"]["includes"]).to eq("_includes")
        expect(info["paths"]["layouts"]).to eq("_layouts")
      else
        expect(info["paths"]["data"]).to eq("_data")
        expect(info["paths"]["collections"]).to eq("")
        expect(info["paths"]["includes"]).to eq("_includes")
        expect(info["paths"]["layouts"]).to eq("_layouts")
      end

      expect(info["paths"].keys.length).to eq(6)
    end

    it "has array structures" do
      expect(info["_array_structures"]["gallery"]).to eq({
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
                                "likely" => { "usually" => "hello" },
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

      expect(info["_array_structures"].keys.length).to eq(1)
    end

    it "has select data" do
      expect(info["_select_data"]).to eq({
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

    it "has _options" do
      expect(info["_options"]).to eq({
        "content" => { "image" => true, "bold" => true },
        "my_html" => {
          "italic" => true,
          "bold"   => true,
          "styles" => "hello.css",
        },
      })
    end

    it "has defaults" do
      expect(info["defaults"]).to eq([
        {
          "scope"  => { "path" => "" },
          "values" => { "layout" => "page" },
        },
        {
          "scope"  => { "path" => "", "type" => "posts" },
          "values" => {
            "layout"            => "post",
            "nested1"           => {
              "nested2" => {
                "nested3" => {
                  "nested4" => {
                    "nested5" => { "nested6" => "MAXIMUM_DEPTH" },
                  },
                },
              },
            },
            "_array_structures" => {
              "gallery" => {
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
                                        "likely" => { "usually" => "hello" },
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
              },
            },
          },
        },
      ])
    end
  end

  context "config with posts collection" do
    let(:site_data) { { :collections => { "posts" => { "title" => "Blog Posts" } } } }

    it "does not override drafts" do
      drafts = info["collections-config"]["drafts"]
      expect(drafts).not_to be_nil
      expect(drafts["path"]).to eq("_drafts")
      expect(drafts["title"]).to be_nil

      posts = info["collections-config"]["posts"]
      expect(posts).not_to be_nil
      expect(posts["path"]).to eq("_posts")
      expect(posts["title"]).to eq("Blog Posts") unless Jekyll::VERSION.start_with? "2."
    end
  end

  # Tests for when the config file is almost empty
  context "config with almost no content" do
    let(:site_data) do
      {
        :skip_config_files => true,
        :config            => "spec/fixtures/standard/_config-almost-empty.yml",
      }
    end

    it "matches the schema" do
      schemer.validate(info).each { |v| log_schema_error(v) }
      expect(schemer.valid?(info)).to eq(true)
    end

    it "has no timezone" do
      expect(info).not_to have_key("timezone")
    end

    it "has no base url" do
      if Jekyll::VERSION.start_with?("2.") || (%r!3\.[0-4]\.! =~ Jekyll::VERSION)
        expect(info["base-url"]).to eq("")
      else
        expect(info).not_to have_key("base-url")
      end
    end

    it "has no non-default collections" do
      expected_collections = %w(posts drafts data other/posts other/drafts)
      expected_collections.each do |collection|
        expect(info["collections-config"][collection]).not_to be_nil
      end
      expect(info["collections-config"].length).to eq(expected_collections.length)
    end

    it "has no comments" do
      expect(info).not_to have_key("_comments")
    end

    it "has no editor" do
      expect(info).not_to have_key("_editor")
    end

    it "has no _source_editor" do
      expect(info).not_to have_key("_source_editor")
    end

    it "has no uploads path" do
      expect(info["paths"]["uploads"]).to be_nil
      expect(info["paths"].keys.length).to eq(6)
    end

    it "has no array structures" do
      expect(info).not_to have_key("_array_structures")
    end

    it "has no select data" do
      expect(info).not_to have_key("_select_data")
    end

    it "has no options" do
      expect(info).not_to have_key("_options")
    end

    it "has no defaults" do
      expect(info["defaults"]).to eq([])
    end
  end

  context "specified _select_data" do
    let(:site_data) do
      {
        :_select_data => { "news" => { "first" => "yes", "second" => "no" } },
      }
    end

    it "has specified select data" do
      expect(info["_select_data"]).to eq({
        "news" => {
          "first"  => "yes",
          "second" => "no",
        },
      })
    end
  end

  context "custom collections dir" do
    let(:site_data) { { :collections_dir => "collections" } }

    it "has collections path" do
      expect(info["paths"]["collections"]).to eq("collections")
    end
  end

  context "specific data" do
    let(:site_data) { { :cloudcannon => { "data" => { "company" => true } } } }

    it "has single data" do
      expect(info["data"]["company"]).not_to be_nil
      expect(info["data"].keys.length).to eq(1)
    end
  end
end
