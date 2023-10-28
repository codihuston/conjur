# frozen_string_literal: true

require 'casbin-ruby'

module AuthorizeResource
  extend ActiveSupport::Concern
  
  included do
    include CurrentUser
  end
  
  def authorize privilege, resource = self.resource
    auth(current_user, privilege, resource)
  end

  def authorize_many(resources, privilege)
    resources.each do |resource|
      auth(current_user, privilege, resource)
    end
  end

  private

  def auth(user, privilege, resource)
    # TODO: cache / singleton
    puts "QWE"
    puts user.role_id
    puts privilege
    puts resource.resource_id
    enforcer = Casbin::Enforcer.new("./dev/casbin-model.conf", "./dev/casbin-policy.csv")
    # TODO: replace with casbin call
    # unless user.allowed_to?(privilege, resource)

    if enforcer.enforce(user.role_id, resource.resource_id, privilege)
      # permit alice to read data1
      # do something
    else
      logger.info(
        Errors::Authentication::Security::RoleNotAuthorizedOnResource.new(
          user.role_id,
          privilege,
          resource.resource_id
        )
      )
      raise ApplicationController::Forbidden
    end
  end
end
