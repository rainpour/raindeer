# frozen_string_literal: true

module Rain
  module Events
    # A multipart/form-data body, which a form with a file input sends: its fields as strings and its files as
    # UploadedFile, by their names as symbols. A name sent more than once, like several files from one input, gives an
    # array. A file input left empty is left out.
    module Multipart
      UploadedFile = Data.define(:filename, :content_type, :data)

      def self.parse(body, boundary)
        parts = body.b.split("--#{boundary}")[1...-1] || []
        parts.each_with_object({}) do |part, fields|
          name, value = field(part)
          next unless name

          fields[name] = fields.key?(name) ? [*fields[name], value] : value
        end
      end

      # A part's name and value, or nil for a part without a name or an empty file input.
      def self.field(part)
        head, data = part.delete_prefix("\r\n").split("\r\n\r\n", 2)
        return unless data

        disposition = head[/^content-disposition:[^\r\n]*/i].to_s
        name = disposition[/\bname="([^"]*)"/, 1]
        filename = disposition[/\bfilename="([^"]*)"/, 1]
        data = data.delete_suffix("\r\n")
        return unless name
        return [name.to_sym, data.force_encoding(Encoding::UTF_8)] unless filename
        return if filename.empty?

        [name.to_sym, UploadedFile.new(filename:, content_type: head[/^content-type:\s*([^\r\n]+)/i, 1], data:)]
      end
    end
  end
end
