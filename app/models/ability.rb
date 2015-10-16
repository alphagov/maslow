class Ability
  include CanCan::Ability

  def initialize(user)
    can [:read, :index, :see_revisions_of], Need

    can [:index, :create], :bookmark if user.viewer?

    if user.editor?
      can [:create, :update, :close, :reopen, :perform_actions_on], Need
      can :create, Note
    end

    can :validate, Need if user.admin?
  end
end
