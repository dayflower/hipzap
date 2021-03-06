require 'time'
require 'yaml'
require 'xrc'
require 'hipzap/renderer/standard'

module Xrc::Client::HipChatStartupExtension
  def hipchat_startup(muc_domain, auto_join = false, &block)
    iq = REXML::Element.new('iq')
    iq.attributes['type'] = 'get'
    iq.attributes['to'] = muc_domain
    query = REXML::Element.new('query')
    query.add_namespace('http://hipchat.com/protocol/startup')
    if auto_join
      query.attributes['send_auto_join_user_presences'] = true
    end
    iq.add(query)

    post(iq, &block)
  end
end

module HipZap
  class Engine
    def initialize(config: config, renderer: renderer = Renderer::Standard.new(config))
      @config = config
      @renderer = renderer

      @room_name = {}

      xrc_params = {
        jid: @config.user_jid,
        nickname: @config.nickname,
        password: @config[:password] ? @config.delete_field(:password) : nil,
        room_jid: @config.room_jid_string,
      }

      if @config.hosts
        xrc_params[:hosts] = @config.hosts
      end

      @client = Xrc::Client.new(xrc_params)
      @client.extend Xrc::Client::OnConnectedExtension
      @client.extend Xrc::Client::HipChatStartupExtension
    end

    def run
      setup

      Signal.trap(:USR1) {
        dump_rooms
        STDERR.puts "Room list dumped."
      }

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

      @client.on_connection_established do
        on_connection_established
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

    def on_connection_established
      if @config.auto_join
        muc_domain = @config.muc_domain
        @client.hipchat_startup(muc_domain, false) do |element|
          joined_rooms = element.elements["//preferences/autoJoin"]
          joined_rooms.each do |room|
            room_jid = room.attributes['jid']
            next unless room_jid.end_with?('@' + muc_domain)
            @client.join(room_jid)
            @room_name[room_jid] = room.attributes['name']
          end
        end
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
          else
            room_name = @room_name[room_jid] || room_jid
          end
        end

        error_text = element.elements["//error/text/text()"]
        if ! error_text.nil? && ! error_text.empty?
          if room_name
            show_log "<#{room_name}>", "Error:", error_text
          else
            show_log "Error:", error_text
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

      if @config.join_on_invite
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

    def dump_rooms(filename = 'room_list.yml')
      trailing = %r{ @ #{Regexp.escape(@config.muc_domain)} \z }x;
      rooms = @room_name.keys.map { |jid| jid.sub(trailing, '') }.sort

      File.open(filename, 'w') { |f|
        f.write(YAML.dump({ 'rooms' =>  rooms }, header: false))
      }
    end
  end
end
