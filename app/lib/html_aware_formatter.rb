# frozen_string_literal: true

class HtmlAwareFormatter
  STATUS_MIME_TYPES = %w(text/plain text/markdown text/x.misskeymarkdown text/html).freeze

  attr_reader :text, :local, :options

  alias local? local

  # @param [String] text
  # @param [Boolean] local
  # @param [Hash] options
  def initialize(text, local, options = {})
    @text    = text
    @local   = local
    @options = options.merge({local: local})
  end

  def to_s
    if local?
      linkify
    else
      reformat
    end
  rescue ArgumentError
    ''.html_safe
  end

  private

  def reformat
    return ''.html_safe if text.blank?

    if %w(text/markdown text/x.misskeymarkdown).include?(@options[:content_type])
      html = AdvancedTextFormatter.new(text, options).to_s
    else
      html = text
    end
    Sanitize.fragment(html, Sanitize::Config::MASTODON_STRICT).html_safe
  end

  def linkify
    if %w(text/markdown text/x.misskeymarkdown text/html).include?(@options[:content_type])
      html = AdvancedTextFormatter.new(text, options).to_s
    else
      html = TextFormatter.new(text, options).to_s
    end
    Sanitize.fragment(html, Sanitize::Config::MASTODON_OUTGOING).html_safe
  end
end
