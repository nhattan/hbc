class Ability
  include CanCan::Ability

  def initialize(user)
    alias_action :create, :read, :update, :destroy, to: :crud

    if user.is_a? Admin
      admin_rules(user)
    elsif user.is_a? User
      user_rules(user)
    else
      guest_rules(user)
    end
  end

  def admin_rules(user)
    can :manange, :all
  end

  def user_rules(user)
    can :read, :all
    can :crud, [User]
  end

  def guest_rules(user)
    can :read, :all
  end
end
