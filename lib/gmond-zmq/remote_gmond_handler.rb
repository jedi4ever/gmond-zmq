# Maybe use defer, as this might take awhile
#  http://eventmachine.rubyforge.org/EventMachine.html#M000486
#  http://www.igvita.com/2008/05/27/ruby-eventmachine-the-speed-demon/
#  Separate thread
class PostCallbacks < Nokogiri::XML::SAX::Document
  def initialize(socket)
    @socket=socket
  end

  def start_element(element,attributes)
    if element == "METRIC"
        @socket.send_msg('gmond', attributes.to_json)
    end
    if element == "HOST"
        @socket.send_msg('gmond', attributes.to_json)
    end
  end
end

class RemoteGmondHandler < EM::Connection
  attr_accessor :zmq_push_socket
  attr_accessor :verbose

  def receive_data data
  puts "fetching XML"
        begin
    parser = Nokogiri::XML::SAX::Parser.new(PostCallbacks.new(zmq_push_socket))
    parser.parse(data)
  rescue
    puts "Error parsing XML"
  end
  end

  def unbind
  puts "closing connection"
  end
end
