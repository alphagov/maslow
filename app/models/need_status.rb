require "active_model"

class NeedStatus
  extend ActiveModel::Naming
  include ActiveModel::Validations
  include ActiveModel::Conversion

  PROPOSED = "proposed"
  NOT_VALID = "not valid"
  VALID = "valid"
  VALID_WITH_CONDITIONS = "valid with conditions"

  attr_reader :description, :reasons, :additional_comments, :validation_conditions

  validates :description, inclusion: { in: [PROPOSED, NOT_VALID, VALID, VALID_WITH_CONDITIONS] },
            presence: { message: "You need to select the new status" }

  validates :reasons, if: Proc.new { |s| s.description == NOT_VALID },
            presence: { message: "A reason is required to mark a need as not valid" }
  validates :validation_conditions, if: Proc.new { |s| s.description == VALID_WITH_CONDITIONS },
            presence: { message: "The validation conditions are required to mark a need as valid with conditions" }

  def initialize(options)
    @description = options[:description]
    @reasons = options[:reasons]
    @additional_comments = options[:additional_comments]
    @validation_conditions = options[:validation_conditions]
  end

  def as_json
    additional_attributes = case description
                            when VALID then
                              if additional_comments.present?
                                { additional_comments: additional_comments }
                              else
                                {}
                              end
                            when NOT_VALID then
                              { reasons: reasons }
                            when VALID_WITH_CONDITIONS then
                              { validation_conditions: validation_conditions }
                            else
                              {}
                            end
    { description: description }.merge(additional_attributes)
  end
end
