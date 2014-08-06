require 'mongo'

module Bipbip

  class Plugin::Mongodb < Plugin

    def metrics_schema
      [
        {:name => 'flushing_flushes', :type => 'counter', :unit => 'flushes'},
        {:name => 'flushing_total_ms', :type => 'gauge', :unit => 'ms'},
        {:name => 'flushing_average_ms', :type => 'gauge', :unit => 'ms'},
        {:name => 'flushing_last_ms', :type => 'gauge', :unit => 'ms'},
        {:name => 'btree_accesses' , :type => 'gauge', :unit => 'accesses'},
        {:name => 'btree_misses' , :type => 'gauge', :unit => 'misses'},
        {:name => 'btree_hits' , :type => 'gauge', :unit => 'hits'},
        {:name => 'btree_resets' , :type => 'gauge', :unit => 'resets'},
        {:name => 'cursors_totalOpen' , :type => 'gauge', :unit => 'crs'},
        {:name => 'cursors_timedOut' , :type => 'gauge', :unit => 'crs/sec'},
        {:name => 'op_inserts' , :type => 'counter'},
        {:name => 'op_queries' , :type => 'counter'},
        {:name => 'op_updates' , :type => 'counter'},
        {:name => 'op_deletes' , :type => 'counter'},
        {:name => 'op_getmores' , :type => 'counter'},
        {:name => 'op_commands' , :type => 'counter'},
        {:name => 'asserts_regular' , :type => 'counter'},
        {:name => 'asserts_warning' , :type => 'counter'},
        {:name => 'asserts_msg' , :type => 'counter'},
        {:name => 'asserts_user' , :type => 'counter'},
        {:name => 'asserts_rollover' , :type => 'counter'},
        {:name => 'connections_available' , :type => 'gauge'},
        {:name => 'connections_current' , :type => 'gauge'},
        {:name => 'mem_resident' , :type => 'gauge', :unit => 'MB'},
        {:name => 'mem_virtual' , :type => 'gauge', :unit => 'MB'},
        {:name => 'mem_mapped' , :type => 'gauge', :unit => 'MB'},
        {:name => 'mem_pagefaults' , :type => 'gauge', :unit => 'faults'},
        {:name => 'globalLock_ratio' , :type => 'gauge', :unit => '%'},
        {:name => 'globalLock_currentQueue' , :type => 'gauge'},
        {:name => 'globalLock_activeClients' , :type => 'gauge'},
        {:name => 'uptime' , :type => 'counter', :unit => 's'},
      ]
    end

    def monitor
      connectionArguments = [
          'port',
          'host',
          'user',
          'password',
      ]
      configConnection = {}
      connectionArguments.each do |k|
        configConnection[k] = @config.has_key?(k) ? @config[k] : nil
      end

      mongo = _connect('admin', configConnection)
      begin
        mongoStats = mongo.command('serverStatus' => 1) if mongo
      rescue Exception => e
        log "Error getting mongo admin stats from: #{configConnection['host']} [skipping]"
      end

      data = {}
      data['btree_accesses']           = mongoStats['indexCounters']['accesses'].to_i
      data['btree_misses']             = mongoStats['indexCounters']['misses'].to_i
      data['btree_hits']               = mongoStats['indexCounters']['hits'].to_i
      data['btree_resets']             = mongoStats['indexCounters']['resets'].to_i
      data['flushing_flushes']         = mongoStats['backgroundFlushing']['flushes'].to_i
      data['flushing_total_ms']        = mongoStats['backgroundFlushing']['total_ms'].to_i
      data['flushing_average_ms']      = mongoStats['backgroundFlushing']['average_ms'].to_i
      data['flushing_last_ms']         = mongoStats['backgroundFlushing']['last_ms'].to_i
      data['cursors_totalOpen']        = mongoStats['cursors']['totalOpen'].to_i
      data['cursors_timedOut']         = mongoStats['cursors']['timedOut'].to_i
      data['op_inserts']               = mongoStats['opcounters']['insert'].to_i
      data['op_queries']               = mongoStats['opcounters']['query'].to_i
      data['op_updates']               = mongoStats['opcounters']['update'].to_i
      data['op_deletes']               = mongoStats['opcounters']['delete'].to_i
      data['op_getmores']              = mongoStats['opcounters']['getmore'].to_i
      data['op_commands']              = mongoStats['opcounters']['command'].to_i
      data['asserts_regular']          = mongoStats['asserts']['regular'].to_i
      data['asserts_warning']          = mongoStats['asserts']['warning'].to_i
      data['asserts_msg']              = mongoStats['asserts']['msg'].to_i
      data['asserts_user']             = mongoStats['asserts']['user'].to_i
      data['asserts_rollover']         = mongoStats['asserts']['rollovers'].to_i
      data['connections_available']    = mongoStats['connections']['available'].to_i
      data['connections_current']      = mongoStats['connections']['current'].to_i
      data['mem_resident']             = mongoStats['mem']['resident'].to_i
      data['mem_virtual']              = mongoStats['mem']['virtual'].to_i
      data['mem_mapped']               = mongoStats['mem']['mapped'].to_i
      data['mem_pagefaults']           = mongoStats['extra_info']['page_faults']
      data['globalLock_ratio']         = (mongoStats['globalLock']['lockTime'] / mongoStats['globalLock']['totalTime'] * 100).to_f
      data['globalLock_currentQueue']  = mongoStats['globalLock']['currentQueue']['total'].to_i
      data['globalLock_activeClients'] = mongoStats['globalLock']['activeClients']['total'].to_i
      data['uptime']                   = mongoStats['uptime'].to_i

      data
    end

    private

    def _connect(db, options={})
      options = {'host' => 'localhost', 'port' => 27017, 'user' => nil, 'password' => nil}.merge(options)
      begin
        connection = Mongo::MongoClient.new(options['host'], options['port'], {:op_timeout=>2, :slave_ok=>true})
      rescue Exception => e
        Bipbip.logger.error "Unable to connect to Mongo at #{options['host']}:#{options['port']} - #{e.message}"
        return nil
      end

      mongo = connection.db(db)
      begin
        mongo.authenticate(options['user'], options['password']) unless options['password'].nil?
      rescue Exception => e
        Bipbip.logger.error "Error connecting to mongodb #{db}, on #{options['host']}:#{options['port']} - #{e.message}"
        return nil
      end
      return mongo
    end

  end
end
