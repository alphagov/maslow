class Ability
  include CanCan::Ability

  def initialize(user)
    can %i[read index see_revisions_of], Need

    can %i[index create], :bookmark if user.viewer?

    if user.editor?
      can %i[perform_actions_on create update unpublish redraft], Need
      can :create, Note
    end

    can %i[publish discard], Need if user.admin?
  end
end
