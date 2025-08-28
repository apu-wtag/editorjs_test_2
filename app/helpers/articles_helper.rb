module ArticlesHelper
  def display_content(content)
    parsed_content = JSON.parse(content)
    content_html = parsed_content["blocks"].map do |block|
      case block["type"]
      when "paragraph"
        "<p>#{block['data']['text']}</p>"

      when "header"
        "<h#{block['data']['level']}>#{block['data']['text']}</h#{block['data']['level']}>"

      when "list"
        render_list(block["data"]["items"], block["data"]["style"])

      when "code"
        # escaped_code = CGI.escapeHTML(block["data"]["code"])
        # "<pre><code>#{escaped_code}</code></pre>"
        escaped_code = CGI.escapeHTML(block["data"]["code"])
        language = block["data"]["languageCode"] || "plaintext" # Fallback to plaintext if no languageCode
        "<pre><code class=\"language-#{language}\">#{escaped_code}</code></pre>"
      else
        ""
      end
    end
    content_html.join.html_safe
  end

  private

  def render_list(items, style = "unordered")
    list_tag = style == "ordered" ? "ol" : "ul"

    list_items = items.map do |item|
      content = item.is_a?(Hash) ? item["content"] : item
      nested  = item.is_a?(Hash) && item["items"].present? ? render_list(item["items"], style) : ""
      "<li>#{content}#{nested}</li>"
    end.join("\n")

    "<#{list_tag}>#{list_items}</#{list_tag}>"
  end
end
