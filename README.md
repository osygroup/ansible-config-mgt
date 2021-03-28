# Project 5: Ansible Refactoring & Static Assignments (Imports)

Refactoring is a general term in software programming. It means making
changes to the source code without any change to the external behaviour
of the solution.

In Ansible, using roles is the best way to refactor source codes or
artifacts. Similar tasks that are done very often e.g. managing user
accounts, installing and configuring a web server or database can be
abstracted into Ansible roles. This means a set of tasks can be
maintained to be used among many playbooks, with variables to give
flexibility where needed.

In this project, we will create a new virtual machine to be used as a
webserver to illustrate using Ansible to deploy a webserver for the
tooling application.

### Prerequisite

Completion of Bastion Host & Ansible Configuration Management (Project 4)

### Step 1 - Create a new webserver and pull Ansible files from GitHub
repository

Create a new RHEL 8 virtual machine in the same virtual network as the
other servers in the architecture and add its private IP address to the
*inventory/dev* list in the Ansible host:

![](https://github.com/osygroup/Images/blob/main/Ansible-Refactoring/image1.png)

Pull down the latest code from master/main branch, and create a new
branch (named something like *refactor*)

Move into the git repository and check the branch that is currently
selected

*\$ sudo git branch*

![](https://github.com/osygroup/Images/blob/main/Ansible-Refactoring/image2.png)

Pull the remote main branch into the local main branch

*\$ sudo git pull remote main*

![](https://github.com/osygroup/Images/blob/main/Ansible-Refactoring/image3.png)

Create a new branch named *refactor* and switch to it immediately:

*\$ sudo git checkout -b refactor*

![](https://github.com/osygroup/Images/blob/main/Ansible-Refactoring/image4.png)

A new branch is created with the contents of the master/main branch.
View the contents of the *refactor* branch.

*\$ sudo git ls-tree -r \--name-only refactor*

![](https://github.com/osygroup/Images/blob/main/Ansible-Refactoring/image5.png)

Within the *playbook* folder, create a new file and name it *site.yml* -
This will now be considered as the entry point into the entire
infrastructure configuration. Other playbooks will be included here as a
reference. In other words, *site.yml* will become a parent to all other
playbooks that will be developed, including *common.yml* that was
created previously.

Create a new folder and name it *static-assignments*. This folder is
where all other dynamic playbooks will be stored. This is merely for
easy organization of work. It is not an Ansible specific concept.

Move the *common.yml* file into the newly created *static-assignments*
folder.

Edit the *hosts* field to:

*hosts: \"{{ hostlist }}\"*

![](https://github.com/osygroup/Images/blob/main/Ansible-Refactoring/image6.png)

Within the *site.yml* file, import the *common.yml* playbook.

Edit the *site.yml* file with a text editor and paste the following
inside:

*\-\--*

*- name: Install Git*

*import_playbook: ../static-assignments/common.yml
hostlist=webserver-ansible*

![](https://github.com/osygroup/Images/blob/main/Ansible-Refactoring/image7.png)

The '*hostlist=webserver-ansible*' will ensure that the *site.yml*
playbook will run the *common.*yml playbook only on the new
webserver-ansible virtual machine. To run the playbook on all the
servers, '*hostlist=all*'.

### Step 2 -- Create and Configure Roles

The tasks to configure the webserver can be written within another
playbook, but that will make reusing the playbook difficult. A dedicated
role is needed to organize Ansible neatly.

To create a role, first, create a directory named *roles* in the parent
*ansible* folder. Roles have specific folder structure which can be
manually created. But, rather than doing the hard work, there is a
smarter way to do that by using an ansible utility called
*ansible-galaxy*. Run the code below within the *roles* folder just
created.

*\$ sudo ansible-galaxy init webserver*

This will create all the folders and files needed to develop a role. The
entire folder structure should look like this:

![](https://github.com/osygroup/Images/blob/main/Ansible-Refactoring/image8.png)

Most of the files and folders are not required yet, so remove *tests*,
*files*, and *vars*. The folder structure should now look like this:

![](https://github.com/osygroup/Images/blob/main/Ansible-Refactoring/image9.png)

Go into *defaults* directory, and within the *main.yml* file, create
some variables so that this role can be easily reusable. Copy and paste
the following variables into the *main.yml* file:

*\#configuration file name*

*ap_http_conf_file: \"tooling.conf\"*

*\#port for webserver*

*ap_http_port: 80*

*\#location of app folder to be deployed (it is on the Ansible host)*

*ap_source_code_location: \"/home/azureuser/tooling/html\"*

![](https://github.com/osygroup/Images/blob/main/Ansible-Refactoring/image10.png)

Go into *templates* directory and create a config file to configure a
new virtual host for the tooling app. The config file will be saved as a
Jinja 2 template file e.g. *tooling.conf.j2*. Copy the below
configuration into the *.conf.j2* file created.

*\<VirtualHost \*:{{ap_http_port}}\>*

*DocumentRoot /var/www/html*

*\</VirtualHost\>*

![](https://github.com/osygroup/Images/blob/main/Ansible-Refactoring/image11.png)

Go into *tasks* directory, and within the *main.yml* file, start writing
the configuration to install Apache server and deploy the tooling app's
html folder into the webserver's */var/www* directory.

Copy and paste the following into the *main.yml* file:

*- name: Install apache*

*package:*

*name: httpd*

*state: present*

*- name: create /var/www folder if it does not exist*

*file:*

*path: /var/www*

*state: directory*

*mode: \'0755\'*

*- name: Copy source code/artifacts*

*copy:*

*src: \"{{ ap_source_code_location }}\"*

*dest: /var/www/*

*- name: Set up Apache VirtualHost*

*template:*

*src: \"tooling.conf.j2\"*

*dest: \"/etc/httpd/conf.d/{{ ap_http_conf_file }}\"*

*- name: Enable Httpd*

*service:*

*name: \"httpd\"*

*enabled: yes*

*- name: Start Httpd*

*service:*

*name: \"httpd\"*

*state: started*

*- name: Stop firewall*

*shell: systemctl stop firewalld*

*- name: Disable firewall*

*shell: systemctl disable firewalld*

*- name: Mask firewall*

*shell: sudo systemctl mask \--now firewalld*

Create another role in the *roles* folder for installing PHP and all the
necessary modules.

*\$ sudo ansible-galaxy init php-rhel*

Only the *tasks* directory will be configured for this role. Edit its
*main.yml* file and add the following PHP 8.0 installation
configuration.

*- name: Install PHP 8.0 in RHEL*

*shell: dnf install -y
https://dl.fedoraproject.org/pub/epel/epel-release-latest-8.noarch.rpm*

*- name: Step 2*

*shell: dnf install -y
http://rpms.remirepo.net/enterprise/remi-release-8.rpm*

*- name: Step 3*

*shell: dnf module reset php*

*- name: Step 4*

*shell: dnf module install -y php:remi-8.0*

*- name: Step 5*

*shell: dnf install -y
php-{mysqlnd,xml,xmlrpc,curl,gd,imagick,mbstring,opcache,soap,zip}*

*- name: Restart Httpd*

*shell: systemctl restart httpd*

Ansible uses a configuration file to customize settings. The file is
*ansible.cfg* file. It can be located anywhere, but it must be exported
as an environmental variable to let Ansible know where to find this
file.

Create a new file in the *roles* directory and name it *ansible.cfg* and
update it with the below content, specifying the full path to the roles.
If this is not done, any role you download through galaxy will be
installed in the default settings which could either be in
/etc/ansible/ansible.cfg or \~/.ansible.cfg

*\[defaults\]*

*timeout = 160*

*roles_path = \<FULL PATH TO ANSIBLE ROLES\>*

*callback_whitelist = profile_tasks*

*log_path=\~/ansible.log*

*host_key_checking = False*

*gathering = smart*

*\[ssh_connection\]*

*ssh_args = -o ControlMaster=auto -o ControlPersist=30m -o
ControlPath=/tmp/ansible-ssh-%h-%p-%r -o ServerAliveInterval=60 -o
ServerAliveCountMax=60*

*\[privilege_escalation\]*

*become=True*

![](https://github.com/osygroup/Images/blob/main/Ansible-Refactoring/image12.png)

Run the export command on the terminal to let Ansible know where to find
the configuration file.

*\$ export ANSIBLE_CONFIG=\<full_path_to_ansible.cfg_file\>*

Once this is exported, all the roles will be activated.

Now check if the two roles were activated and are ready to be used.

*\$ ansible-galaxy role list*

![](https://github.com/osygroup/Images/blob/main/Ansible-Refactoring/image13.png)

Navigate back to the *static-assignments* directory and create a new
playbook for the webserver role named *webservers.yml*. This is where
the webserver role will be referenced.

*\-\--*

*- name: set up tooling webserver*

*hosts: \"{{ hostlist }}\"*

*roles:*

*- webserver*

*become: true*

Also create a new playbook for the php-rhel role named *php-rhel.yml*.

*\-\--*

*- name: set up tooling webserver*

*hosts: \"{{ hostlist }}\"*

*roles:*

*- php-rhel*

*become: true*

Since the roles will be run on a new RHEL virtual machine, create a
playbook for updating the virtual machine and disabling SELinux.

Add the below tasks into the playbook named *update.yml*:

*\-\--*

*- name: Update server and disable SELinux*

*hosts: \"{{ hostlist }}\"*

*become: true*

*tasks:*

*- name: Update server*

*package:*

*name: \'\*\'*

*state: latest*

*update_only: yes*

*- name: disable SELinux*

*shell: setenforce 0*

*- name: setsebool for NFS*

*shell: setsebool -P httpd_use_nfs=1*

Remember that the entry point to the Ansible configuration is the
*site.yml* file in the *playbooks* directory. Without updating the entry
point, all the playbooks in the *static-assignments* directory will not
be used.

The updated *site.yml* file would look like this:

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

Now run the playbook from the root of the Ansible directory:

*\$* *ansible-playbook -i ansible/inventory/dev
ansible/playbooks/site.yml*

![](https://github.com/osygroup/Images/blob/main/Ansible-Refactoring/image14.png)

Curl the private IP address of the webserver to confirm that the tooling
website was deployed:

![](https://github.com/osygroup/Images/blob/main/Ansible-Refactoring/image15.png)

Head over to a web browser and type in the public IP address of the
webserver to view the tooling website:

![](https://github.com/osygroup/Images/blob/main/Ansible-Refactoring/image16.png)

### Conclusion

Ansible refactoring allows us to hide complexity and to provide defined
interfaces. It also increases the ability to work in parallel on
different parts of your Infrastructure as Code (IaC) project.

### Credits

<https://medium.com/faun/ansible-write-ansible-role-to-configure-apache-webserver-9c08aaf66528>

<https://docs.ansible.com/ansible/latest/collections/ansible/builtin/copy_module.html>

<https://www.mydailytutorials.com/how-to-copy-files-and-directories-in-ansible-using-copy-and-fetch-modules/>

<https://stackoverflow.com/questions/62392584/ansible-to-check-particular-directory-exists-if-not-create-it>

<https://stackoverflow.com/a/63668940>

<https://docs.ansible.com/ansible/latest/collections/ansible/builtin/yum_module.html>

<https://docs.ansible.com/ansible/2.5/modules/yum_module.html>

<https://serverfault.com/a/1051530>

<https://blog.programster.org/ansible-update-and-reboot-if-required-amazon-linux-servers>

<https://www.educba.com/ansible-yum-module/>

<https://opensource.com/article/20/1/ansible-playbooks-lessons>
