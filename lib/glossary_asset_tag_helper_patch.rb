module ActionView
  module Helpers
    module AssetTagHelper
      def javascript_include_tag_with_glossary(*sources)
        out = javascript_include_tag_without_glossary(*sources)
        if sources.is_a?(Array) and sources[0] == 'jstoolbar/textile'
          out += javascript_tag <<-javascript_tag
jsToolBar.prototype.elements.termlink = {
	type: 'button',
        title: '#{l(:label_tag_termlink)}',
	fn: {
		wiki: function() { this.encloseSelection("{{term(", ")}}") }
	}
}
javascript_tag
          out += stylesheet_link_tag 'termlink', :plugin => 'redmine_glossary'
        end
        out
      end
     alias_method_chain :javascript_include_tag, :glossary
    end
  end
end
