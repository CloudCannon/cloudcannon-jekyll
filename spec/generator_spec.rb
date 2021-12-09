# frozen_string_literal: true

require 'fileutils'
require 'json'
require 'pathname'
require 'spec_helper'

describe CloudCannonJekyll::Generator do
  # Tests for the generator

  let(:fixture) { 'empty' }
  let(:config_path) { nil }
  let(:site) { make_site({}, fixture, config_path) }
  let(:info_raw) { File.read(dest_dir(fixture, '_cloudcannon/info.json')) }
  let(:info) { JSON.parse(info_raw) }
  before do
    allow(Time).to receive(:now).and_return(Time.parse('2024-01-01 00:00:00 +1300'))
    site&.process
  end

  def check_fixture(fixture, expected_keys, info)
    expect(info.keys.sort).to eq(expected_keys.sort)

    expected_dir = File.expand_path('expected', __dir__)
    expected = JSON.parse(File.read(File.join(expected_dir, Jekyll::VERSION, "#{fixture}.json")))

    expected_keys.each do |key|
      expect(info[key]).to eq(expected[key])
    end
  end

  context 'configuration from' do
    let(:expected_keys) do
      %w[time version cloudcannon generator paths collections_config collection_groups collections
         data source timezone base_url _inputs _editables _select_data _structures
         editor source_editor defaults]
    end

    context 'json config file' do
      let(:fixture) { 'json-config' }
      let(:config_path) { source_dir('json-config/cloudcannon.config.json') }

      it 'generates info' do
        check_fixture(fixture, expected_keys, info)
      end
    end

    context 'yaml config file' do
      let(:fixture) { 'yaml-config' }
      let(:config_path) { source_dir('yaml-config/cloudcannon.config.yml') }

      it 'generates info' do
        check_fixture(fixture, expected_keys, info)
      end
    end

    context 'site config' do
      let(:fixture) { 'site-config' }

      it 'generates info' do
        check_fixture(fixture, expected_keys, info)
      end
    end

    context 'no config' do
      let(:fixture) { 'no-config' }
      let(:expected_keys) do
        %w[time version cloudcannon generator paths collections_config collections data source
           timezone base_url defaults]
      end

      it 'generates info' do
        check_fixture(fixture, expected_keys, info)
      end
    end
  end

  context 'legacy' do
    let(:fixture) { 'legacy' }
    let(:expected_keys) do
      %w[time version cloudcannon generator paths collections_config
         collection_groups collections data source timezone base_url _select_data
         editor source_editor _array_structures _comments _options defaults]
    end

    it 'generates info' do
      check_fixture(fixture, expected_keys, info)
    end
  end

  context 'legacy with collections_dir' do
    let(:fixture) { 'legacy-collections-dir' }
    let(:expected_keys) do
      %w[time version cloudcannon generator paths collections_config
         collection_groups collections data source timezone base_url _select_data
         editor source_editor _array_structures _comments _options defaults]
    end

    it 'generates info' do
      # collections_dir was introduced in version 3.5
      if !Jekyll::VERSION.start_with?('2.') && !Jekyll::VERSION.match?(/3\.[0-4]\./)
        check_fixture(fixture, expected_keys, info)
      end
    end
  end
end
