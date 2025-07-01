# frozen_string_literal: true

class RolePolicy < ApplicationPolicy
  def index?
    user.present?
  end

  def show?
    user.present?
  end

  def create?
    user.present?
  end

  def update?
    user.present? && !record.default?
  end

  def destroy?
    user.present? && !record.default?
  end

  class Scope < Scope
    def resolve
      scope.all
    end
  end
end 