# October 2016 - Mattermost

[Mattermost](https://www.mattermost.org/) is an open-source alternative to enterprise messaging services such as [Slack](https://slack.com) and [HipChat](http://www.hipchat.com/).


## Pros

- Self-hosted (allows you to keep control of the messages instead of using a hosted service)
- Free

## Cons

- Missing some features (e.g. link expansion)
- Push notifications for messages are not encrypted by default
  - Mattermost provides encrypted push notifications to enterprise customers (current price is [$20/year per user](https://about.mattermost.com/pricing/)).
  - A do-it-yourself alternative for encrypted push notifications
    - Generate your own push notification keys
    - Manually compile the smartphone app (which is open-source)
    - Note: this has to be done separately for both Android and iOS
    - Doing something like this is out of the scope of this presentation, but this document will be updated in the future if I get this set up.
  - Mattermost provides a testing push notifictation service which provides unencrypted notifications
    - Production uptime not guaranteed
    - Intended for evaluation purposes
  - More information on push notifications [here](https://docs.mattermost.com/deployment/push.html)


## Deployment

Deployment is not turnkey, you need to do a lot of things:

- Create a database
- Add a database user and grant privileges to that user
- Install the application
- Setup nginx to proxy web traffic to the application

Install guides can be found [here](https://www.mattermost.org/installation/).

For this demo we'll be deploying to a CentOS 7 server hosted with [Vultr](https://vultr.com/), using [Salt](https://saltstack.com/community/) to handle all the deployment steps. The more commonly-used agent-based setup for Salt requires the client (i.e. "minion") to be able to connect to the Salt master. Since this demo is being run from a laptop, and we can't get the minion to connect through the library firewall, we will use Salt's SSH-based agentless tool, [salt-ssh](https://docs.saltstack.com/en/latest/topics/ssh/).

The walkthrough for installing Mattermost on a CentOS 7 server can be found [here](https://docs.mattermost.com/install/prod-rhel-7.html).

### Installing salt-ssh

#### System Packages

There are packages for salt-ssh available for several platforms at [repo.saltstack.com](https://repo.saltstack.com).

#### Using pip

As salt-ssh is a standalone tool that requires no daemon on the master nor the minion, you can do a simple ``pip install``.

```
# pip install salt-ssh
```

When I install from pip, I prefer to do so in a virtualenv so that I am not installing via pip to a location where system packages might also get installed:

```
# mkdir ~/venv
# virtualenv ~/venv/salt
# source ~/venv/salt/bin/activate
# pip install salt-ssh
```

Note: for distros like Arch Linux in which ``python`` refers to Python 3, you may need to use ``virtualenv2`` to create the virtualenv using Python2.

##### Optional: Install from a git clone

If you absolutely want to use the latest code, pip will allow you to install from a git clone. Simply clone the repo and then use the ``--editable`` option when installing using pip.

```
# mkdir -p ~/git
# git clone https://github.com/saltstack/salt ~/git/salt
# pip install --editable ~/git/salt
```

### Setting up a roster file for salt-ssh

To use salt-ssh, a [roster](https://docs.saltstack.com/en/latest/topics/ssh/roster.html) is required so that Salt knows how to connect to the hosts it will manage. The default roster type is a simple YAML file:

```
mattermost.foxvalleylug.org:
  host: mattermost.foxvalleylug.org
  user: root
  passwd: thisisnotarealpassword
  tty: False
  minion_opts:
    postgres.host: localhost
    postgres.port: 5432
    postgres.user: postgres
    postgres.pass: postgres_user_pass_goes_here
    postgres.bins_dir: /usr/pgsql-9.4/bin
    postgres.mm_database_name: mattermost
    postgres.mm_database_user: mmuser
    postgres.mm_database_pass: mattermost_user_pass_goes_here
```

The roster should be saved to ``/etc/salt/roster``.

The ``minion_opts`` are options that will be set on the remote host that will be effective during the salt-ssh run. These options are required for Salt to manage PostgreSQL databases.

### Configuration files

Configs can be found in the [salt](https://github.com/foxvalleylug/meetings/tree/master/2016/10/salt) subdirectory. There are two subdirectories here:

1. [sls](https://github.com/foxvalleylug/meetings/tree/master/2016/10/salt/sls) - contains all of the files needed to deploy Mattermost
2. [pillar](https://github.com/foxvalleylug/meetings/tree/master/2016/10/salt/pillar) - contains user-defined variables

The files in the ``sls`` subdir should be copied to ``/srv/salt``, and the files in the ``pillar`` subdir should be copied to ``/srv/pillar``. These are the default locations for these files.

### Running salt-ssh

The first time you run salt-ssh, if you don't have the remote host's SSH host
key in your ``known_hosts`` file, you will need to run the command with ``-i``
to accept the host key:

```
# salt-ssh mattermost.foxvalleylug.org test.ping
mattermost.foxvalleylug.org:
    ----------
    retcode:
        254
    stderr:
    stdout:
        The host key needs to be accepted, to auto accept run salt-ssh with the -i flag:
        The authenticity of host 'mattermost.foxvalleylug.org (45.63.78.189)' can't be established.
        ECDSA key fingerprint is SHA256:kZFmsFq/9047FxhYBUvbWbOzfzmghl8rgkYHj+ja4og.
        Are you sure you want to continue connecting (yes/no)?
# salt-ssh mattermost.foxvalleylug.org test.ping -i
mattermost.foxvalleylug.org:
    True
```

### Let's Encrypt pre-setup

Let's Encrypt requires domain verification. That is, there must be a webpage at the domain you wish to protect. So, before I did anything, I manually installed nginx on the remote server, opened port 80 in firewalld, and ran the initial setup. I then created a tar archive of the /etc/letsencrypt directory, retrieved it from the server, and then rebuilt the cloud VM so it was back to a fresh instance.

```
# yum -y install nginx
# systemctl start nginx
# firewall-cmd --zone=public --add-port=80/tcp
# wget https://dl.eff.org/certbot-auto
# chmod +x certbot-auto
# ./certbot-auto certonly --webroot --webroot-path /usr/share/nginx/html --renew-by-default --email user@domain.tld --text --agree-tos -d mattermost.foxvalleylug.org
# tar -C /etc -czf /root/letsencrypt.tar.gz letsencrypt
```

The ``certbot-auto`` script is a Let's Encrypt client that supports a number of different authentication methods. We're using the webroot method here, in which the script will write a file to the ``--webroot-path``, and then contact Let's Encrypt and have it read that file for verification.

The ``letsencrypt.tar.gz`` is notably not in this repo, partly because it's a binary file (which are not handled efficiently by Git), and also because it'd be useless to anyone who wants to use this walkthrough on their own server.

The steps I used to generate my SSL certificate were loosely based off of [this walkthrough](https://community.letsencrypt.org/t/how-to-get-a-lets-encrypt-certificate-while-using-cloudflare/6338). I ended up using this client because I had trouble authenticating my site using the default client. This may have just been user error or ignorance, but in the end the ``certbot-auto`` client worked for me so that is what I used.

### Deploying using Salt orchestration

We will be using salt's [orchestrate runner](https://docs.saltstack.com/en/latest/topics/orchestrate/orchestrate_runner.html) for this deployment. This allows us to deploy the different components in stages, and not proceed with the next stage unless the prior stage has completed successfully.

I included both SSL and non-SSL deployments in this example. For our demo, we will be using SSL, with the keys I created earlier using ``certbot-auto``.

The orchestration configs can be found [here](https://github.com/foxvalleylug/meetings/tree/master/2016/10/salt/sls/mattermost/ssl.sls), and the Salt configs are in the [deploy](https://github.com/foxvalleylug/meetings/tree/master/2016/10/salt/sls/mattermost/deploy) subdirectory.

To kick off the orchestration, we just need to run:

```
# salt-run state.orchestrate mattermost.ssl
```

### Deployment notes

- When upgrading, make sure to check config.json to make sure that the ``SqlSettings`` section hasn't changed. The [file.serialize](https://github.com/foxvalleylug/meetings/blob/master/2016/10/salt/sls/mattermost/deploy/server.sls#L54-L71) state will replace the entire ``SqlSettings`` section, so we need to specify all settings in that section.
- We can't use ``file.managed`` to manage config.json, because Mattermost alters that file, writing configuration created while Mattermost is running to it. So we don't want to stomp on those changes. That is the reason for using [file.serialize](https://github.com/foxvalleylug/meetings/blob/master/2016/10/salt/sls/mattermost/deploy/server.sls#L54-L71). This will usually result in a big diff showing in the results when applying changes, because the order in which the json values are dumped by python is different from however Mattermost writes the file.
- There is a bug in the nginx package for CentOS 7, it specifies a different path for the service's PID file than is specified in the nginx config file. Therefore, we have to deploy an [overridden unit file for nginx](https://github.com/foxvalleylug/meetings/blob/master/2016/10/salt/sls/mattermost/deploy/nginx-base.sls#L8-L18).
