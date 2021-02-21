# frozen_string_literal: true

require "spec_helper"

describe CloudCannonJekyll::Configuration do
  # Tests for the configuration step

  let(:site) { make_site(site_data) }
  before { site.process }
  let(:plugins_key) do
    if Jekyll::VERSION.start_with? "2."
      "gems"
    else
      "plugins"
    end
  end

  context "configuration" do
    let(:site_data) do
      if Jekyll::VERSION.start_with? "2."
        { :gems => ["cloudcannon-jekyll"] }
      else
        { :plugins => ["cloudcannon-jekyll"] }
      end
    end

    it "sets the unduplicated cloudcannon-jekyll plugin" do
      expect(site.config[plugins_key]).to eq(["cloudcannon-jekyll"])
    end
  end

  context "configuration by default" do
    let(:site_data) { {} }

    it "sets the cloudcannon-jekyll plugin" do
      expect(site.config[plugins_key]).to eq(["cloudcannon-jekyll"])
    end
  end
end
