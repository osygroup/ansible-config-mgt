# Project 6: Ansible Dynamic Assignments (Include) and Community Roles

From Project 5, static assignments use *import* Ansible module. The
module that enables dynamic assignments is *include*.

Hence:

*import* = Static and *include* = Dynamic

When the *import* module is used, all statements are pre-processed at
the time playbooks are parsed. Meaning, when you execute *site.yml*
playbook, Ansible will process all the playbooks referenced during the
time it is parsing the statements. This also means that, during actual
execution, if any statement changes, such statements will not be
considered. Hence, it is static.

On the other hand, when *include* module is used, all statements are
processed only during execution of the playbook. Meaning, after the
statements are parsed, any changes to the statements encountered during
execution will be used.

For dynamic re-use, add an include\_\* task in the tasks section of a
play:

*include_role*

*include_tasks*

*include_vars*

For static re-use, add an import\_\* task in the tasks section of a
play:

*import_role*

*import_tasks*

Task *include* and *import* statements can be used at arbitrary depth.

## Pre-requisite

Create five new virtual machines in the Virtual network used for the
Tooling webapp:

Three RHEL 8 servers for the webservers

One Ubuntu 20.04 LTS server for the MySQL server

One Ubuntu 20.04 LTS server for the load balancer

## Step 1: Introducing Dynamic Assignment into the structure

Check the branch that git is currently switched to:

*\$ git branch*

Create a new branch (named *dynamic)* off the *refactor* branch and
switch to it immediately:

*\$ git checkout -b dynamic refactor*

Create a new folder, name it *dynamic-assignments*. Then inside this
folder, create a new file and name it *env-vars.yml*.

Since we will be using the same Ansible to configure multiple
environments, and each of these environments will have certain unique
attributes, such as servername, ip-address etc., we will need a way to
set values to variables per specific environment.

For this reason, we will now create a folder to keep each environment's
variables file. Therefore, create a new folder *env-vars* in the Ansible
folder, then for each environment, create new YAML files which we will
use to set variables.

The layout should now look like this:

![](https://github.com/osygroup/Images/blob/main/Ansible-Dynamic/image1.png)

Paste the instruction below into the env-vars.yml file.

*\-\--*

*- name: collate variables from env specific file, if it exists*

*hosts: all*

*tasks:*

*- name: looping through list of available files*

*include_vars: \"{{ item }}\"*

*with_first_found:*

*- files:*

*- dev.yml*

*- stage.yml*

*- prod.yml*

*- stage.yml*

*- default.yml*

*paths:*

*- \"{{ playbook_dir }}/../env-vars\"*

*tags:*

*- always*

Update *site.yml* with dynamic assignments by adding the following:

*- name: Import dynamic variables*

*import_playbook: ../dynamic-assignments/env-vars.yml hostlist=all*

*tags:*

*- always*

*site.yml* should now look like this:

![](https://github.com/osygroup/Images/blob/main/Ansible-Dynamic/image2.png)

Update the inventory/dev file to add the new servers created. In the
screenshot below, new groups were created for the new servers:
*ansible-webserver* (for the three webservers) *db-ansible* (for the
MySQL server) and *lb-ansible* (for the load balancer):

![](https://github.com/osygroup/Images/blob/main/Ansible-Dynamic/image3.png)

In the tooling app folder that was cloned to the Ansible server, edit
the *html/functions.php* file and change the private IP address of the
database to the private IP of the new MySQL server:

![](https://github.com/osygroup/Images/blob/main/Ansible-Dynamic/image4.png)

## Step 2: Create roles

The roles will be created for MySQL, Nginx load balancer and Let's
Encrypt.

### Mysql Role:

Create a MySQL role in the *roles* directory by downloading a MySQL role
from Ansible Galaxy (created by 'geerlingguy'):

*\$ ansible-galaxy install geerlingguy.mysql*

Rename the role folder from *geerlingguy.mysql* to *mysql.*

*\$ sudo mv geerlingguy.mysql mysql*

Enter the *mysql* role directory, open the defaults/main.yml file and
edit it to create a user named 'webaccess' and a database named
'tooling':

*\# Databases.*

*mysql_databases:*

*- name: tooling*

*\# collation: utf8_general_ci*

*\# encoding: utf8*

*\# replicate: 1*

*\# Users.*

*mysql_users:*

*- name: webaccess*

*host: \"%\"*

*password: Password11\#*

*priv: \"tooling.\*:ALL\"*

![](https://github.com/osygroup/Images/blob/main/Ansible-Dynamic/image5.png)

Add the following to the *defaults/main.*yml file (as seen in the
screenshot above immediately after the *Users* section). This table is
in the tooling repository cloned on the Ansible host:

*\#location of tooling app database table to be dumped in the MySQL
server*

*tooling_database_location: \"/home/azureuser/tooling/tooling-db.sql\"*

Add this at the bottom of the *tasks/main.yml* file to dump the database
table:

*- name: Copy tooling app database table*

*  copy:*

*       src: \"{{ tooling_database_location }}\"*

*       dest: /home/*

*- name: Dump tooling app database table*

*mysql_db:*

*name: tooling*

*state: import*

*target: /home/tooling-db.sql*

Navigate back to the *static-assignments* directory and create a new
playbook for the MySQL role named mysqldb*.yml*. This is where the MySQL
role will be referenced.

*\-\--*

*- name: set up MySQL Server*

*hosts: \"{{ hostlist }}\"*

*tasks:*

*- name: Update server*

*package:*

*name: \'\*\'*

*state: latest*

*only_upgrade: yes*

*roles:*

*- mysql*

*become: true*

### Nginx Load Balancer role:

Create an Nginx role in the *roles* directory by downloading an Nginx
role from Ansible Galaxy (created by 'geerlingguy'):

*\$ ansible-galaxy install geerlingguy.nginx*

Rename the role folder from *geerlingguy.nginx* to *nginx.*

In *defaults/main.*yml file of the Nginx role, change the
*nginx_remove_default_vhost* from *false* to *true*. This will prevent
the installation from creating any default vhost file in the
*sites-enabled* directory of Nginx.

![](https://github.com/osygroup/Images/blob/main/Ansible-Dynamic/image6.jpeg)

At the end of the file, add the following variables:

*enable_nginx_lb: true*

*load_balancer_is_required: true*

Go into *templates* directory and create and create the load balancer
configuration file with a text editor. The config file will be saved as
a Jinja 2 template file e.g. *load-balancer.conf.j2*. Copy and paste the
below configuration into the .conf.j2 file created:

*\# Define which servers to include in the load balancing scheme.*

*\# It\'s best to use the servers\' private IPs for better performance
and security.*

*upstream backend {*

*       server \<webserver1_private_IP\>;*

*       server \<webserver2_private_IP\>;*

*       server \<webserver3_private_IP\>;*

*}*

*\# This server accepts all traffic to port 80 and passes it to the
upstream.*

*\# Notice that the upstream name and the proxy_pass need to match.*

*server {*

*      listen 80;*

*server_name \<domain_name\> www.\<domain_name\>;*

*      location / {*

*          proxy_pass http://backend;*

*      }*

*}*

![](https://github.com/osygroup/Images/blob/main/Ansible-Dynamic/image7.jpeg)

In *tasks/main.yml* file, copy the tow tasks below and insert it before
the last task (Ensure nginx service is running as configured).

*- name: Set up load-balancer config file*

*template:*

*src: \"load-balancer.conf.j2\"*

*dest: \"/etc/nginx/conf.d/load-balancer.conf\"*

*- name: Delete default.conf file from conf.d directory*

*ansible.builtin.file:*

*path: /etc/nginx/conf.d/default.conf*

*state: absent*

![](https://github.com/osygroup/Images/blob/main/Ansible-Dynamic/image8.jpeg)

The first task will move the *load-balancer.conf* file to
*/etc/nginx/conf.d/* directory and the second task will delete the
*default.conf* file created by the Nginx installation so that only the
load balancer config will be available.

Navigate back to the *static-assignments* directory and create a new
playbook for the load balancer role named *loadbalancers.yml*. This is
where the Nginx load balancer role will be referenced.

*\-\--*

*- name: set up LB*

*hosts: \"{{ hostlist }}\"*

*tasks:*

*- name: Update server*

*package:*

*name: \'\*\'*

*state: latest*

*only_upgrade: yes*

*roles:*

*- { role: nginx, when: enable_nginx_lb and load_balancer_is_required }*

*\# - { role: apache, when: enable_apache_lb and
load_balancer_is_required }*

*become: true*

To create a role for Apache load balancer, you can decide to develop
your own roles or find available ones from the [Ansible Galaxy
community](https://galaxy.ansible.com/home).

Make use of env-vars\\uat.yml file to define which load balancer to use
in UAT environment by setting respective environmental variable to true.

Activate load balancer and enable Nginx by setting these in the
respective environment's env-vars file:

*enable_nginx_lb: true*

*load_balancer_is_required: true*

![](https://github.com/osygroup/Images/blob/main/Ansible-Dynamic/image9.png)

### Let's Encrypt role:

Run the code below within the *roles* folder to create a role for Let's
Encrypt (to configure Secure Connection to an Nginx Load Balancer):

*\$ sudo ansible-galaxy init letsencrypt*

In the *letsencrypt* directory, add the following into the
*defaults/main.yml* file:

*certbot_site_name: \"\<domain_name\>\"*

*certbot_package: \"python3-certbot-nginx\"*

*certbot_plugin: \"nginx\"*

*certbot_mail_address: \<your_email_address\>*

![](https://github.com/osygroup/Images/blob/main/Ansible-Dynamic/image10.png)

NOTE: Don't forget to create a DNS record of type 'A' on the domain name
that points to the public IP address of the load balancer and open port
443 (port number for https) in the Inbound port rules of the Network
Security Group of the load balancer VM.

In the *tasks/main.yml* file, add the below tasks:

*\-\--*

*\# tasks file for letsencrypt*

*- name : Install Core*

*command: \"snap install core\"*

*#- name : Remove certbot if installed previously*

*#command: \"rm /usr/bin/certbot\"*

*- name : Install Certbot*

*command: \"snap install \--classic certbot\"*

*- name : Ensure that the certbot command can be run*

*command: \"ln -s /snap/bin/certbot /usr/bin/certbot\"*

*- name: Create and Install Cert Using {{ certbot_plugin }} Plugin*

*command: \"certbot \--{{ certbot_plugin }} -d {{ certbot_site_name }}
-m {{ certbot_mail_address }} \--agree-tos \--noninteractive\"*

*- name: Set Letsencrypt Cronjob for Certificate Auto Renewal*

*cron: name=letsencrypt_renewal special_time=monthly
job=\"/usr/bin/certbot renew\"*

*when: ansible_facts\[\'os_family\'\] == \"Debian\"*

Navigate back to the *static-assignments* directory and create a new
playbook for the Let's Encrypt role named *letsencrypt.yml*. This is
where the Let's Encrypt role will be referenced.

*\-\--*

*- name: Setup Let\'s Encrypt for Debian*

*hosts: \"{{ hostlist }}\"*

*roles:*

*- letsencrypt*

*become: true*

Update the site.yml file to include all the new roles created:

*\-\--*

*- name: Update server, disable firewall and disable SELinux*

*import_playbook: ../static-assignments/update.yml
hostlist=webserver-ansible*

*- name: Install Git*

*import_playbook: ../static-assignments/common.yml
hostlist=webserver-ansible*

*- name: Set up tooling webserver*

*import_playbook: ../static-assignments/webservers.yml
hostlist=webserver-ansible*

*- name: Install RHEL PHP*

*import_playbook: ../static-assignments/php-rhel.yml
hostlist=webserver-ansible*

*- name: Import dynamic variables*

*import_playbook: ../dynamic-assignments/env-vars.yml hostlist=all*

*tags:*

*- always*

*- name: Install MySQl DB*

*import_playbook: ../static-assignments/mysqldb.yml hostlist=db-ansible*

*- name: Setup LB*

*import_playbook: ../static-assignments/loadbalancers.yml
hostlist=lb-ansible*

*when: load_balancer_is_required*

*- name: Install Let\'s Encrypt on load balancer*

*import_playbook: ../static-assignments/letsencrypt.yml
hostlist=lb-ansible*

Run the export command on the terminal to let Ansible know where to find
the configuration file. 

*\$ export ANSIBLE_CONFIG=\<full_path_to_ansible.cfg_file\>*

Once this is exported, all the roles will be activated.

Now check if all the roles were activated and are ready to be used.

*\$ ansible-galaxy role list*

![](https://github.com/osygroup/Images/blob/main/Ansible-Dynamic/image11.png)

Navigate out of the ansible directory and run the *site.yml* playbook

*\$ ansible-playbook -i ansible/inventory/dev
ansible/playbooks/site.yml*

![](https://github.com/osygroup/Images/blob/main/Ansible-Dynamic/image12.png)

Note: The servers that shoe 'unreachable=0' are the servers that were
not needed for this project. They were switched off.

Head over to a web browser and type in the domain name that was
registered to the load balancer to view the tooling website:

![](https://github.com/osygroup/Images/blob/main/Ansible-Dynamic/image13.png)

Login using the default details (username: admin, password: admin).

![](https://github.com/osygroup/Images/blob/main/Ansible-Dynamic/image14.png)

If the tooling website is not logging in with the default details,
restart all the servers created for this project and attempt to login
again.

Navigate into the ansible directory and add all the created files in
this project to update the new local branch created (named *dynamic*):

*\$ sudo git add .*

Commit the added files:

*\$ sudo git commit -m \"leave_a\_comment_here\"*

Push this new branch to Github:

*\$ sudo git push -u origin dynamic*

In case this error is encountered when running the playbook "the output
has been hidden due to the fact that 'no_log': true was specified for
this result":

![](https://github.com/osygroup/Images/blob/main/Ansible-Dynamic/image15.jpeg)

Change *no_log: true* to *false* in the *tasks/users.yml* file of the
MySQL role:

![](https://github.com/osygroup/Images/blob/main/Ansible-Dynamic/image16.jpeg)

## Conclusion

Included roles and tasks are similar to handlers - they may or may not
run, depending on the results of other tasks in the top-level playbook.

The primary advantage of using *include\_\** statements is looping. When
a loop is used with an *include*, the included tasks or role will be
executed once for each item in the loop.

Take note that in most cases it is recommended to use static assignments
for playbooks, because it is more reliable. With dynamic assignments, it
is hard to debug playbook problems due to its dynamic nature. However,
dynamic assignments can be used for environment-specific variables.

## Credits

<https://docs.ansible.com/ansible/latest/user_guide/playbooks_reuse.html#playbooks-reuse>

<https://docs.ansible.com/ansible/latest/collections/ansible/builtin/include_role_module.html#include-role-module>

<https://docs.ansible.com/ansible/latest/collections/ansible/builtin/include_vars_module.html#include-vars-module>

<https://docs.ansible.com/ansible/latest/collections/ansible/builtin/apt_module.html>

<https://severalnines.com/database-blog/introduction-mysql-deployment-using-ansible-role>

<https://docs.ansible.com/ansible/latest/collections/community/mysql/mysql_user_module.html>

<https://docs.ansible.com/ansible/latest/collections/ansible/builtin/file_module.html>

<https://linuxbuz.com/linuxhowto/install-letsencrypt-ssl-ansible>

<https://serverfault.com/questions/997617/ansible-gives-me-an-error-during-execution-of-some-playbooks>

<https://www.digitalocean.com/community/tutorials/how-to-install-nginx-on-ubuntu-18-04>

<https://stackoverflow.com/questions/49172841/how-to-install-certbot-lets-encrypt-without-interaction>

<https://docs.ansible.com/ansible/2.8/modules/mysql_db_module.html>

<https://www.iaspnetcore.com/blog/blogpost/5d9865cc72c1772b244afe0f>

<https://docs.ansible.com/ansible/latest/user_guide/playbooks_reuse.html#playbooks-reuse>

<https://docs.ansible.com/ansible/latest/collections/ansible/builtin/include_vars_module.html#include-vars-module>

<https://ansible-project.narkive.com/CLb9jRRm/mysql-db-state-import-only-once>

<https://askubuntu.com/a/398850>
