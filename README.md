Vagrant Framework:
==================

* A VM Provider and Provisioning tool to help with local/cloud development, deployment and testing.
* Use cases:
    * Develop automation scripts locally, switch to test in the cloud.
    * Deploy a group of servers at a time to AWS, bring down as a group.
* Prerequisites:
    * For Local Dev:
        * Install Virtualbox: https://www.virtualbox.org/wiki/Downloads
        * Install Vagrant: http://downloads.vagrantup.com/
    * For AWS Deploys:
        * Install Vagrant AWS Plugin: `vagrant plugin install vagrant-aws`
        * Obtain AWS key and place in vagrant/keys/
        * Update AWS config in vagrant/keys/awsKeys.yaml
* Setup:
    * Create project workspace: `mkdir -p /path/to/my/project`
    * Clone this framework: `git clone https://github.com/tylerwalts/framework-vagrant.git`
    * CD to this framework: `cd framework-vagrant`
    * Install this framework to your project: `./install.sh /path/to/my/project`
    * (optional) Cleanup this framework:  `rm -rf framework-vagrant`
* Usage:
    * All commands below assume your current working directory (cwd) is at the root of your project.
    * Develop Locally:
        * Launch local test:  `vagrant up`
        * Use local test:  `vagrant ssh`
        * Kill local test:  `vagrant destroy`
    * Test in AWS:
        * Launch AWS:  `vagrant up --provider aws`
        * Use AWS:  `vagrant ssh`
        * Kill AWS:  `vagrant destroy`
    * Switch list of nodes to use:
        * Set env flag: `export nodes=myList`
        * Or, edit Vagrantfile ~ line 20 marked by `### List of Nodes ###` to comment/uncomment
        * Or, create a new list in tools/vagrant/nodeLists/ and do one of above




[![Bitdeli Badge](https://d2weczhvl823v0.cloudfront.net/tylerwalts/framework-vagrant/trend.png)](https://bitdeli.com/free "Bitdeli Badge")

