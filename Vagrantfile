# Note: First time users run this:  `vagrant plugin install vagrant-aws`
require 'yaml'
Vagrant.require_plugin "vagrant-aws"

awsKeys = {
  "accessKey"       => ENV['AWS_ACCESS_KEY']        || 'define_access',
  "secretKey"       => ENV['AWS_SECRET_KEY']        || 'define_secret',
  "keypair"         => ENV['AWS_KEYPAIR']           || 'define_keypair',
  "keypath"         => ENV['AWS_KEYPATH']           || 'define_keypath', 
  "security_group"  => ENV['AWS_SECURITY_GRP_ID']   || 'default'
}
begin
  awsKeys.merge! YAML.load_file("#{File.dirname(__FILE__)}/tools/vagrant/keys/awsKeys.yaml")
rescue
  p "AWS keys file was missing, using environment vairables/defaults"
end

# Get list of base image configs:
begin
  imageTypes = YAML.load_file("#{File.dirname(__FILE__)}/tools/vagrant/imageTypes.yaml")
rescue
  imageTypes ||= {vagrantBox:'a',vagrantUrl:'b',amazonImage:'c',rackspaceImage:'d'}
end

### Node List ###
# Use environment var, or default below:
nodeList = ENV['nodes']
nodeList ||= 'dev'
#nodeList ||= 'cluster'
p "Using node list: #{nodeList}"
nodes = YAML.load_file("#{File.dirname(__FILE__)}/tools/vagrant/nodeLists/#{nodeList}.yaml")

Vagrant.configure("2") do |config|
    ### Provide VMs ###
    nodes.each do |node|
        fqdn="#{node['hostname']}.#{node['domain']}"
        config.vm.define node['hostname'] do |node_default|

            # Default settings for all providers
            node_default.vm.hostname = node['hostname']
            node_default.vm.box = 'Aws_Dummy_Box'
            node_default.vm.box_url = 'https://github.com/mitchellh/vagrant-aws/raw/master/dummy.box'

            # Amazon
            node_default.vm.provider :aws do |aws, override|
                aws.access_key_id              = awsKeys['accessKey']
                aws.secret_access_key          = awsKeys['secretKey']
                aws.security_groups            = [awsKeys['security_group']].flatten
                aws.keypair_name               = awsKeys['keypair']
                override.ssh.private_key_path  = awsKeys['keypath']
                override.ssh.username          = "root"
                aws.region                     = "us-east-1"
                aws.ami                        = imageTypes[ node['imageType'] ]['amazonImage'][awsKeys['region']]
                aws.instance_type              = node['awsType']
            end

            # VirtualBox
            node_default.vm.provider :virtualbox do |vb, override|
                fqdn = "#{node['hostname']}.vagrant.#{node['domain']}"
                override.vm.hostname           = fqdn
                override.vm.box                = imageTypes[ node['imageType'] ]['vagrantBox']
                override.vm.box_url            = imageTypes[ node['imageType'] ]['vagrantUrl']
                override.vm.network :private_network, ip: node['ip']
                node['portmappings'] && node['portmappings'].each do |portmap|
                    override.vm.network :forwarded_port, guest: portmap['from'], host: portmap['to']
                end
                vb.customize [
                    'modifyvm', :id,
                    '--name', fqdn,
                    '--memory', node['ram'],
                    "--natdnsproxy1", "off",
                    "--natdnshostresolver1", "off"
                ]
                vb.customize ["setextradata", :id, "VBoxInternal2/SharedFoldersEnableSymlinksCreate/v-root", "1" ]
            end

            # Rackspace
            # TODO

            ### Provision VMs ###
            # Assume using the puppet apply wrapper with librarian argument
            config.vm.provision :shell do |shell|
                shell.inline = "/vagrant/tools/puppet/run_puppet_apply.sh -l"
            end
        end
    end
end
