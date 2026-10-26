module ApplicationHelper
  def nav_link(name, path)
    link_to name, path, class: "nav-link", aria: { current: ("page" if current_page?(path)) }
  end
end
