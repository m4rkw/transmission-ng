
require 'mechanize'
require 'json'

$rpc_version = 15
$VERBOSE = nil

module Kernel
  def reload(lib)
    if old = $LOADED_FEATURES.find{|path| path=~/#{Regexp.escape lib}(\.rb)?\z/ }
      load old
    else
      require lib
    end
  end
end

class Transmission
  attr_accessor :list_attributes
  attr_accessor :settable_attributes

  def initialize(config)
    @config = config

    @list_attributes = ['id','name','hashString','isFinished','isStalled','leftUntilDone','eta','percentDone','rateDownload',
      'status','totalSize','rateDownload','peersConnected','peersFrom','rateUpload','downloadedEver','peersSendingToUs',
      'peersGettingFromUs']
    @all_attributes = ['activityDate','addedDate','bandwidthPriority','comment','corruptEver','creator','dateCreated',
      'desiredAvailable','doneDate','downloadDir','downloadedEver','downloadLimit','downloadLimited','error',
      'errorString','eta','etaIdle','files','fileStats','hashString','haveUnchecked','haveValid','honorsSessionLimits',
      'id','isFinished','isPrivate','isStalled','leftUntilDone','magnetLink','manualAnnounceTime','maxConnectedPeers',
      'metadataPercentComplete','name','peer-limit','peers','peersConnected','peersFrom','peersGettingFromUs',
      'peersSendingToUs','percentDone','pieces','pieceCount','pieceSize','priorities','queuePosition','rateDownload',
      'rateUpload','recheckProgress','secondsDownloading','secondsSeeding','seedIdleLimit','seedIdleMode','seedRatioLimit',
      'seedRatioMode','sizeWhenDone','startDate','status','trackers','trackerStats','totalSize','torrentFile',
      'uploadedEver','uploadLimit','uploadLimited','uploadRatio','wanted','webseeds','webseedsSendingToUs']
    @settable_attributes = ['bandwidthPriority','downloadLimit','downloadLimited','files-wanted','files-unwanted',
      'honorsSessionLimits','location','peer-limit','priority-high','priority-low','priority-normal','queuePosition',
      'seedIdleLimit','seedIdleMode','seedRatioLimit','seedRatioMode','trackerAdd','trackerRemove','trackerReplace',
      'uploadLimit','uploadLimited']
    @session_attributes = ['alt-speed-down','alt-speed-enabled','alt-speed-time-begin','alt-speed-time-enabled',
      'alt-speed-time-end','alt-speed-time-day','alt-speed-up','blocklist-url','blocklist-enabled','blocklist-size',
      'cache-size-mb','config-dir','download-dir','download-queue-size','download-queue-enabled','dht-enabled',
      'encryption','idle-seeding-limit','idle-seeding-limit-enabled','incomplete-dir','incomplete-dir-enabled',
      'lpd-enabled','peer-limit-global','peer-limit-per-torrent','pex-enabled','peer-port','peer-port-random-on-start',
      'port-forwarding-enabled','queue-stalled-enabled','queue-stalled-minutes','rename-partial-files','rpc-version',
      'rpc-version-minimum','script-torrent-done-filename','script-torrent-done-enabled','seedRatioLimit','seedRatioLimited',
      'seed-queue-size','seed-queue-enabled','speed-limit-down','speed-limit-down-enabled','speed-limit-up',
      'speed-limit-up-enabled','start-added-torrents','trash-original-torrent-files','units','utp-enabled','version','units']
    @session_settable_attributes = ['alt-speed-down','alt-speed-enabled','alt-speed-time-begin','alt-speed-time-enabled',
      'alt-speed-time-end','alt-speed-time-day','alt-speed-up','blocklist-url','blocklist-enabled','cache-size-mb',
      'download-dir','download-queue-size','download-queue-enabled','dht-enabled','encryption','idle-seeding-limit',
      'idle-seeding-limit-enabled','incomplete-dir','incomplete-dir-enabled','lpd-enabled','peer-limit-global',
      'peer-limit-per-torrent','pex-enabled','peer-port','peer-port-random-on-start','port-forwarding-enabled',
      'queue-stalled-enabled','queue-stalled-minutes','rename-partial-files','script-torrent-done-filename',
      'script-torrent-done-enabled','seedRatioLimit','seedRatioLimited','seed-queue-size','seed-queue-enabled',
      'speed-limit-down','speed-limit-down-enabled','speed-limit-up','speed-limit-up-enabled','start-added-torrents',
      'trash-original-torrent-files','units','utp-enabled','units']

    rpc_version = session_get['rpc-version']

    if rpc_version != $rpc_version
      puts "--------------------------------------------------------"
      puts "WARNING: RPC version is #{rpc_version} but we only support #{$rpc_version}."
      puts "Some API methods may fail or produce unexpected results."
      puts "Please check for an update to this gem."
      puts "--------------------------------------------------------"
    end
  end

  def rpc(method, args=[], session_id=nil)
    resp = nil

    begin
      if TCPSocket::socks_server
        socks_server = TCPSocket::socks_server
        socks_port = TCPSocket::socks_port
        TCPSocket::socks_server = nil
        TCPSocket::socks_port = nil
        disabled_socksify = true
      else
        disabled_socksify = false
      end
    rescue NoMethodError
      disabled_socksify = false
    end

    Mechanize.start do |mech|
      mech.user_agent_alias = 'Mac Safari'
      mech.add_auth "http://#{@config[:host]}:#{@config[:port].to_s}", @config[:user], @config[:pass]

      begin
        resp = mech.post 'http://' + @config[:host] + ':' + @config[:port].to_s + '/transmission/rpc', {
            'method' => method,
            'arguments' => args
          }.to_json, {
            'X-Transmission-Session-Id' => session_id,
            'Content-Type' => 'application/json'
          }
      rescue Mechanize::ResponseCodeError => e
        if e.response_code == "409"
          session_id = e.page.search('code').text.match(/X-Transmission-Session-Id: ([a-zA-Z0-9]+)/)[1]

          if disabled_socksify
            TCPSocket::socks_server = socks_server
            TCPSocket::socks_port = socks_port
          end

          return rpc method, args, session_id
        end
        raise e
      end
    end

    if disabled_socksify
      TCPSocket::socks_server = socks_server
      TCPSocket::socks_port = socks_port
    end

    json = resp.body

    response = JSON.parse(json)

    if response["result"] != "success"
      raise "RPC error: " + response["result"]
    end

    response
  end
  private :rpc

  def get(ids=[], attributes=[])
    attributes.each do |attr|
      if !@all_attributes.include? attr
        raise "Unknown torrent attributes: #{attr}"
      end
    end

    if attributes.empty?
      attributes = @all_attributes
    end

    params = {
      :fields => attributes
    }

    if ids.is_a? Integer
      ids = [ids]
      single = true
    else
      single = false
    end

    if !ids.empty?
      params[:ids] = ids
    end

    resp = rpc('torrent-get', params)

    for i in 0...resp["arguments"]["torrents"].length
      resp["arguments"]["torrents"][i].each do |key, value|
        if respond_to? "map_#{key}"
          resp["arguments"]["torrents"][i][key] = self.send "map_#{key}", value
        end
      end
    end

    if single
      return !resp["arguments"]["torrents"].empty? ? resp["arguments"]["torrents"][0] : false
    end

    resp["arguments"]["torrents"]
  end

  def list
    get([], @list_attributes)
  end

  def list_by(field, operator, value=nil)
    torrents = []

    if value == nil
      value = operator
      operator = '='
    end

    list.each do |torrent|
      if eval_operator(torrent[field], operator, value)
        torrents.push torrent
      end
    end

    torrents
  end

  def eval_operator(torrent_value, operator, value)
    case operator
    when '=','=='
      return torrent_value == value
    when '>'
      return torrent_value > value
    when '<'
      return torrent_value < value
    when '>='
      return torrent_value >= value
    when '<='
      return torrent_value <= value
    when '!=','<>'
      return torrent_value != value
    else
      raise "Unknown comparison operator: #{operator}"
    end
  end
  private :eval_operator

  def map_name(name)
    URI.unescape(name).gsub /\+/, ' '
  end

  def map_status(code)
    case code
    when 0
      return 'stopped'
    when 1
      return 'check-wait'
    when 2
      return 'checking'
    when 3
      return 'download-wait'
    when 4
      return 'downloading'
    when 5
      return 'seed-wait'
    when 6
      return 'seeding'
    else
      raise "Unknown status code: #{code}"
    end
  end

  def map_percentDone(percent)
    percent * 100
  end

  def get_attr(id, attribute)
    resp = get([id], [attribute])

    resp[0][attribute]
  end

  def get_attrs(ids, attributes)
    get(ids, attributes)
  end

  def add(params={})
    resp = rpc('torrent-add', params)

    resp["arguments"]["torrent-added"]
  end
  private :add

  def all_ids
    ids = []

    list.each do |tor|
      ids.push tor['id']
    end

    ids
  end

  def add_magnet(magnet_link, params={})
    if !magnet_link.match /\Amagnet:\?/
      raise "This doesn't look like a magnet link to me: #{magnet_link}"
    end
    ids_before = all_ids

    add({'filename' => magnet_link}.merge(params))

    while 1
      diff = all_ids - ids_before

      if diff
        break
      end

      sleep 0.1
    end

    return diff[0]
  end

  def add_torrentfile(torrent_file, params={})
    add({'filename' => torrent_file}.merge(params))
  end

  def add_torrentdata(torrent_data, params={})
    add({'metainfo' => torrent_data}.merge(params))
  end

  def method_missing(method, *args, &block)
    map = {
      :start => 'torrent-start',
      :stop => 'torrent-stop',
      :verify => 'torrent-verify',
      :reannounce => 'torrent-reannounce',
      :queue_top => 'queue-move-top',
      :queue_up => 'queue-move-up',
      :queue_down => 'queue-move-down',
      :queue_bottom => 'queue-move-bottom'
    }

    if map[method] == nil
      raise "Unknown method: #{method}"
    end

    resp = rpc(map[method], {'ids' => args[0]})

    true
  end

  def set(ids, keys)
    keys.each do |key, value|
      if !@settable_attributes.include? key
        raise "Unknown attribute: #{key}"
      end
    end

    resp = rpc('torrent-set',{
      'ids' => ids
    }.merge(keys))

    true
  end

  def delete(ids, delete_local_data=false)
    resp = rpc('torrent-remove',{
      'ids' => ids,
      'delete-local-data' => delete_local_data
    })

    true
  end

  def set_location(ids, location, move=false)
    resp = rpc('torrent-set-location',{
      'ids' => ids,
      'location' => location,
      'move' => move
    })

    true
  end

  def rename_path(ids, path, name)
    resp = rpc('torrent-rename-path',{
      'ids' => ids,
      'path' => path,
      'name' => name
    })

    true
  end

  def session_get
    resp = rpc('session-get')

    resp['arguments']
  end

  def session_set(keys)
    keys.each do |key, value|
      if !@session_attributes.include? key
        raise "Unknown session attribute: #{key}"
      end
      if !@session_settable_attributes.include? key
        raise "Session attribute '#{key}' cannot be changed."
      end
    end

    resp = rpc('session-set',keys)

    true
  end

  def session_stats
    resp = rpc('session-stats')

    resp['arguments']
  end

  def blocklist_update
    resp = rpc('blocklist-update')

    resp['arguments']
  end

  def port_test
    resp = rpc('port-test')

    resp['arguments']['port-is-open']
  end

  def session_close
    resp = rpc('session-close')

    true
  end

  def free_space(path)
    resp = rpc('free-space',{'path' => path})

    resp['arguments']
  end
end
