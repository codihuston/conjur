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

    # This call results in the following error...
    # This is because privilege "update" does not appear in the policy definition!
    # INFO 2023/10/28 11:32:05 +0000 [pid=663] [origin=172.18.0.2] [request_id=f6504b8e-1ecb-4fa8-a3b1-9d9dc41046e5] [tid=667] Completed 500 Internal Server Error in 4521ms (Allocations: 16921281)
    # FATAL 2023/10/28 11:32:05 +0000 [pid=663] [origin=172.18.0.2] [request_id=f6504b8e-1ecb-4fa8-a3b1-9d9dc41046e5] [tid=667]
    # [origin=172.18.0.2] [request_id=f6504b8e-1ecb-4fa8-a3b1-9d9dc41046e5] [tid=667] NoMethodError (undefined method `to_node' for :update:Symbol):
    # [origin=172.18.0.2] [request_id=f6504b8e-1ecb-4fa8-a3b1-9d9dc41046e5] [tid=667]
    # [origin=172.18.0.2] [request_id=f6504b8e-1ecb-4fa8-a3b1-9d9dc41046e5] [tid=667] app/controllers/concerns/authorize_resource.rb:34:in `auth'
    # [origin=172.18.0.2] [request_id=f6504b8e-1ecb-4fa8-a3b1-9d9dc41046e5] [tid=667] app/controllers/concerns/authorize_resource.rb:13:in `authorize'
    # [origin=172.18.0.2] [request_id=f6504b8e-1ecb-4fa8-a3b1-9d9dc41046e5] [tid=667] app/controllers/secrets_controller.rb:12:in `create'
    # [origin=172.18.0.2] [request_id=f6504b8e-1ecb-4fa8-a3b1-9d9dc41046e5] [tid=667] app/controllers/application_controller.rb:83:in `run_with_transaction'
    # [origin=172.18.0.2] [request_id=f6504b8e-1ecb-4fa8-a3b1-9d9dc41046e5] [tid=667] lib/rack/remove_request_parameters.rb:26:in `call'
    # [origin=172.18.0.2] [request_id=f6504b8e-1ecb-4fa8-a3b1-9d9dc41046e5] [tid=667] lib/rack/default_content_type.rb:78:in `call'
    if enforcer.enforce(user.role_id, resource.resource_id, "read")
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
