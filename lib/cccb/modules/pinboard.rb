module CCCB::Core::Pinboard

  class PinboardCollection

    def initialize
      @boards = {}
    end

    def [](name)
      @boards[name]
    end

    def []=(name,description)
      if @boards[name].nil? then 
        @boards[name] = PinboardBoard.new(description)
      else
        @boards[name].description = description
      end
    end

    def names
      @boards.keys
    end

    def empty?
      @boards.empty?
    end

  end

  class PinboardBoard

    attr_accessor :description

    def initialize(description)
      @description = description
    end

  end


  extend Module::Requirements

  needs :bot

  def module_load

    pinboard.cmd_name = "pinboard"
    pinboard.boards ||= PinboardCollection.new

    add_command :pinboard, pinboard.cmd_name do |message, args|
        
        case args.shift
            when "setboard"
                if (name = args.shift).nil? then
                   message.reply "Say \"!#{pinboard.cmd_name} board boardname description\" to create a board or edit description"
                else
              	   description = args.join(" ")
                   pinboard.boards[name] = args.join(" ")	   
                   message.reply "Board '#{name}': #{description}"
                end
            when "show"
                if (name = args.shift).nil? or (board = pinboard.boards[name]).nil? then
                   message.reply "Say \"!#{pinboard.cmd_name} board boardname description\" to create a board or edit description"
                else
                   message.reply "Board '#{name}': #{board.description}"
                end
            when "debug"
                message.reply message.channel.inspect
                   

	    # Should probably remove this command before use
            when "reset_all"
		pinboard.boards = PinboardCollection.new
 		message.reply "All data deleted (hope you were sure!)"               
            else
                if pinboard.boards.empty? then
                   message.reply "No boards yet (say \"!#{pinboard.cmd_name} board boardname description\" to create one)"
		else
                   message.reply "Available boards are: #{pinboard.boards.names.join(", ")} (say \"!#{pinboard.cmd_name} show boardname\" to show)"
		end
	end
    end

  end
end

