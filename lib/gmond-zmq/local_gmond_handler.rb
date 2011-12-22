# gem install em-zeromq
# gem install eventmachine

require 'rubygems'
require 'em-zeromq'
require 'eventmachine'
require 'dante'
require 'socket'
require 'pp'
require 'nokogiri'
require 'gmond-zmq/gmondpacket2'
require 'gmond-zmq/gmondpacket'

# requires yum install libxml2-devel
# requires yum install libxslt-devel

# Inspiration
# https://github.com/fastly/ganglia/blob/master/lib/gm_protocol.x
# https://github.com/igrigorik/gmetric/blob/master/lib/gmetric.rb
# https://github.com/ganglia/monitor-core/blob/master/gmond/gmond.c#L1211
# https://github.com/ganglia/ganglia_contrib/blob/master/gmetric-python/gmetric.py#L107
# https://gist.github.com/1377993

# http://rubyforge.org/projects/ruby-xdr/

Thread.abort_on_exception = true

# Passing params to an EM Connectino
#  http://stackoverflow.com/questions/3985092/one-question-with-eventmachine


class LocalGmondHandler < EM::Connection
  attr_accessor :zmq_push_socket
  attr_accessor :verbose

  def receive_data packet

    gmonpacket=GmonPacket.new(packet)
    @counter=0 if @counter.nil?
    @counter=@counter+1
    if verbose
      pp '[',@counter,']',gmonpacket.to_hash
    end

    # We currently assume this goes fast
    # send Topic, Body
    # Using the correct helper methods - https://github.com/andrewvc/em-zeromq/blob/master/lib/em-zeromq/connection.rb
    zmq_push_socket.send_msg('gmond', gmonpacket.to_hash.to_json)

    # If not, we might need to defer the block
    # # http://www.igvita.com/2008/05/27/ruby-eventmachine-the-speed-demon/
    # # Callback block to execute once the parsing is finished
    # operation = proc do 
    # end
    #
    # callback = proc do |res|
    # end
    # # Let the thread pool (20 Ruby Threads handle request)
    # EM.defer(operation,callback)

  end

end
