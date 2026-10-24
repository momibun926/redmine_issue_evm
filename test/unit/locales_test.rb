require File.expand_path("../test_helper", __dir__)

# The label keys of the plugin that every language file has to hold, so that a page of the plugin
# does not show "translation missing" in any of the languages.
class LocalesTest < ActiveSupport::TestCase
  LOCALE_FILES = Dir[File.expand_path("../../config/locales/*.yml", __dir__)].freeze
  REQUIRED_KEYS = %w[label_baseline label_baseline_none].freeze

  def test_the_plugin_has_language_files
    assert_equal %w[cs en es ja pt zh], LOCALE_FILES.map { |path| File.basename(path, ".yml") }.sort
  end

  def test_every_language_file_has_the_label_keys
    LOCALE_FILES.each do |path|
      language = File.basename(path, ".yml")
      labels = YAML.safe_load(File.read(path, encoding: "bom|utf-8")).fetch(language)
      REQUIRED_KEYS.each do |key|
        assert labels[key].present?, "#{path} has no #{key}"
      end
    end
  end
end
