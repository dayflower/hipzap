require 'time'
require 'date'
require 'ansi/code'

module HipZap; end

module HipZap::Renderer
  class Colorful < Standard
    def initialize(config)
      super

      @hl_re = if config.highlight then Regexp.new(config.highlight) end
    end

    def render_room_message(params)
      if @hl_re && params[:body] =~ @hl_re
        body = ANSI.on_yellow { params[:body] }
      else
        body = params[:body]
      end

      [
        render_room_name(params[:room_name]),
        ANSI.underline { ANSI.cyan { "#{params[:sender_nick]}:" } },
        body
      ]
    end

    def render_dm(params)
      if @hl_re && params[:body] =~ @hl_re
        body = ANSI.on_yellow { params[:body] }
      else
        body = params[:body]
      end

      room_name = render_dm_room_name(params[:room_name])
      sender = params[:sender_name] + ":"
      if params[:recipient]
        return [
          ANSI.white { ANSI.underline { sender } },
          ANSI.magenta { "@#{params[:recipient]}" },
          body
        ]
      else
        return [
          ANSI.cyan { ANSI.underline { sender } },
          body
        ]
      end
    end

    def render_topic(params)
      room_name = render_room_name(params[:room_name])
      topic = ANSI.green { params[:topic] }

      if params[:sender_name]
        [ room_name, ANSI.cyan { ANSI.underline { params[:sender_name] } }, "set", "topic:", topic ]
      else
        [ room_name, "topic:", topic ]
      end
    end

    def render_room_name(room_name)
      ANSI.blue { ANSI.bold { "<#{room_name}>" } }
    end

    def render_dm_room_name(room_name)
      ANSI.magenta { ANSI.bold { ">#{room_name}<" } }
    end

    def render_timestamp(time)
      return ANSI.blue { super(time) }
    end

    def render_sending_stream(str)
      ANSI.yellow { str }
    end

    def render_received_stream(element)
      ANSI.blue { element.to_s }
    end
  end
end
