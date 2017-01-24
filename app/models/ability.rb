class Ability
  include CanCan::Ability

  def initialize(user)
    can [:read, :index, :see_revisions_of], Need

    can [:index, :create], :bookmark if user.viewer?

    if user.editor?
      can [:perform_actions_on, :create, :update, :unpublish, :redraft], Need
      can :create, Note
    end

    can [:publish, :discard], Need if user.admin?
  end
end
