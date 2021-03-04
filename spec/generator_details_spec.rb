# frozen_string_literal: true

require "spec_helper"
require "json_schemer"
require "pathname"

describe CloudCannonJekyll::Generator do
  # Tests for the details file

  let(:fixture) { "standard" }
  let(:site_data) { {} }
  let(:site) { make_site(site_data, fixture) }
  let(:details_raw) { File.read(dest_dir("_cloudcannon/details.json")) }
  let(:details) { JSON.parse(details_raw) }
  before { site.process }

  details_schema = Pathname.new("spec/build-details-schema.json")
  details_schemer = JSONSchemer.schema(details_schema, :ref_resolver => "net/http")

  context "details" do
    it "exists" do
      expect(Pathname.new(dest_dir("_cloudcannon/details.json"))).to exist
    end

    it "matches schema" do
      details_schemer.validate(details).each { |v| log_schema_error(v) }
      expect(details_schemer.valid?(details)).to eq(true)
    end

    it "has no data" do
      expect(details_raw.scan(%r!"data": {"!).length).to eq(0)
    end

    it "has no unsupported items" do
      expect(details_raw.scan(%r!UNSUPPORTED!).length).to eq(0)
    end

    it "has valid time" do
      expect(details["time"]).to match(%r!\d{4}\-\d\d\-\d\dT\d\d:\d\d:\d\d[+-]\d\d:\d\d!)
    end

    it "has gem information" do
      expect(details["cloudcannon"]["name"]).to eq("cloudcannon-jekyll")
      expect(details["cloudcannon"]["version"]).to eq(CloudCannonJekyll::VERSION)
    end

    it "has generator information" do
      expect(details["generator"]["name"]).to eq("jekyll")
      expect(details["generator"]["version"]).to match(%r![2-4]\.\d+\.\d+!)
      expect(details["generator"].key?("environment")).to eq(true)
      expect(details["generator"]["metadata"]["markdown"]).to eq("kramdown")
      expect(details["generator"]["metadata"]["kramdown"]).not_to be_nil
      expect(details["generator"]["metadata"]["commonmark"]).to be_nil
    end


    it "has collections" do
      expect(details["collections"]["posts"]).not_to be_nil
      expect(details["collections"]["staff_members"]).not_to be_nil
      expect(details["collections"]["drafts"]).not_to be_nil
      expect(details["collections"]["empty"]).not_to be_nil
      expect(details["collections"]["pages"]).not_to be_nil
      expect(details["collections"].length).to eq(5)

      first_post = details["collections"]["posts"][0]
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

      first_staff_member = details["collections"]["staff_members"][0]
      expect(first_staff_member["path"]).to eq("_staff_members/jane-doe.md")
      expect(first_staff_member["name"]).to eq("Jane Doe")

      first_draft = details["collections"]["drafts"][0]
      expect(first_draft["path"]).to eq("_drafts/incomplete.md")
      expect(first_draft["title"]).to eq("WIP")

      second_draft = details["collections"]["drafts"][1]
      expect(second_draft["path"]).to eq("other/_drafts/testing-for-category.md")
      expect(second_draft["title"]).to eq("Testing for category drafts")

      expect(details["collections"]["drafts"].length).to eq(2)

      first_collection_page = details["collections"]["pages"][0]
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
          ]
        }
      })

      expect(details["collections"]["pages"].length).to eq(1)
    end

    it "has pages" do
      page_urls = details["pages"].map { |page| page["url"] }.join(",")
      expect(page_urls).to(
        eq("/404.html,/about/,/contact-success/,/contact/,/,/services/,/terms/")
      )
      expect(details["pages"].length).to eq(7)
    end

    it "has static files" do
      expect(details["static-pages"].length).to eq(1)
      expect(details["static-pages"][0]["path"]).to eq("static-page.html")
      expect(details["static-pages"][0]["url"]).to eq("/static-page.html")
    end
  end

  context "details with custom collections_dir" do
    let(:fixture) { "collections-dir" }

    it "has collections" do
      # collections_dir was introduced in version 3.5
      unless Jekyll::VERSION.start_with?("2.") || Jekyll::VERSION.match?(%r!3\.[0-4]\.!)
        first_post = details["collections"]["posts"][0]
        expect(first_post["path"]).to eq("collections/_posts/2016-08-10-business-mergers.md")

        first_staff_member = details["collections"]["staff_members"][0]
        expect(first_staff_member["path"]).to eq("collections/_staff_members/jane-doe.md")

        first_draft = details["collections"]["drafts"][0]
        expect(first_draft["path"]).to eq("collections/_drafts/incomplete.md")

        # This doesn't seem to be supported when using a collections_dir, perhaps it should be?
        #second_draft = details["collections"]["drafts"][1]
        #expect(second_draft["path"]).to eq("collections/other/_drafts/testing-for-category.md")
        #expect(details["collections"]["drafts"].length).to eq(2)

        first_collection_page = details["collections"]["pages"][0]
        expect(first_collection_page["path"]).to eq("collections/_pages/page-item.md")
        expect(details["collections"]["pages"].length).to eq(1)

        expect(details["collections"].length).to eq(5)
      end
    end
  end

  context "details with data enabled" do
    let(:site_data) { { :cloudcannon => { "data" => true } } }

    it "has data" do
      expect(details_raw.scan(%r!"data": {"!).length).to eq(1)
      expect(details_raw.scan(%r!UNSUPPORTED!).length).to eq(0)

      expect(details["data"]["company"]).not_to be_nil
      expect(details["data"]["footer"]).not_to be_nil
      expect(details["data"].keys.length).to eq(2)
    end
  end

  context "details with specific data enabled" do
    let(:site_data) { { :cloudcannon => { "data" => { "company" => true } } } }

    it "has single data" do
      expect(details["data"]["company"]).not_to be_nil
      expect(details["data"].keys.length).to eq(1)
    end
  end
end
