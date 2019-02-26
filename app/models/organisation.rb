class Organisation
  attr_reader :content_id, :title, :internal_name, :publication_state, :base_path

  def initialize(atts)
    @content_id = atts[:content_id]
    @title = atts[:title]
    @internal_name = atts[:internal_name]
    @publication_state = atts[:publication_state]
    @base_path = atts[:base_path]
  end

  def to_option
    [title_and_publication_state, content_id]
  end

  def title_and_publication_state
    suffix = (publication_state == "draft" ? " (draft)" : "")
    "#{title}#{suffix}"
  end

  def self.to_options
    all.map(&:to_option)
  end

  def self.all
    organisations.map { |atts| new(atts) }
  end

  def self.organisations
    Rails.cache.fetch('organisations') do
      response = Services.publishing_api_v2.get_linkables(
        document_type: "organisation"
      )

      (response || []).map(&:deep_symbolize_keys)
    end
  end
end
