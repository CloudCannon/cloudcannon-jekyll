# frozen_string_literal: true

require "spec_helper"
require "json_schemer"
require "pathname"

describe CloudCannonJekyll::Generator do
  # Tests for the config file

  let(:fixture) { "standard" }
  let(:site_data) { {} }
  let(:site) { make_site(site_data, fixture) }
  let(:config_raw) { File.read(dest_dir("_cloudcannon/config.json")) }
  let(:config) { JSON.parse(config_raw) }
  before { site.process }

  config_schema = Pathname.new("spec/build-configuration-schema.json")
  config_schemer = JSONSchemer.schema(config_schema, :ref_resolver => "net/http")

  context "config" do
    it "exists" do
      expect(Pathname.new(dest_dir("_cloudcannon/config.json"))).to exist
    end

    it "matches the schema" do
      config_schemer.validate(config).each { |v| log_schema_error(v) }
      expect(config_schemer.valid?(config)).to eq(true)
    end

    it "has source" do
      # Usually this would be output without a trailing slash, but spec_helper.rb
      # does some overwriting which doesn't fully replicate a normal build.
      expect(config["source"]).to eq("/spec/fixtures/standard")
    end

    it "has timezone" do
      expect(config["timezone"]).to eq("Etc/UTC")
    end

    it "has include" do
      expect(config["include"].length).not_to eq(0)
    end

    it "has exclude" do
      expect(config["exclude"].length).not_to eq(0)
    end

    it "has base-url" do
      expect(config["base-url"]).to eq("basic")
    end

    it "has collections" do
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
      expect(drafts["title"]).to be_nil

      pages = collections["pages"]
      expect(pages).not_to be_nil
      expect(pages["_path"]).to eq("_pages")
      expect(pages["title"]).to be_nil
      expect(pages["output"]).to eq(true)

      data = collections["data"]
      expect(data).not_to be_nil
      expect(data["_path"]).to eq("_data")

      staff_members = collections["staff_members"]
      expect(staff_members).not_to be_nil
      expect(staff_members["output"]).to eq(false)
      expect(staff_members["_path"]).to eq("_staff_members")
      expect(staff_members["_sort-key"]).to eq("name")
      expect(staff_members["_singular-name"]).to eq("staff_member")

      empty = collections["empty"]
      expect(empty).not_to be_nil
      expect(empty["_path"]).to eq("_empty")

      expect(collections.length).to eq(8)
    end

    it "has comments" do
      expect(config["comments"]).to eq({
        "heading_image" => "This image should be related to the content",
      })
    end

    it "has editor" do
      expect(config["editor"]).to eq({ "default-path" => "basic" })
    end

    it "has source editor" do
      expect(config["source-editor"]).to eq({
        "tab-size"    => 2,
        "show-gutter" => false,
        "theme"       => "dawn",
      })
    end

    it "has explore groups" do
      expect(config["collections"]["posts"]["_group"]).to eq("Blogging")
      expect(config["collections"]["drafts"]["_group"]).to eq("Blogging")
      expect(config["collections"]["pages"]["_group"]).to eq("Other")
      expect(config["collections"]["staff_members"]["_group"]).to eq("Other")
    end

    it "has paths" do
      expect(config["paths"]["uploads"]).to eq("uploads")
      expect(config["paths"]["pages"]).to eq("")

      if Jekyll::VERSION.start_with? "2."
        expect(config["paths"]["plugins"]).to be_nil
        expect(config["paths"]["data"]).to be_nil
        expect(config["paths"]["collections"]).to be_nil
        expect(config["paths"]["includes"]).to be_nil
        expect(config["paths"]["layouts"]).to be_nil
      elsif Jekyll::VERSION.match? %r!3\.[0-5]\.!
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

    it "has array-structures" do
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

    it "has select data" do
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

    it "has input options" do
      expect(config["input-options"]).to eq({
        "content" => { "image" => true, "bold" => true },
        "my_html" => {
          "italic" => true,
          "bold"   => true,
          "styles" => "hello.css",
        },
      })
    end

    it "has defaults" do
      expect(config["defaults"]).to eq([
        {
          "scope"  => { "path" => "" },
          "values" => { "layout" => "page" },
        },
        {
          "scope"  => { "path" => "", "type" => "posts" },
          "values" => {
            "layout" => "post",
            "nested1" => {
              "nested2" => {
                "nested3" => {
                  "nested4" => {
                    "nested5" => {
                      "nested6" => "MAXIMUM_DEPTH"
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
                ]
              }
            }
          }
        },
      ])
    end
  end

  context "config with posts collection" do
    let(:site_data) { { :collections => { "posts" => { "title" => "Blog Posts" } } } }

    it "does not override drafts" do
      drafts = config["collections"]["drafts"]
      expect(drafts).not_to be_nil
      expect(drafts["_path"]).to eq("_drafts")
      expect(drafts["title"]).to be_nil

      posts = config["collections"]["posts"]
      expect(posts).not_to be_nil
      expect(posts["_path"]).to eq("_posts")
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
      config_schemer.validate(config).each { |v| log_schema_error(v) }
      expect(config_schemer.valid?(config)).to eq(true)
    end

    it "has no timezone" do
      expect(config).not_to have_key("timezone")
    end

    it "has no base url" do
      if Jekyll::VERSION.start_with?("2.") || Jekyll::VERSION.match?(%r!3\.[0-4]\.!)
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

    it "has no array structures" do
      expect(config).not_to have_key("array-structures")
    end

    it "has no select data" do
      expect(config).not_to have_key("select-data")
    end

    it "has no input options" do
      expect(config).not_to have_key("input-options")
    end

    it "has no defaults" do
      expect(config["defaults"]).to eq([])
    end
  end

  context "config with select data" do
    let(:site_data) do
      {
        :_select_data => { "news" => { "first" => "yes", "second" => "no" } },
      }
    end

    it "has select data" do
      expect(config["select-data"]).to eq({
        "news" => {
          "first"  => "yes",
          "second" => "no",
        },
      })
    end
  end

  context "config with custom collections dir" do
    let(:site_data) { { :collections_dir => "collections" } }

    it "has collections path" do
      expect(config["paths"]["collections"]).to eq("collections")
    end
  end
end
