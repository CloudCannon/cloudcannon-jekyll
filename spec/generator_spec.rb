# frozen_string_literal: true

require "spec_helper"

describe CloudCannonJekyll::Generator do
  let(:site) { make_site(site_data) }
  before { site.process }
  let(:content) { File.read(dest_dir("_cloudcannon/details.json")) }

  context "creates" do
    let(:site_data) { {} }

    it "a details file" do
      expect(Pathname.new(dest_dir("_cloudcannon/details.json"))).to exist
    end

    it "details without data" do
      expect(content.scan(%r!"data": {"!).length).to eq(0)
    end

    it "details without unsupported items" do
      expect(content.scan(%r!UNSUPPORTED!).length).to eq(0)
    end
  end

  context "options" do
    let(:site_data) { { :cloudcannon => { "data" => true } } }

    it "allow details with data" do
      expect(content.scan(%r!"data": {"!).length).to eq(1)
    end

    it "allow details with data without unsupported items" do
      expect(content.scan(%r!UNSUPPORTED!).length).to eq(0)
    end
  end

  context "content" do
    let(:site_data) { { :cloudcannon => { "data" => true } } }
    let(:parsed) { JSON.parse(content) }

    it "contains valid time" do
      expect(parsed["time"]).to match(%r!\d{4}\-\d\d\-\d\d \d\d:\d\d:\d\d [+-]\d{4}!)
    end

    it "contains gem information" do
      expect(parsed["cloudcannon"]["name"]).to eq("cloudcannon-jekyll")
      expect(parsed["cloudcannon"]["version"]).to eq(CloudCannonJekyll::VERSION)
    end

    it "contains generator information" do
      expect(parsed["generator"]["name"]).to eq("jekyll")
      expect(parsed["generator"]["version"]).to match(%r![2-4]\.\d+\.\d+!)
      expect(parsed["generator"].key?("environment")).to eql(true)
      expect(parsed["generator"]["metadata"]["markdown"]).to eql("kramdown")
      expect(parsed["generator"]["metadata"]["kramdown"]).not_to be_nil
      expect(parsed["generator"]["metadata"]["commonmark"]).to be_nil
    end

    it "contains data" do
      expect(parsed["data"].keys.length).to eq(2)
      expect(parsed["data"]["company"]).not_to be_nil
      expect(parsed["data"]["footer"]).not_to be_nil
    end

    it "contains collections" do
      expect(parsed["collections"].keys.length).to eq(2)

      expect(parsed["collections"]["posts"]).not_to be_nil
      expect(parsed["collections"]["posts"][0]["tags"]).to eq(["hello"])
      expect(parsed["collections"]["posts"][0]["date"]).to(
        match(%r!\d{4}\-\d\d\-\d\d \d\d:\d\d:\d\d [+-]\d{4}!)
      )

      if Jekyll::VERSION.start_with? "2"
        expect(parsed["collections"]["posts"][0]["categories"]).to eq(["business"])
      else
        expect(parsed["collections"]["posts"][0]["categories"]).to eq(["Business"])
      end

      expect(parsed["collections"]["staff_members"]).not_to be_nil
      unless Jekyll::VERSION.start_with? "2"
        expect(parsed["collections"]["staff_members"][0]["id"]).not_to be_nil
      end
    end

    it "contains pages" do
      expect(parsed["pages"].length).to eq(8)
      page_urls = parsed["pages"].map { |page| page["url"] }.join(",")
      expect(page_urls).to(
        eq("/404.html,/about/,/contact-success/,/contact/,/,/robots.txt,/services/,/terms/")
      )
    end

    it "contains static files" do
      expect(parsed["static"].length).to eq(1)
      expect(parsed["static"][0]["path"]).to eq("/static-page.html")
      expect(parsed["static"][0]["extname"]).to eq(".html")

      unless Jekyll::VERSION.start_with? "2"
        expect(parsed["static"][0]["modified_time"]).to(
          match(%r!\d{4}\-\d\d\-\d\d \d\d:\d\d:\d\d [+-]\d{4}!)
        )
      end
    end
  end

  context "specific data" do
    let(:site_data) { { :cloudcannon => { "data" => { "company" => true } } } }
    let(:parsed) { JSON.parse(content) }

    it "contains a single data entry" do
      expect(parsed["data"].keys.length).to eq(1)
      expect(parsed["data"]["company"]).not_to be_nil
    end
  end
end
