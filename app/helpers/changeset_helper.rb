class ChangeSet
  attr_reader :current, :previous

  def initialize(current, previous)
    @current = current
    @previous = previous
  end

  # This method returns the changes between the current revision and its
  # previous revision as a hash of arrays. Each array contains the previous value,
  # followed by the value for the current revision. For example:
  #
  #   {
  #     :role => [ "driver", "vehicle owner" ],
  #     :goal => [ "Pay my car tax", nil ],
  #     :benefit => [ nil, "I can drive my car" ],
  #   }
  #
  def changes
    versions = [@previous, @current]

    keys = changed_keys - ["version"]

    keys.inject({}) { |changes, key|
      changes.merge(key => versions.map {|version| version[key] })
    }
  end

  private

  def changed_keys
    (@current.keys | @previous.keys).reject { |key|
      @current[key] == @previous[key]
    }
  end
end
