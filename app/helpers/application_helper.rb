module ApplicationHelper
  def nav_link(name, path)
    link_to name, path, class: "nav-link", aria: { current: ("page" if current_page?(path)) }
  end

  def expiry_label(lot)
    return "No expiry" unless lot.expiry_date

    badge = tag.span("Expired", class: "badge badge-danger") if lot.expired?
    safe_join([ lot.expiry_date.iso8601, badge ].compact, " ")
  end
end
