TransmissionNG ruby gem
=======================

Version history
---------------

1.0.0 - Initial release, compatible with RPC version 15 (latest as of 18/08/2015)
1.0.1 - Minor bugfix (regex anchor)
1.0.2 - Added a few default list attributes and fixed the name value
1.0.3 - Added peersGettingFromUs and peersSendingToUs to default list keys
1.0.4 - Fixed broken JSON back from RPC bug


Description
-----------

This gem is designed to provide a clean and simple ruby interface to the Transmission RPC API.

It is optimised for simplicity and ease of use and is compatible with version 15 of the
Transmission RPC API, the spec for which is currently here:

https://trac.transmissionbt.com/browser/branches/1.7x/doc/rpc-spec.txt


Installation
------------

sudo gem install transmission-ng


Usage
-----

Initialise the instance:

    require 'transmission'

    t = Transmission.new({
      :host => '127.0.0.1',
      :port => 9091,
      :user => 'admin',
      :pass => 'admin'
    })

Get a list of torrents:

    t.list => []

Change the default keys included with list items:

    t.list_attributes = ['id','name']
    t.list => []

Get all torrent information by id:

    t.get(9) => {} or false
    t.get([9,10]) => []

Get torrents with a specific attribute:

    t.list_by("status","stopped") => []
    t.list_by("status","=","stopped") => []
    t.list_by("percentDone",">=",98) => []
    t.list_by("status","!=","seeding") => []

Get torrent attributes:

    t.get(9, 'isFinished') => boolean
    t.get(9, 'name') => string
    t.get(9, ['name','isFinished','isStalled']) => {}

    For a full list of attributes please refer to the spec document here:
    https://trac.transmissionbt.com/browser/trunk/extras/rpc-spec.txt

Add torrents:

    t.add_magnet('magnet:?blahblah') => true
    t.add_torrentfile('http://path/to/torrent.torrent') => true

    torrent_data = File.open("path/to/torrent.torrent","r").read
    t.add_torrentdata(torrent_data) => true

Add torrent in paused state:

    t.add_magnet('magnet:?blahblah',{'paused' => true}) => true
    t.add_torrentfile('http://path/to/torrent.torrent',{'paused' => true}) => true
    t.add_torrentdata(torrent_data,{'paused' => true}) => true

For more parameters for the add torrent methods, please see section 3.4 of the spec at:
https://trac.transmissionbt.com/browser/trunk/extras/rpc-spec.txt

Change torrent parameters:

    t.set(9, {
      'peer-limit' => 20,
      'uploadLimited' => true
    })

For a full list of attributes, please see section 3.2 of the spec at:
https://trac.transmissionbt.com/browser/trunk/extras/rpc-spec.txt

Change parameters on all torrents at once:

    t.set([], {
      'peer-limit' => 20,
      'uploadLimited' => true
    })

Just as an empty "ids" value is shorthand for "all ids", using an empty array for "files-wanted",
"files-unwanted", "priority-high", "priority-low", or "priority-normal" is shorthand for saying
"all files".  For example, to make all files high priority:

    t.set(9, {
      'priority-high' => []
    })

Delete torrent(s):

    t.delete(9) => true
    t.delete([9,10]) => true

Delete torrent(s) and also remove all their local data:

    t.delete(9,true) => true
    t.delete([9,10],true) => true

Start torrent(s):

    t.start(9) => true
    t.start([9,10]) => true

Stop torrent(s):

    t.stop(9) => true
    t.stop([9,10]) => true

Verify torrent(s):

    t.verify(9) => true
    t.verify([9,10]) => true

Reannounce torrent(s):

    t.reannounce(9) => true
    t.reannounce([9,10]) => true

Move torrent(s) to the top of the queue:

    t.queue_top(9) => true
    t.queue_top([9,10]) => true

Move torrent(s) up the queue:

    t.queue_up(9) => true
    t.queue_up([9,10]) => true

Move torrent(s) down the queue:
    t.queue_down(9) => true
    t.queue_down([9,10]) => true

Move torrent(s) to the bottom of the queue:

    t.queue_bottom(9) => true
    t.queue_bottom([9,10]) => true

Set the location of a torrent:

    t.set_location(9, '/path/to/files') => true
    t.set_location([9,10], '/path/to/files') => true

    t.set_location(9, '/path/to/files', true) => true
    t.set_location([9,10], '/path/to/files', true) => true

If the third parameter is true the files will be moved to the new location, otherwise the
client will simply look for the files in the new location.

Renaming a torrent's path:

    t.rename_path(9, 'file/one', 'file/two') => true

For more information on the use of this function, see the transmission.h documentation of
tr_torrentRenamePath(). In particular, note that if this call succeeds you'll want to
update the torrent's "files" and "name" field with torrent-get.

Get the session variables:

    t.session_get => {}

Set session variables:

    t.session_set({
      'encryption' => 'required',
      'peer-port' => 31337,
      'pex-enabled' => false
    }) => true

Get session statistics:

    t.session_stats => {}

Update the blocklist:

    t.blocklist_update => true

Note: this currently doesn't work for me, might be a bug in Transmission.

Test that the external port is reachable via the internet:

    t.port_test => boolean

Close the session:

    t.session_close => true

Return the amount of free space at a specific directory:

    t.free_space("/") => {}
