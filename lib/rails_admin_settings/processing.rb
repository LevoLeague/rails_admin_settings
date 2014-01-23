module RailsAdminSettings
  module Processing
    RailsAdminSettings.types.each do |dtype|
      define_method "#{dtype}_type?" do
        dtype == type
      end
    end

    def text_type?
      (RailsAdminSettings.types - ['phone', 'phones', 'integer', 'yaml', 'boolean']).include? type
    end

    def upload_type?
      ['file', 'image'].include? type
    end

    def html_type?
      ['html', 'sanitized'].include? type
    end

    def boolean_type?
      type == 'boolean'
    end

    def value
      if upload_type?
        if file?
          file.url
        else
          nil
        end
      elsif raw.blank? || disabled?
        default_value
      else
        processed_value
      end
    end

    def blank?
      if file_type?
        file.url.nil?
      elsif raw.blank? || disabled?
        true
      else
        false
      end
    end

    def to_s
      if yaml_type? || phone_type? || integer_type?
        raw
      else
        value
      end
    end

    private

    def sanitize_value
      require_sanitize do
        self.raw = Sanitize.clean(value, Sanitize::Config::RELAXED)
      end
    end

    def default_value
      if html_type?
        ''.html_safe
      elsif text_type?
        ''
      elsif integer_type?
        0
      elsif boolean_type?
        false
      elsif yaml_type?
        nil
      elsif phone_type?
        require_russian_phone do
          RussianPhone::Number.new('')
        end
      elsif phones_type?
        []
      else
        nil
      end
    end

    def default_serializable_value
      if phones_type?
        ''
      elsif boolean_type?
        'false'
      else
        default_value
      end
    end

    def process_text
      text = raw.dup
      text.gsub!('{{year}}', Time.now.strftime('%Y'))
      text.gsub! /\{\{year\|([\d]{4})\}\}/ do
        if Time.now.strftime('%Y') == $1
          $1
        else
          "#{$1}-#{Time.now.strftime('%Y')}"
        end
      end
      text = text.html_safe if html_type?
      text
    end

    def load_phone
      require_russian_phone do
        RussianPhone::Number.new(raw)
      end
    end

    def load_phones
      require_russian_phone do
        raw.gsub("\r", '').split("\n").map{|i| RussianPhone::Number.new(i)}
      end
    end

    def load_yaml
      require_safe_yaml do
        YAML.safe_load(raw)
      end
    end

    def processed_value
      if text_type?
        process_text
      elsif integer_type?
        raw.to_i
      elsif boolean_type?
        raw == 'true'
      elsif yaml_type?
        load_yaml
      elsif phone_type?
        load_phone
      elsif phones_type?
        load_phones
      elsif file_type?
        file.url
      else
        puts "[rails_admin_settings] Unknown field type: #{type}"
        nil
      end
    end

    def self.included(base)
      base.class_eval do
        alias_method :val, :value
      end
    end
  end
end
