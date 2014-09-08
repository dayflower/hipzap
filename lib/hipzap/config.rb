require 'ostruct'

module HipZap
  class Config < OpenStruct
    def initialize(config)
      config = config.dup

      config['rooms'] ||= []

      config['muc_domain'] ||= "conf.hipchat.com"

      if config['host']
        config['hosts'] ||= []
        config['hosts'] << config['host']
      end

      super(config)
    end

    def user_jid
      jid = self.jid
      if ! self.playback_recent
        jid += '/bot'
      end
      jid
    end

    def room_jid_string
      self.rooms.map { |id| "#{id}@#{self.muc_domain}" }.join(',')
    end
  end
end
