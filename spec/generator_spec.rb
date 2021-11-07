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

  expected_categories = %w(Business Property other)

  # Jekyll 2 seems to lowercase categories
  expected_categories = %w(business property other) if Jekyll::VERSION.start_with? "2."

  context "info" do
    it "exists" do
      expect(Pathname.new(dest_dir("_cloudcannon/info.json"))).to exist
    end

    it "has no data" do
      expect(info["data"]).to eq({
        "categories" => expected_categories,
        "tags"       => %w(hello hi),
      })
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
      expected_keys = %w(staff_members posts empty pages drafts other/posts other/drafts)
      expect(info["collections"].keys.sort).to eq(expected_keys.sort)

      post = info["collections"]["posts"][0]
      expect(post.key?("content")).to eq(false)
      expect(post.key?("output")).to eq(false)
      expect(post.key?("next")).to eq(false)
      expect(post.key?("previous")).to eq(false)
      expect(post.key?("excerpt")).to eq(false)
      expect(post["id"]).to eq("/business/2016/08/10/business-mergers")
      expect(post["url"]).to eq("/business/2016/08/10/business-mergers/")
      expect(post["path"]).to eq("_posts/2016-08-10-business-mergers.md")
      expect(post["tags"]).to eq(["hello"])
      expect(post["date"]).to match(%r!\d{4}\-\d\d\-\d\d \d\d:\d\d:\d\d [+-]\d{4}!)
      # expect(post["collection"]).to eq("posts") # TODO

      expect(info["collections"]["posts"].length).to eq(2)
      expect(info["collections"]["other/posts"].length).to eq(1)

      if Jekyll::VERSION.start_with? "2."
        expect(post["categories"]).to eq(["business"])
      else
        expect(post["categories"]).to eq(["Business"])
      end

      staff_member = info["collections"]["staff_members"][0]
      expect(staff_member["path"]).to eq("_staff_members/jane-doe.md")
      # expect(staff_member["collection"]).to eq("staff_members") # TODO
      expect(staff_member["name"]).to eq("Jane Doe")

      draft = info["collections"]["drafts"][0]
      expect(draft["path"]).to eq("_drafts/incomplete.md")
      # expect(draft["collection"]).to eq("drafts") # TODO
      expect(draft["title"]).to eq("WIP")

      other_draft = info["collections"]["other/drafts"][0]
      expect(other_draft["path"]).to eq("other/_drafts/testing-for-category.md")
      # expect(other_draft["collection"]).to eq("other/drafts") # TODO
      expect(other_draft["title"]).to eq("Testing for category drafts")

      expect(info["collections"]["drafts"].length).to eq(1)
      expect(info["collections"]["other/drafts"].length).to eq(1)

      expect(info["collections"]["pages"][0]).to eq({
        "name"=>"404.html",
        "path" => "404.html",
        "url" => "/404.html",
        "layout" => "page",
        "title" => "Not Found",
        "call_to_action" => "Contact",
        "background_image_path" => nil,
        "large_header" => false,
        "show_in_navigation" => false,
        "permalink" => "/404.html",
        "sitemap" => false,
      })

      expect(info["collections"]["pages"].length).to eq(8)
    end

    it "has pages" do
      urls = "/404.html,/about/,/contact-success/,/contact/,/,/services/,/terms/,/static-page.html"
      page_urls = info["collections"]["pages"].map { |page| page["url"] }.join(",")
      expect(page_urls).to eq(urls)
    end
  end

  context "custom collections_dir" do
    let(:fixture) { "collections-dir" }

    it "has collections" do
      # collections_dir was introduced in version 3.5
      unless Jekyll::VERSION.start_with?("2.") || Jekyll::VERSION.match?(%r!3\.[0-4]\.!)
        post = info["collections"]["posts"][0]
        expect(post["path"]).to eq("collections/_posts/2016-08-10-business-mergers.md")

        other_post = info["collections"]["other/posts"][0]
        expect(other_post["path"]).to eq("collections/other/_posts/2020-08-10-category-test.md")

        staff_member = info["collections"]["staff_members"][0]
        expect(staff_member["path"]).to eq("collections/_staff_members/jane-doe.md")

        draft = info["collections"]["drafts"][0]
        expect(draft["path"]).to eq("collections/_drafts/incomplete.md")
        expect(info["collections"]["drafts"].length).to eq(1)

        # This doesn't seem to be supported when using a collections_dir, perhaps it should be?
        # other_draft = info["collections"]["other/drafts"][1]
        # expect(other_draft["path"]).to eq("collections/other/_drafts/testing-for-category.md")
        # expect(info["collections"]["other/drafts"].length).to eq(1)

        page = info["collections"]["pages"][0]
        expect(page["path"]).to eq("collections/_pages/page-item.md")
        expect(info["collections"]["pages"].length).to eq(1)

        expect(info["collections"].length).to eq(7)
      end
    end
  end

  context "data enabled" do
    let(:site_data) { { :cloudcannon => { "data" => true } } }

    it "has data" do
      expect(info["data"]).to eq({
        "categories" => expected_categories,
        "tags"       => %w(hello hi),
        "company"    => {
          "title"                 => "Example",
          "description"           => "Testing things",
          "contact_email_address" => "contact@example.com",
          "contact_phone_number"  => "(03) 123 4567",
          "address"               => "123 Example Street, Gooseburb, 9876, Ducktown, New Zealand",
          "postal_address"        => "PO Box 123, Ducktown, New Zealand",
        },
        "footer"     => [
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
      expect(info["data"].keys.length).to eq(4)
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
      collections_config = info["collections-config"]

      posts = collections_config["posts"]
      expect(posts).not_to be_nil
      expect(posts["output"]).to eq(true)
      expect(posts["path"]).to eq("_posts")

      category_other_posts = collections_config["other/posts"]
      expect(category_other_posts).not_to be_nil
      expect(category_other_posts["output"]).to eq(true)
      expect(category_other_posts["path"]).to eq("other/_posts")

      category_other_drafts = collections_config["other/drafts"]
      expect(category_other_drafts).not_to be_nil
      expect(category_other_drafts["output"]).to eq(true)
      expect(category_other_drafts["path"]).to eq("other/_drafts")

      drafts = collections_config["drafts"]
      expect(drafts).not_to be_nil
      expect(drafts["path"]).to eq("_drafts")
      expect(drafts["title"]).to be_nil
      expect(drafts["output"]).to eq(true)

      pages = collections_config["pages"]
      expect(pages).not_to be_nil
      expect(pages["path"]).to eq("")
      expect(pages["filter"]).to eq("strict")
      expect(pages["output"]).to eq(true)

      data = collections_config["data"]
      expect(data).not_to be_nil
      expect(data["path"]).to eq("_data")

      staff_members = collections_config["staff_members"]
      expect(staff_members).not_to be_nil
      expect(staff_members["output"]).to eq(false)
      expect(staff_members["path"]).to eq("_staff_members")
      expect(staff_members["_sort_key"]).to eq("name")
      expect(staff_members["_singular_name"]).to eq("staff_member")

      empty = collections_config["empty"]
      expect(empty).not_to be_nil
      expect(empty["path"]).to eq("_empty")

      expect(collections_config.length).to eq(8)
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
      expect(info["paths"]["static"]).to eq("")

      if Jekyll::VERSION.start_with? "2."
        expect(info["paths"]["data"]).to be_nil
        expect(info["paths"]["collections"]).to be_nil
        expect(info["paths"]["layouts"]).to be_nil
      elsif Jekyll::VERSION.match? %r!3\.[0-5]\.!
        expect(info["paths"]["data"]).to eq("_data")
        expect(info["paths"]["collections"]).to be_nil
        expect(info["paths"]["layouts"]).to eq("_layouts")
      else
        expect(info["paths"]["data"]).to eq("_data")
        expect(info["paths"]["collections"]).to eq("")
        expect(info["paths"]["layouts"]).to eq("_layouts")
      end

      expect(info["paths"].keys.length).to eq(5)
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
                    "nested5" => {
                      "nested6" => {
                        "nested7" => {
                          "nested8" => {
                            "nested9" => { "nested10" => "MAXIMUM_DEPTH" },
                          },
                        },
                      },
                    },
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
      if Jekyll::VERSION.start_with?("2.") || Jekyll::VERSION.match?(%r!3\.[0-4]\.!)
        expect(info["base-url"]).to eq("")
      else
        expect(info).not_to have_key("base-url")
      end
    end

    it "has no extra collections" do
      expected_collections = %w(posts pages drafts other/posts other/drafts data)
      expect(info["collections-config"].keys.sort).to eq(expected_collections.sort)
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
      expect(info["paths"].keys.length).to eq(5)
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
      expect(info["data"]["categories"]).to eq(expected_categories)
      expect(info["data"]["tags"]).to eq(%w(hello hi))
      expect(info["data"]["company"]).not_to be_nil
      expect(info["data"].keys.length).to eq(3)
    end
  end
end
