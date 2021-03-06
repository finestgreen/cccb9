gem 'redcarpet', '<=3.2.0'
require 'redcarpet'

class CCCB::Reply
  class IRCRender < Redcarpet::Render::Base
    def normal_text(text)
      text
    end
    def block_code(code,language = nil)
      block = if language 
        [ "|== #{italic code} ==", ] 
      else
        []
      end
      block += normal_text(code).each_line.map do |l|
        l.strip.gsub /^/, '| '
      end
      block.join("\n") + "\n"
    end
    def codespan(code)
      block_code(code,nil)
    end
    def bold(text)
      "\x02#{text}\x02"
    end
    def reverse(text)
      "\x16#{text}\x16"
    end
    def italic(text)
      "\x06#{text}\x06"
    end
    def underline(text)
      "\x1f#{text}\x1f"
    end
    def header(title,level)
      case level
      when 1 then text = underline(bold(title))
      when 2 then text = underline(italic(title))
      when 3 then text = underline(title)
      when 4 then text = italic(title)
      else
        text = title
      end
      text + "\n"
    end
    def double_emphasis(text)
      bold text
    end
    def emphasis(text)
      italic text
    end
    def linebreak
      "\n"
    end
    def paragraph(text)
      text + "\n"
    end
    def list(content,list_type)
      "\u0000L[#{content}\u0000L]"
    end
    def list_item(content, list_type)
      type = list_type.to_s[0]
      "\u0000L#{type}#{content}\n"
    end
    def link(link,title,content)
      content
    end
    def postprocess(data)
      lists = []
      parsed = ""
      until ( index = data.index("\u0000") ).nil?
        parsed += data[0,index]
        token = data[index+1,2]
        data[0,index+3] = ""
        case token
        when "L["
          lists << { index: 1 }
        when "L]"
          lists.pop
        when "Lu"
          parsed += "#{ "  " * (lists.count-1) }* "
        when "Lo"
          parsed += "#{ "  " * (lists.count-1) }#{lists.last[:index]}. "
          lists.last[:index] += 1
        end
      end
      parsed + data
    end
    def table(*rows)
      table = []
      max_width = []
      rows.each do |r|
        row = []
        table << row
        r.split("\u0000T").each_with_index do |c,i|
          max_width[i] ||= 0
          row << c
          max_width[i] = c.length if c.length > max_width[i]
        end
      end
      output = ""
      table.each_with_index do |r,n|
        r.each_with_index do |c,i|
          content = c
          content = if n == 0
            bold(c).center(max_width[i]+2)
          else
            c.center(max_width[i])
          end
          c.replace(content)
        end
        output += "|" + r.join(" | ") + "|\n"
      end
      output
    end
    def table_row(*args)
      args[0]
    end
    def table_cell(*args)
      "#{args[0]}\u0000T"
    end
    
    #def respond_to?(sym)
    #  puts "#{self}.respond_to?(#{sym.inspect})"
    #  super
    #end
    #def method_missing(sym,*args,**kwargs,&block)
    #  puts "#{self}.#{sym}(*#{args.inspect},**#{kwargs.inspect},&#{block})"
    #  super
    #end
  end

  @categories = %i{ title summary fulltext }

  def initialize(message)
    @message = message
    @no_minimal = false
  end

  @categories.each do |sym|
    attr_accessor sym
    writer = :"#{sym}="
    var = :"@#{sym}"
    define_method sym do |data = nil|
      if data
        self.send(writer,data)
        self
      else
        self.instance_variable_get(var)
      end
    end
  end

  def write
    @message.send_reply
  end

  def no_minimal
    @no_minimal = true
  end

  def force_title=(title_text)
    self.no_minimal
    self.title = title_text
  end

  def minimal_form
    return self.short_form if @no_minimal
    [ self.summary || self.title || self.fulltext ].flatten.join("\n")
  end

  def short_form
    "# #{[ *self.title ].first}\n#{self.summary || self.fulltext}"
  end

  def long_form
    "# #{[ *self.title ].first}\n#{self.fulltext || self.summary}"
  end
    
end

module CCCB::Core::Reply
  extend Module::Requirements

  def markdown_list(list)
    list.map do |i|
      if i.is_a? Array
        markdown_list(i).force_encoding("UTF-8").gsub(/^(\s*)\*/m,'  \1*')
      else
        "* #{i}"
      end
    end.join("\n")
  end

  def module_load
    reply.irc_parser = Redcarpet::Markdown.new( 
      CCCB::Reply::IRCRender,
      no_intra_emphasis: true,
      lax_spacing: true,
      quote: false,
      footnotes: true,
      tables: true
    )
    reply.web_parser = Redcarpet::Markdown.new( 
      Redcarpet::Render::HTML, 
      autolink: true,
      footnotes: true,
      quote: true,
      lax_spacing: true,
      tables: true
    )
  end

end
