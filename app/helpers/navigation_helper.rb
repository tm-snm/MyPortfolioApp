module NavigationHelper
  def sidebar_navigation?
    user_signed_in? && !%w[home pages].include?(controller_path)
  end

  def current_navigation_item
    case controller_path
    when "cards"
      if %w[new new_from_ai preview_from_ai create].include?(action_name)
        :create_card
      elsif action_name == "index" && @review_filter == "due"
        :review
      else
        :cards
      end
    when "prompt_templates" then :prompts
    when "dashboards" then :dashboard
    when "users/registrations", "account_deletions" then :account
    end
  end

  def navigation_link(label, path, item, exact: false, classes: "site-nav-link")
    current = (exact ? "page" : "location") if current_navigation_item == item
    link_to label, path, class: classes, aria: { current: current }
  end
end
