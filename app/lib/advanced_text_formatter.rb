# frozen_string_literal: true

class AdvancedTextFormatter < TextFormatter
  attr_reader :content_type

  # @param [String] text
  # @param [Hash] options
  # @option options [Boolean] :multiline
  # @option options [Boolean] :with_domains
  # @option options [Boolean] :with_rel_me
  # @option options [Array<Account>] :preloaded_accounts
  # @option options [String] :content_type
  def initialize(text, options = {})
    @content_type = options.delete(:content_type)
    @tags = options.delete(:tags) || []
    @status = options[:status]
    if @status.is_a?(StatusEdit)
      @status = @status.status
    end
    @local = options.delete(:local)
    super

    parse_tags_from_mentions
  end

  def parse_tags_from_mentions
    return if @status.nil?

    @status.mentions.each do |mention|
      next unless AccountSearchService::MENTION_ONLY_RE.match?(mention.name)
      account = mention.account
      next if account.nil?

      @tags << {'type' => 'Mention', 'name' => mention.name, 'href' => account.uri}
    end
  end

  def is_mfm?
    content_type == 'text/x.misskeymarkdown'
  end

  # does some tags and quote stuff, but keeps the source text intact otherwise
  def to_source_s
    return '' if text.blank?

    result = text.dup

    result
  end

  # Differs from TextFormatter by not messing with newline after parsing
  def to_s
    @text = format_markdown(text) if %w(text/markdown text/x.misskeymarkdown).include?(content_type)
    return add_quote_fallback('').html_safe if text.blank? # rubocop:disable Rails/OutputSafety

    html = rewrite do |entity|
      if entity[:hashtag] || entity[:tag_type] == 'Hashtag'
        link_to_hashtag(entity)
      elsif entity[:screen_name] || entity[:tag_type] == 'Mention'
        link_to_mention(entity)
      elsif entity[:url]
        link_to_url(entity)
      end
    end

    html = add_quote_fallback(html) if options[:quoted_status].present?

    html
  end

  # Differs from TextFormatter by operating on the parsed HTML tree
  def rewrite
    if @tree.nil?
      src = text.gsub(Sanitize::REGEX_UNSUITABLE_CHARS, '')
      @tree = Nokogiri::HTML5.fragment(src)
      document = @tree.document

      if is_mfm?
        @tree.xpath('.//em').each do |node|
          node.node_name = 'i'
        end
        @tree.xpath('.//strong').each do |node|
          node.node_name = 'b'
        end
      end

      @tree.xpath('.//text()[not(ancestor::a | ancestor::code)]').each do |text_node|
        # Iterate over text elements and build up their replacements.
        content = text_node.content
        replacement = Nokogiri::XML::NodeSet.new(document)
        processed_index = 0
        Extractor.extract_entities_with_indices(
          content,
          extract_url_without_protocol: false,
          tags: @tags
        ) do |entity|
          # Iterate over entities in this text node.
          advance = entity[:indices].first - processed_index
          if advance.positive?
            # Text node for content which precedes entity.
            replacement << Nokogiri::XML::Text.new(
              content[processed_index, advance],
              document
            )
          end
          replacement << Nokogiri::HTML5.fragment(yield(entity))
          processed_index = entity[:indices].last
        end
        if processed_index < content.size
          # Text node for remaining content.
          replacement << Nokogiri::XML::Text.new(
            content[processed_index, content.size - processed_index],
            document
          )
        end
        text_node.replace(replacement)
      end
    end

    return @tree.to_html
  end

  private

  def format_markdown(html)
    html = markdown_formatter.render(html)
    html.delete("\r").delete("\n")
  end

  def markdown_formatter
    MastodonRustStuff::MarkdownRenderer.new({mfm: is_mfm?})
  end
end
