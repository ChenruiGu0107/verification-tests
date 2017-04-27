Given /^the env is using multitenant network$/ do
  ensure_admin_tagged

  _host = node.host rescue nil
  unless _host
    step "I store the schedulable nodes in the clipboard"
    _host = node.host
  end

  @result = _host.exec('ovs-ofctl dump-flows br0 -O openflow13 || docker exec openvswitch ovs-ofctl dump-flows br0 -O openflow13')
  unless @result[:success] && @result[:response] =~ /table=253.*actions=note:01/
    raise "The env is not using multitenant network."
  end
end

Given /^the env is using networkpolicy plugin$/ do
  ensure_admin_tagged

  _host = node.host rescue nil
  unless _host
    step "I store the schedulable nodes in the clipboard"
    _host = node.host
  end

  @result = _host.exec('ovs-ofctl dump-flows br0 -O openflow13 || docker exec openvswitch ovs-ofctl dump-flows br0 -O openflow13')
  unless @result[:success] && @result[:response] =~ /table=253.*actions=note:02/
    raise "The env is not using networkpolicy plugin."
  end
end

Given /^the network plugin is switched on the#{OPT_QUOTED} node$/ do |node_name|
  ensure_admin_tagged

  _node = node(node_name)
  _host = _node.host
  @result = _host.exec('ovs-ofctl dump-flows br0 -O openflow13 || docker exec openvswitch ovs-ofctl dump-flows br0 -O openflow13')

  if @result[:success] && @result[:response] =~ /table=253.*actions=note:01/
    logger.info "Switch plguin from multitenant to subnet"
    @result = _host.exec("sed -i 's/multitenant/subnet/g' /etc/origin/node/node-config.yaml")
    raise "failed to switch plugin in node config" unless @result[:success]
  else
    logger.info "Switch plguin from subnet to multitenant"
    @result = _host.exec("sed -i 's/subnet/multitenant/g' /etc/origin/node/node-config.yaml")
    raise "failed to switch plugin in node config" unless @result[:success]
  end
end

Given /^the#{OPT_QUOTED} node network is verified$/ do |node_name|
  ensure_admin_tagged

  _node = node(node_name)
  _host = _node.host

  net_verify = proc {
    @result = _host.exec('ovs-ofctl dump-flows br0 -O openflow13 || docker exec openvswitch ovs-ofctl dump-flows br0 -O openflow13')
    unless @result[:success] || @result[:response] =~ /table=253.*actions=note/
      raise "unexpected network setup, see log"
    end
  }

  net_verify.call
  teardown_add net_verify
end

Given /^the#{OPT_QUOTED} node iptables config is verified$/ do |node_name|
  ensure_admin_tagged
  _node = node(node_name)
  _host = _node.host
  _admin = admin

  @result = _admin.cli_exec(:get, resource: "clusternetwork", resource_name: "default", template: "{{.network}}")
  unless @result[:success]
    raise "Can not get clusternetwork resource!"
  end

  subnet = @result[:response]
  cb.clusternetwork = subnet

  iptables_verify = proc {
    @result = _host.exec_admin("systemctl status iptables")
    unless @result[:success] && @result[:response] =~ /Active:\s+?active/
      raise "The iptables deamon verification failed. The deamon is not active!"
    end
    filter_matches = [
      'INPUT -i tun0 -m comment --comment "traffic from(.*)" -j ACCEPT',
      'INPUT -p udp -m multiport --dports 4789 -m comment --comment "001 vxlan incoming" -j ACCEPT',
      'OUTPUT -m comment --comment "kubernetes service portals" -j KUBE-SERVICES',
      "FORWARD -s #{subnet} -j ACCEPT",
      "FORWARD -d #{subnet} -j ACCEPT"
    ]
    @result = _host.exec_admin("iptables-save -t filter")
    filter_matches.each { |match|
      unless @result[:success] && @result[:response] =~ /#{match}/
        raise "The filter table verification failed!"
      end
    }

    nat_matches = [
      'PREROUTING -m comment --comment "kubernetes service portals" -j KUBE-SERVICES',
      'POSTROUTING -m comment --comment "kubernetes postrouting rules" -j KUBE-POSTROUTING',
      "POSTROUTING -s #{subnet}(.*)-j MASQUERADE"
    ]
    @result = _host.exec_admin("iptables-save -t nat")
    nat_matches.each { |match|
      unless @result[:success] && @result[:response] =~ /#{match}/
        raise "The nat table verification failed!"
      end
    }
  }

  firewalld_verify = proc {
    @result = _host.exec_admin("systemctl status firewalld")
    unless @result[:success] && @result[:response] =~ /Active:\s+?active/
      raise "The firewalld deamon verification failed. The deamon is not active!"
    end
    filter_matches = [
      'INPUT -i tun0 -m comment --comment "traffic from(.*)" -j ACCEPT',
      'INPUT -p udp -m multiport --dports 4789 -m comment --comment "001 vxlan incoming" -j ACCEPT',
      'OUTPUT -m comment --comment "kubernetes service portals" -j KUBE-SERVICES',
      "FORWARD -s #{subnet} -j ACCEPT",
      "FORWARD -d #{subnet} -j ACCEPT"
    ]
    @result = _host.exec_admin("iptables-save -t filter")
    filter_matches.each { |match|
      unless @result[:success] && @result[:response] =~ /#{match}/
        raise "The filter table verification failed!"
      end
    }

    nat_matches = [
      'PREROUTING -m comment --comment "kubernetes service portals" -j KUBE-SERVICES',
      'POSTROUTING -m comment --comment "kubernetes postrouting rules" -j KUBE-POSTROUTING',
      "POSTROUTING -s #{subnet}(.*)-j MASQUERADE"
    ]
    @result = _host.exec_admin("iptables-save -t nat")
    nat_matches.each { |match|
      unless @result[:success] && @result[:response] =~ /#{match}/
        raise "The nat table verification failed!"
      end
    }
  }

  @result = _host.exec_admin("firewall-cmd --state")
  if @result[:success] && @result[:response] =~ /running/
    firewalld_verify.call
    logger.info "Cluster network #{subnet} saved into the :clusternetwork clipboard"
    teardown_add firewalld_verify
  else
    iptables_verify.call
    logger.info "Cluster network #{subnet} saved into the :clusternetwork clipboard"
    teardown_add iptables_verify
  end
end


Given /^admin adds( and overwrites)? following annotations to the "(.+?)" netnamespace:$/ do |overwrite, netnamespace, table|
  ensure_admin_tagged
  _admin = admin
  _netnamespace = netns(netnamespace, env)
  _annotations = _netnamespace.annotations

  table.raw.flatten.each { |annotation|
    if overwrite
      @result = _admin.cli_exec(:annotate, resource: "netnamespace", resourcename: netnamespace, keyval: annotation, overwrite: true)
    else
      @result = _admin.cli_exec(:annotate, resource: "netnamespace", resourcename: netnamespace, keyval: annotation)
    end
    raise "The annotation '#{annotation}' was not successfully added to the netnamespace '#{netnamespace}'!" unless @result[:success]
  }

  teardown_add {
    current_annotations = _netnamespace.annotations(cached: false)
    
    unless current_annotations == _annotations
      current_annotations.keys.each do |annotation|
        @result = _admin.cli_exec(:annotate, resource: "netnamespaces", resourcename: netnamespace, keyval: "#{annotation}-")
        raise "The annotation '#{annotation}' was not removed from the netnamespace '#{netnamespace}'!" unless @result[:success]
      end

      if _annotations
        _annotations.each do |annotation, value|
          @result = _admin.cli_exec(:annotate, resource: "netnamespaces", resourcename: netnamespace, keyval: "#{annotation}=#{value}")
          raise "The annotation '#{annotation}' was not successfully added to the netnamespace '#{netnamespace}'!" unless @result[:success]
        end
      end
      # verify if the restoration process was succesfull
      current_annotations = _netnamespace.annotations(cached: false)
      unless current_annotations == _annotations
        raise "The restoration of netnamespace '#{netnamespace}' was not successfull!"
      end
    end
  } 
end
