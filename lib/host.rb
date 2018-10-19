module Host
  TRUSTED_HOST_REGEXES = Rails.application.secrets.trusted_hosts.map do |host|
    /\A(.*\.)?#{host.gsub('.', '\.')}\z/
  end

  def self.trusted?(url)
    uri = Addressable::URI.parse url

    TRUSTED_HOST_REGEXES.any? { |regex| regex.match uri.host }
  end
end