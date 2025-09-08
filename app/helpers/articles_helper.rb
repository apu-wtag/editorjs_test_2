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
        escaped_code = CGI.escapeHTML(block["data"]["code"])
        language = block["data"]["languageCode"] || "plaintext" # Fallback to plaintext if no languageCode
        "<pre><code class=\"language-#{language}\">#{escaped_code}</code></pre>"

      when "image"
        data = block['data']
        file = data['file']
        caption = CGI.escapeHTML(data['caption'] || '')
        with_border = data['withBorder'] ? 'border border-gray-300 rounded' : ''
        with_background = data['withBackground'] ? 'bg-gray-100 p-4' : ''
        stretched = data['stretched'] ? 'w-full mx-auto' : 'max-w-3xl mx-auto'
        "<figure class=\"#{stretched} my-8\"><img src=\"#{file['url']}\" alt=\"#{caption}\" class=\"w-full h-auto #{with_border} #{with_background}\"><figcaption class=\"text-center text-gray-500 mt-2\">#{caption}</figcaption></figure>"

      when "attaches"
        data = block['data']
        file = data['file']
        title = CGI.escapeHTML(data['title'] || file['name'])
        "<div class=\"my-4\"><a href=\"#{file['url']}\" download class=\"text-blue-600 hover:underline\">#{title} (#{file['extension']}, #{number_to_human_size(file['size'])})</a></div>"

      when "embed"
        data = block['data']
        "<div class=\"my-8 max-w-3xl mx-auto\"><iframe src=\"#{data['embed']}\" width=\"#{data['width']}\" height=\"#{data['height']}\" frameborder=\"0\" allowfullscreen class=\"w-full\"></iframe><p class=\"text-center text-gray-500 mt-2\">#{CGI.escapeHTML(data['caption'] || '')}</p></div>"

      when "quote"
        data = block['data']
        if data["caption"] != ""
          "<blockquote class=\"my-8 border-l-4 border-gray-300 pl-4 italic text-gray-700\">#{data['text']}<cite class=\"block text-right mt-2 text-gray-500\">— #{CGI.escapeHTML(data['caption'])}</cite></blockquote>"
        else
          "<blockquote class=\"my-8 border-l-4 border-gray-300 pl-4 italic text-gray-700\">#{data['text']}</blockquote>"
        end

      when "delimiter"
        "<div class=\"my-8 text-center text-3xl tracking-wider text-black-300\">***</div>"
      when "table"
        data = block['data']
        content = data['content']
        with_headings = data['withHeadings']
        table_rows = content.map.with_index do |row, index|
          cells = row.map do |cell|
            # Sanitize cell content to allow b, i, a tags
            sanitized_cell = sanitize(cell, tags: %w[b i a], attributes: %w[href])
            "<#{with_headings && index == 0 ? 'th' : 'td'} class=\"border border-gray-300 px-4 py-2 #{with_headings && index == 0 ? 'font-bold bg-gray-100' : 'bg-white'}\">#{sanitized_cell}</#{with_headings && index == 0 ? 'th' : 'td'}>"
          end.join
          "<tr class=\"#{index.even? ? 'bg-gray-50' : 'bg-white'}\">#{cells}</tr>"
        end.join
        "<div class=\"my-8 max-w-3xl mx-auto overflow-x-auto\"><table class=\"w-full border-collapse border border-gray-300\">#{table_rows}</table></div>"
      else
        ""
      end
    end
    content_html.join.html_safe
  end
  def extract_summary_from_editorjs(content_json, length: 150)
    return "" if content_json.blank?

    summary_text = "" # Initialize an empty string to build our summary

    begin
      content_hash = JSON.parse(content_json)
      blocks = content_hash["blocks"] || []

      blocks.each do |block|
        text_content = nil
        case block["type"]
        when "paragraph", "header", "quote"
          text_content = block.dig("data", "text")
        when "code"
          text_content = block.dig("data", "code")
        when "list"
          items = block.dig("data", "items")
          text_content = items.is_a?(Array) ? items.join(" ") : nil
        end
        if text_content.present?
          clean_text = sanitize(text_content, tags: []) # Strip any HTML
          summary_text += clean_text + " " # Add the text and a space
        end
        break if summary_text.length >= length
      end
      return truncate(summary_text, length: length, separator: ' ')
    rescue StandardError => e
      Rails.logger.error "Failed to parse article summary: #{e.message}"
      ""
    end
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
