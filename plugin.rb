# name: discourse-sso-provider-group
# about: Restrict SSO provider to users in specific groups
# version: 0.1
# authors: richard@discoursehosting.com
# url: https://github.com/discoursehosting/discourse-sso-provider-group

enabled_site_setting :sso_provider_group_enabled
#hide_plugin if self.respond_to?(:hide_plugin)


after_initialize do
  module ::OverrideSSOProvider
    def self.in_allowed_group(user)
      allowed_groups = SiteSetting.sso_provider_group_allowed_groups.split('|')

      user.groups.each do |group|
        return true if allowed_groups.include?(group.name)
      end
      false
    end

    def sso_provider(payload = nil)
      if SiteSetting.sso_provider_group_enabled
        if current_user
          return render body: "You are not allowed to authenticate", status: 403 unless OverrideSSOProvider::in_allowed_group current_user
          super(payload)
        else
          cookies[:sso_payload] = request.query_string
          redirect_to path('/login')
        end
      else
        super(payload)
      end
    end
  end

  class ::SessionController
    prepend OverrideSSOProvider
  end

end
