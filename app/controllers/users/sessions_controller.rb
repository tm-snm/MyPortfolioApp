module Users
  class SessionsController < Devise::SessionsController
    include AuthenticationRateLimiting
  end
end
