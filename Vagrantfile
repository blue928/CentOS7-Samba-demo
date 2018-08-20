# -*- mode: ruby -*-
# vi: set ft=ruby :


# https://github.com/hashicorp/vagrant/issues/1874#issuecomment-165904024
# not using 'vagrant-vbguest' vagrant plugin because now using bento images which has vbguestadditions preinstalled.
def ensure_plugins(plugins)
  logger = Vagrant::UI::Colored.new
  result = false
  plugins.each do |p|
    pm = Vagrant::Plugin::Manager.new(
      Vagrant::Plugin::Manager.user_plugins_file
    )
    plugin_hash = pm.installed_plugins
    next if plugin_hash.has_key?(p)
    result = true
    logger.warn("Installing plugin #{p}")
    pm.install_plugin(p)
  end
  if result
    logger.warn('Re-run vagrant up now that plugins are installed')
    exit
  end
end

required_plugins = ['vagrant-hosts', 'vagrant-share', 'vagrant-vbox-snapshot', 'vagrant-host-shell', 'vagrant-reload']
ensure_plugins required_plugins



Vagrant.configure(2) do |config|
  config.vm.define "samba_storage" do |samba_storage_config|
    samba_storage_config.vm.box = "bento/centos-7.5"
    samba_storage_config.vm.hostname = "samba-storage.local"
    # https://www.vagrantup.com/docs/virtualbox/networking.html
    samba_storage_config.vm.network "private_network", ip: "10.0.4.10", :netmask => "255.255.255.0", virtualbox__intnet: "intnet2"

    samba_storage_config.vm.provider "virtualbox" do |vb|
      vb.gui = true
      vb.memory = "1024"
      vb.cpus = 2
      vb.customize ["modifyvm", :id, "--clipboard", "bidirectional"]
      vb.name = "centos7_samba_storage"
    end

    samba_storage_config.vm.provision "shell", path: "scripts/install-rpms.sh", privileged: true
    samba_storage_config.vm.provision "shell", path: "scripts/samba_server_setup.sh", privileged: true
  end


  config.vm.define "samba_client" do |samba_client_config|
    samba_client_config.vm.box = "bento/centos-7.5"
    samba_client_config.vm.hostname = "samba-client.local"
    samba_client_config.vm.network "private_network", ip: "10.0.4.11", :netmask => "255.255.255.0", virtualbox__intnet: "intnet2"

    samba_client_config.vm.provider "virtualbox" do |vb|
      vb.gui = true
      vb.memory = "1024"
      vb.cpus = 2
      vb.name = "centos7_samba_client"
    end

    samba_client_config.vm.provision "shell", path: "scripts/install-rpms.sh", privileged: true
    samba_client_config.vm.provision "shell", path: "scripts/samba_client_setup.sh", privileged: true
  end

  config.vm.provision :hosts do |provisioner|
    provisioner.add_host '10.0.4.10', ['samba-storage.local']
    provisioner.add_host '10.0.4.11', ['samba-client.local']
  end

end