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
    mocked_now = Time.parse('2024-01-01 00:00:00 +1300')
    allow(Time).to receive(:now).and_return(mocked_now)
    allow(File).to receive(:mtime).and_return(mocked_now)
    stub_const('CloudCannonJekyll::VERSION', '*.*.*')
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

  context 'with configuration' do
    let(:expected_keys) do
      %w[time version cloudcannon generator paths collections_config collection_groups collections
         data source timezone base_url _inputs _editables _select_data _structures
         editor source_editor defaults]
    end

    context 'from json config file' do
      let(:fixture) { 'json-config' }
      let(:config_path) { source_dir('json-config/cloudcannon.config.json') }

      it 'should generate info' do
        check_fixture(fixture, expected_keys, info)
      end
    end

    context 'from yaml config file' do
      let(:fixture) { 'yaml-config' }
      let(:config_path) { source_dir('yaml-config/cloudcannon.config.yml') }

      it 'should generate info' do
        check_fixture(fixture, expected_keys, info)
      end
    end

    context 'from site config' do
      let(:fixture) { 'site-config' }

      it 'should generate info' do
        check_fixture(fixture, expected_keys, info)
      end
    end

    context 'from no config' do
      let(:fixture) { 'no-config' }
      let(:expected_keys) do
        %w[time version cloudcannon generator paths collections_config collections data source
           timezone base_url defaults]
      end

      it 'should generate info' do
        check_fixture(fixture, expected_keys, info)
      end
    end

    context 'containing collections_config_override' do
      let(:fixture) { 'collections-config-override' }
      let(:config_path) { source_dir('collections-config-override/cloudcannon.config.yml') }

      it 'should generate info' do
        check_fixture(fixture, expected_keys, info)
      end
    end
  end

  context 'with legacy' do
    let(:expected_keys) do
      %w[time version cloudcannon generator paths collections_config
         collection_groups collections data source timezone base_url _select_data
         editor source_editor _array_structures _comments _options defaults]
    end

    context 'base' do
      let(:fixture) { 'legacy' }

      it 'should generate info' do
        check_fixture(fixture, expected_keys, info)
      end
    end

    context 'custom collections directory' do
      let(:fixture) { 'legacy-collections-dir' }

      it 'should generate info' do
        # collections_dir was introduced in version 3.5
        if !Jekyll::VERSION.start_with?('2.') && !Jekyll::VERSION.match?(/3\.[0-4]\./)
          check_fixture(fixture, expected_keys, info)
        end
      end
    end
  end
end
