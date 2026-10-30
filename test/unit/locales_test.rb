require File.expand_path("../test_helper", __dir__)

# The label keys of the plugin that every language file has to hold, so that a page of the plugin
# does not show "translation missing" in any of the languages.
class LocalesTest < ActiveSupport::TestCase
  LOCALE_FILES = Dir[File.expand_path("../../config/locales/*.yml", __dir__)].freeze
  REQUIRED_KEYS = %w[label_baseline label_baseline_none].freeze
  LANGUAGES = LOCALE_FILES.map { |path| File.basename(path, ".yml") }.freeze

  def test_the_plugin_has_language_files
    assert_equal %w[cs en es ja pt zh], LOCALE_FILES.map { |path| File.basename(path, ".yml") }.sort
  end

  # The English file is the reference: every other language has all of its keys, and no key of its
  # own, so that a misspelled key does not leave a message untranslated.
  def test_every_language_file_has_the_keys_of_the_english_file
    english = labels_of("en").keys
    (LANGUAGES - %w[en]).each do |language|
      keys = labels_of(language).keys
      assert_empty english - keys, "#{language}.yml lacks keys of en.yml"
      assert_empty keys - english, "#{language}.yml has keys that en.yml does not have"
    end
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

  private

  def labels_of(language)
    path = File.expand_path("../../config/locales/#{language}.yml", __dir__)
    YAML.safe_load(File.read(path, encoding: "bom|utf-8")).fetch(language)
  end
end
