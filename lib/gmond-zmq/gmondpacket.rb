require 'gmond-zmq/xdr'
class GmonPacket

  def initialize(packet)
    @xdr=XDR::Reader.new(StringIO.new(packet))
    @result=Hash.new
    packet_type=@xdr.uint32
    @result['gmetadata_full']=packet_type
    case packet_type
    when 128 then unpack_meta
    when 132 then unpack_heartbeat
    when 134,133 then unpack_data
    end
  end

  def unpack_meta
    puts "got meta package"
    # This parse is only working correctly with gmetadata_full=128
    @result['hostname']=@xdr.string
    @result['metricname']=@xdr.string
    @result['spoof']=@xdr.uint32
    @result['metrictype']=@xdr.string
    @result['metricname2']=@xdr.string
    @result['metricunits']=@xdr.string
    @result['slope']=@xdr.uint32
    @result['tmax']=@xdr.uint32
    @result['dmax']=@xdr.uint32
    nrelements=@xdr.uint32
    @result['nrelements']=nrelements
    unless nrelements.nil?
      for i in 1..nrelements[0]
        name=@xdr.string
        @result[name]=@xdr.string
      end
    end
  end

  def unpack_data
    puts "got data package"
    unpack_data_blob
  end

  def unpack_data_blob
    @result['hostname']=@xdr.string
    @result['metricname']=@xdr.string
    @result['spoof']=@xdr.uint32
    format=@xdr.string
    @result['format']=format

    # Quick hack here
    # Needs real XDR parsing here
    # http://ruby-xdr.rubyforge.org/git?p=ruby-xdr.git;a=blob;f=lib/xdr.rb;h=b41177f32ae72f30d31122e5d801e4828a614c79;hb=HEAD
    @result['value']=@xdr.float32 if format.include?("f")
    @result['value']=@xdr.uint32 if format.include?("u")
    @result['value']=@xdr.string if format.include?("s")
  end

  def unpack_heartbeat
    puts "got heartbeat"
    unpack_data_blob
  end


  def to_hash
    return @result
  end

end
