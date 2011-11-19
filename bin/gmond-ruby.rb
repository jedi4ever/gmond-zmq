require 'eventmachine'
require 'socket'
require 'pp'

# Inspiration
# https://github.com/fastly/ganglia/blob/master/lib/gm_protocol.x
# https://github.com/igrigorik/gmetric/blob/master/lib/gmetric.rb
# https://github.com/ganglia/monitor-core/blob/master/gmond/gmond.c#L1211
# https://github.com/ganglia/ganglia_contrib/blob/master/gmetric-python/gmetric.py#L107
# https://gist.github.com/1377993

class GmonPacket

  def initialize(packet)
    @unpacked=packet
    @result=Hash.new
    packet_type=unpack_int
    @result['gmetadata_full']=packet_type
    case packet_type[0]
    when 128 then unpack_meta
    when 132 then unpack_heartbeat
    when 134,133 then unpack_data
    end
  end

  def unpack_meta
    puts "got meta package"
    # This parse is only working correctly with gmetadata_full=128
    @result['hostname']=unpack_string
    @result['metricname']=unpack_string
    @result['spoof']=unpack_int
    @result['metrictype']=unpack_string
    @result['metricname2']=unpack_string
    @result['metricunits']=unpack_string
    @result['slope']=unpack_int
    @result['tmax']=unpack_int
    @result['dmax']=unpack_int
    nrelements=unpack_int
    @result['nrelements']=nrelements
    unless nrelements.nil?
      for i in 1..nrelements[0]
        name=unpack_string
        @result[name]=unpack_string
      end
    end
  end

  def unpack_data
    puts "got data package"
    unpack_data_blob
  end

  def unpack_data_blob
    @result['hostname']=unpack_string
    @result['metricname']=unpack_string
    @result['spoof']=unpack_int
    format=unpack_string
    @result['format']=format

    # Quick hack here
    # Needs real XDR parsing here
    # http://ruby-xdr.rubyforge.org/git?p=ruby-xdr.git;a=blob;f=lib/xdr.rb;h=b41177f32ae72f30d31122e5d801e4828a614c79;hb=HEAD
    @result['value']=unpack_float if format.include?("f")
    @result['value']=unpack_int if format.include?("u")
    @result['value']=unpack_string if format.include?("s")
  end

  def unpack_heartbeat
    puts "got heartbeat"
    unpack_data_blob
  end


  def unpack_int
    unless @unpacked.nil?
      value=@unpacked[0..3].unpack('N')
      shift_unpacked(4)
      return value
    else
      return nil
    end
  end

  def unpack_float
    unless @unpacked.nil?
      value=@unpacked[0..3].unpack('g')
      shift_unpacked(4)
      return value
    else
      return nil
    end
  end

  def unpack_string
    unless @unpacked.nil?
      size=@unpacked[0..3].unpack('N').to_s.to_i
      shift_unpacked(4)
      value=@unpacked[0..size-1]
      #The packets are padded
      shift_unpacked(size+((4-size) % 4))
      return value
    else
      return nil
    end
  end

  def shift_unpacked(count)
    @unpacked=@unpacked[count..@unpacked.length]
  end

  def to_hash
    return @result
  end

end

class UDPServer
  def initialize(port)
    @port = port
  end

  def handle(packet)
    print "Connection: #{packet[1]} :"
    pp packet[0]
    gmonpacket=GmonPacket.new(packet[0])
    pp gmonpacket.to_hash

  end

  def start
    @socket = UDPSocket.new
    @socket.bind("0.0.0.0", @port) # is nil OK here?
    while true
      packet = @socket.recvfrom(1024)
      handle(packet)
    end
  end
end

#server = UDPServer.new(1234)
#server.start

module GmonHandler
  def receive_data packet
    #pp packet
    gmonpacket=GmonPacket.new(packet)
    @counter=0 if @counter.nil?
    @counter=@counter+1
    pp '[',@counter,']',gmonpacket.to_hash
  end
end

EventMachine::run {
  host,port = "0.0.0.0",1234
  #EventMachine::open_datagram_socket(address, port, handler=nil, *args
  EventMachine::open_datagram_socket(host,port,GmonHandler)
  puts "Now accepting connections on address #{host}, port #{port}..."
  EventMachine::add_periodic_timer( 1 ) { $stderr.write "*" }
}
