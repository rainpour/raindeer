# frozen_string_literal: true

module Rain
  # Reads a request's header from its list of fields, like "host", rather than with "request.headers['host']", which
  # indexes and parses every header the first time any is read. LowLoop has already refused a request with a header
  # repeated that can't be, so the first of one like "host" is the only one.
  module RequestHeader
    module_function

    # The first value of the header, or nil.
    def first(request, name)
      request.headers.fields.each { |key, value| return value if named?(key, name) }
      nil
    end

    # Every value of a header that can be repeated, like "accept-language", joined with commas, or nil.
    def joined(request, name)
      values = nil
      request.headers.fields.each { |key, value| (values ||= []) << value if named?(key, name) }
      values&.join(',')
    end

    # Header names are ASCII, so they're compared with casecmp, as casecmp? folds Unicode case into new strings.
    def named?(key, name)
      key = key.to_s
      key.length == name.length && key.casecmp(name) == 0
    end
  end
end
