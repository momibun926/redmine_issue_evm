require File.expand_path('../../test_helper', __FILE__)

class GlossaryTermTest < ActiveSupport::TestCase
  fixtures :glossary_terms
  plugin_fixtures :glossary_terms

  def setup
    @term = glossary_terms('red')
  end
  
  def test_valid
    assert @term.valid?
  end

  def test_invalid_without_name
    @term.name = nil
    assert_raises ActiveRecord::NotNullViolation do
      @term.save
    end
  end
end
