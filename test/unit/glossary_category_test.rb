# coding: utf-8
require File.expand_path('../../test_helper', __FILE__)

class GlossaryCategoryTest < ActiveSupport::TestCase
  fixtures :glossary_categories
  plugin_fixtures :glossary_categories

  def setup
    @category = glossary_categories('color')
  end
  
  def test_valid
    assert !@category.valid?
  end
end
