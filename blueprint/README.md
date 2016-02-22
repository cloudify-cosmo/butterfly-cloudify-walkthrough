# cfy-local-nodejs-mongodb

## Summary

Deploys any NodeJS/Mongo Application using cfy local on AWS and Openstack.

A bit more detailed explanation:

In Cloudify, you describe applications and their infrastructure in blueprints. Blueprints are files that are supported by scripts and other resources in a single archive. You can also import other code using plugins.

cfy local refers to executing Cloudify blueprints in local mode.

There are three blueprints in this repository. One blueprint, application-blueprint.yaml describes a Node application with a Mongo database backend. The script in scripts/tasks.py contain the code that installs Node and Mongo. You can deploy entire example by running just this blueprint in Cloudify.

There are two other blueprints openstack-blueprint.yaml and aws-ec2-blueprint.yaml. These describe a simple infrastructure in these two IaaS providers (Openstack and AWS).

After executing one of these, you can take the outputs and execute the application-blueprint.yaml if you want to.

## Application
The default application is the [Nodecellar](http://coenraets.org/blog/2012/10/nodecellar-sample-application-with-backbone-js-twitter-bootstrap-node-js-express-and-mongodb/) application.

## Prerequisites

* RHEL 7, Centos 7, or Ubuntu 14.04
* Python 2.7
* Cloudify

Additionally, you will need probably unzip and curl if you install Cloudify with the below instructions.

## How to Install

First, Install Cloudify: http://docs.getcloudify.org/3.3.0/intro/installation/

Unofficial install Cloudify:

```bash
curl -L -o get-cloudify.py http://gigaspaces-repository-eu.s3.amazonaws.com/org/cloudify3/get-cloudify.py
sudo python get-cloudify.py --force
source /opt/cfy/env/bin/activate
```

Get this example:

```bash
curl -L -o cfy-local-nodejs-mongodb.zip https://github.com/EarthmanT/cfy-local-nodejs-mongodb/archive/master.zip
unzip cfy-local-nodejs-mongodb.zip
```

### Set up a local environment (no IaaS):

Create keys local:

```bash
ssh-keygen
```

* Name the keypair: ~/.ssh/cfy_local_keypair.pem
* [enter], [enter], [enter]

```bash
cat ~/.ssh/cfy_local_keypair.pem > ~/.ssh/authorized_keys
```

Running the Blueprint:

```bash
cd cfy-local-nodejs-mongodb-master
cfy local init --install-plugins -p simple-blueprint.yaml
cfy local execute -w install --task-retries=9 --task-retry-interval=10
```

Then go to http://YourIPAddress:8080.

### Set up an IaaS (e.g. AWS OR Openstack) environment:

First create work directories

```bash
mkdir infrastructure
mkdir application
```

Now, make a copy of the appropriate infrastructure inputs:

For AWS:

```bash
cp inputs/aws-ec2-inputs.yaml infrastructure/inputs.yaml
```

OR for Openstack:

```bash
cp inputs/openstack-inputs.yaml infrastructure/inputs.yaml
```

You'll need to make some minor adjustments to the inputs file to provide your own IaaS provider credentials.

Now, execute the install workflow for the infrastructure:

For AWS:

```bash
(cd infrastructure && cfy local init --install-plugins -p ../aws-ec2-blueprint.yaml -i inputs.yaml && cfy local execute -w install --task-retries=9 --task-retry-interval=10 && cfy local outputs)
```
OR, for Openstack:

```bash
(cd infrastructure && cfy local init --install-plugins -p ../openstack.yaml -i inputs.yaml && cfy local execute -w install --task-retries=9 --task-retry-interval=10 && cfy local outputs)
```

When the command is finished you'll see the outputs from that blueprint. You'll notice that they correspond to the inputs on the applcation blueprint:

```
{
  "application": {
    "application_server_port": ...,
    "nodejs_host_ip": "...",
    "nodejs_host_public_key_path": "..."
  },
  "database": {
    "mongo_host_ip": "...",
    "mongo_host_public_key_path": "...",
    "mongo_port": ...
  }
}
```

Create the inputs file:
```bash
cp inputs/application-inputs.yaml application/inputs.yaml
```

Now take the values from the outputs of the last command, and replace them in application/inputs.yaml. By default, you should only need to replace the nodejs_host_ip and mongo_host_ip values.

Then run:
```bash
(cd application && cfy local init --install-plugins -p ../application-blueprint.yaml -i inputs.yaml  && cfy local execute -w install --task-retries=9 --task-retry-interval=10 && cfy local outputs)
```

To see the application, you can go to http://[THE APPLICATION URL]:8080/.

To uninstall the application run:
```bash
(cd application && cfy local execute -w uninstall --task-retries=9 --task-retry-interval=10)
```

To uninstall the infrastructure:
```bash
(cd infrastructure && cfy local execute -w uninstall --task-retries=9 --task-retry-interval=10)
```