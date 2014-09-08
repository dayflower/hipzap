require 'time'
require 'date'

module HipZap; end

module HipZap::Renderer
  class Standard
    def initialize(config)
      @config = config
    end

    def render_sending_stream(str)
      ">>> " + str
    end

    def render_received_stream(element)
      "<<< " + element.to_s
    end

    def render_room_message(params)
      [ render_room_name(params[:room_name]), "#{params[:sender_nick]}:", params[:body] ]
    end

    def render_dm(params)
      room_name = render_dm_room_name(params[:room_name])
      sender = params[:sender_name] + ":"
      if params[:recipient]
        return [ sender, "@#{params[:recipient]}", params[:body] ]
      else
        return [ sender, params[:body] ]
      end
    end

    def render_topic(params)
      if params[:sender_name]
        [ render_room_name(params[:room_name]), params[:sender_name], "set", "topic:", params[:topic] ]
      else
        [ render_room_name(params[:room_name]), "topic:", params[:topic] ]
      end
    end

    def render_room_name(room_name)
      "<#{room_name}>"
    end

    def render_dm_room_name(room_name)
      ">#{room_name}<"
    end

    def render_timestamp(time)
      unless @today
        @today = Date.today
      end

      if @today == time.to_date
        return time.strftime('%H:%M')
      else
        return time.strftime('%m/%d %H:%M')
      end
    end
  end
end
