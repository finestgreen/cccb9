module CCCB::Core::Hello

  extend Module::Requirements

  needs :bot

  def module_load

    add_setting :network, "said_hello_to", default: {}

    add_hook :hello, :message do |message|

      next unless message.text =~ /!hello/

      said_hello_to = message.network.get_setting("said_hello_to")

      if said_hello_to[message.user.nick] then
        reply = "Hello again, #{message.user.nick}"
      else
        reply = "Hello, #{message.user.nick}"
        said_hello_to[message.user.nick] = true
      end

      message.reply reply

    end

  end
end

