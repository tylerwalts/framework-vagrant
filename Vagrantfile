domain = 'example.com'

# Note: First time users run this:  `vagrant plugin install vagrant-aws`
require 'yaml'
Vagrant.require_plugin "vagrant-aws"
begin
    awsKeys = YAML.load_file("keys/awsKeys.yaml")
rescue
    awsKeys ||= {accessKey:'a',secretKey:'b',keypair:'c',keypath:'d'}
end

# Get list of base image configs:
imageTypes = YAML.load_file("tools/vagrant/imageTypes.yaml")
imageTypes ||= {accessKey:'foo',secretKey:'bar'} # Prevent fail for local only dev

### Node List ###
# Use environment var, or default below:
nodeList = ENV['nodes']
nodeList ||= 'dev'
#nodeList ||= 'cluster'
p "Using node list: #{nodeList}"
nodes = YAML.load_file("tools/vagrant/nodeLists/#{nodeList}.yaml")

Vagrant.configure("2") do |config|

    ### Provide VMs ###
    nodes.each do |node|
        config.vm.define node['hostname'] do |node_default|

            # Default settings for all providers
            node_default.vm.hostname = node['hostname']
            node_default.vm.box = 'OverrideMe'
            node_default.vm.box_url = 'http://override.me'

            # Amazon
            node_default.vm.provider :aws do |aws, override|
                domain = domain
                override.vm.hostname           = node['hostname'] + '.' + domain
                aws.access_key_id              = awsKeys['accessKey']
                aws.secret_access_key          = awsKeys['secretKey']
                aws.keypair_name               = awsKeys['keypair']
                override.ssh.private_key_path  = awsKeys['keypath']
                override.ssh.username          = "root"
                aws.region                     = "us-east-1"
                aws.ami                        = imageTypes[ node['imageType'] ]['amazonImage']
                aws.instance_type              = node['awsType']
            end

            # VirtualBox
            node_default.vm.provider :virtualbox do |vb, override|
                override.vm.hostname = node['hostname'] + domain
                override.vm.box = imageTypes[ node['imageType'] ]['vagrantBox']
                override.vm.box_url = imageTypes[ node['imageType'] ]['vagrantUrl']
                override.vm.network :private_network, ip: node['ip']
                node['portmappings'] && node['portmappings'].each do |portmap|
                    override.vm.network :forwarded_port, guest: portmap['from'], host: portmap['to']
                end
                vb.customize [
                    'modifyvm', :id,
                    '--name', node['hostname'],
                    '--memory', node['ram'],
                    "--natdnsproxy1", "off",
                    "--natdnshostresolver1", "off"
                ]
                vb.customize ["setextradata", :id, "VBoxInternal2/SharedFoldersEnableSymlinksCreate/v-root", "1" ]
            end

            # Rackspace
            # TODO

        end
    end

    ### Provision VMs ###
    # Assume using the puppet apply wrapper with librarian argument
    config.vm.provision :shell do |shell|
        shell.inline = "/vagrant/tools/puppet/run_puppet_apply.sh -l"
    end

end
