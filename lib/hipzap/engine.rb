require 'time'
require 'xrc'
require 'hipzap/renderer/standard'

module HipZap
  class Engine
    def initialize(config: config, renderer: renderer = Renderer::Standard.new(config))
      @config = config
      @renderer = renderer

      @room_name = {}

      xrc_params = {
        jid: @config.user_jid,
        nickname: @config.nickname,
        password: @config.delete_field(:password),
        room_jid: @config.room_jid_string,
      }

      if @config.hosts
        xrc_params[:hosts] = @config.hosts
      end

      @client = Xrc::Client.new(xrc_params)
    end

    def run
      setup
      @client.connect
    end

    private

    def setup
      if @config.debug
        ss_out = lambda { |s| puts @renderer.render_sending_stream(s) }

        Xrc::Connection.class_eval do
          @@ss_out = ss_out
          def write(object)
            @@ss_out.call(object.to_s)
            socket << object.to_s
          end
        end
      end

      @client.on_event do |element|
        on_event(element)
      end

      @client.on_room_message do |message|
        on_room_message(message)
      end

      @client.on_private_message do |message|
        on_private_message(message)
      end

      @client.on_subject do |message|
        on_subject(message)
      end

      @client.on_invite do |message|
        on_invite(message)
      end
    end

    def on_event(element)
      if @config.debug
        puts @renderer.render_received_stream(element)
      end

      if element.name == "presence"
        # rescue room name from presence of owner
        from_jid = element.attribute('from').to_s
        if from_jid =~ %r{\A ( \S+@#{@config['muc_domain']} ) /?}x
          room_jid = $1
          room_name = element.elements["//name/text()"]
          if ! room_name.nil? && ! room_name.empty?
            @room_name[room_jid] = room_name
          end
        end
      end
    end

    def on_room_message(message)
      return unless message.from =~ %r{\A (\S+@#{@config.muc_domain}) / (.+) \z}x
      room_jid, sender_nick = $1, $2
      room_name = @room_name[room_jid] || room_jid

      if message.delayed?   # replay log
        stamp = message.element.elements['delay'].attribute('stamp').to_s.split(/\s/, 2)[0]
        time = Time.iso8601(stamp)

        show_log *@renderer.render_room_message(
                   room_name: room_name,
                   body: message.body,
                   sender_nick: sender_nick,
                   replay: true,
                 ),
                 time: time
      else
        time = Time.now

        show_log *@renderer.render_room_message(
                   room_name: room_name,
                   body: message.body,
                   sender_nick: sender_nick,
                 ),
                 time: time
      end
    end

    def on_private_message(message)
      from = @client.users[normalize_jid(message.from)]
      room_name = from.name

      if message.delayed?
        delay = message.element.elements['delay']
        stamp = delay.attribute('stamp').to_s.split(/\s/, 2)[0]
        time = Time.iso8601(stamp)

        sender_jid = normalize_jid(delay.attribute('from_jid').to_s)

        show_log *@renderer.render_dm(
                   room_name: room_name,
                   body: message.body,
                   sender_name: @client.users[sender_jid].mention_name,
                   recipient: from.mention_name,
                 ),
                 time: time
      else
        time = Time.now

        show_log *@renderer.render_dm(
                   room_name: room_name,
                   body: message.body,
                   sender_name: from.mention_name,
                 ),
                 time: time
      end
    end

    def on_subject(message)
      return unless @config.show_topic

      topic = message.subject
      return if topic.empty?

      room_jid = normalize_jid(message.from)
      room_name = @room_name[room_jid] || room_jid

      if message.delayed?
        delay = message.element.elements['delay']
        stamp = delay.attribute('stamp').to_s.split(/\s/, 2)[0]
        time = Time.iso8601(stamp)

        sender_jid = normalize_jid(delay.attribute('from_jid').to_s)

        show_log *@renderer.render_topic(
                   room_name: room_name,
                   topic: topic,
                   sender_name: @client.users[sender_jid].name,
                 ),
                 time: time
      else
        time = Time.now

        show_log *@renderer.render_topic(
                   room_name: room_name,
                   topic: topic,
                 ),
                 time: time
      end
    end

    def on_invite(message)
      room_jid = normalize_jid(message.from)
      @room_name[room_jid] = message.room_name
      show_log "invited to #{message.room_name}"

      if @config.auto_join
        @client.join(room_jid)
      end
    end

    def normalize_jid(jid_str)
      jid_str.to_s.split('/', 2)[0]
    end

    def show_log(*tokens, time: Time.now)
      time = time.localtime
      puts [ @renderer.render_timestamp(time), *tokens ].join(" ")
    end
  end
end
