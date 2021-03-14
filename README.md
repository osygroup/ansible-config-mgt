# Project 4: Bastion & Ansible Configuration Management

A Bastion host/server is an intermediary server through which access to
internal network can be achieved. A bastion host is a server whose
purpose is to provide access to a private network from an external
network, such as the Internet. Because of its exposure to potential
attack, a bastion host must minimize the chances of penetration. For
example, you can use a bastion host to mitigate the risk of allowing SSH
connections from an external network to the Linux instances launched in
a private subnet of a virtual network or private cloud.

Ansible is an open-source automation tool, or platform, used for IT
tasks such as configuration management, application deployment,
intraservice orchestration, and provisioning. Automation is crucial
these days, with IT environments that are too complex and often need to
scale too quickly for system administrators and developers to keep up if
they had to do everything manually. Automation simplifies complex tasks,
not just making developers' jobs more manageable but allowing them to
focus attention on other tasks that add value to an organization. In
other words, it frees up time and increases efficiency. And Ansible is
rapidly rising to the top in the world of automation tools.

In this project, we will create a Bastion server to run Ansible scripts
on the servers in the Tooling Website architecture.

## Prerequisite
Completion of Load-Balancer-Solution-with-Nginx-and-SSL-TLS (Project 3)

## Step 1 - Create a GitHub repository

Create a new GitHub repository named *ansible-config-mgt*. In the
repository, create a branch named *feature-001*:

![](https://github.com/osygroup/Images/blob/main/Bastion-Ansible-Demo/image1.jpeg)

## Step 2 - Prepare a Jump/Bastion server to act as Ansible Client

Create an Ubuntu 20.04 LTS server and call it Bastion. It will serve as
a client to run ansible scripts.

On the bastion server install Ansible:

*\$ sudo apt update*

*\$ sudo apt install ansible*

Check Ansible version:

*\$ ansible --version*

![](https://github.com/osygroup/Images/blob/main/Bastion-Ansible-Demo/image2.jpeg)

Create a folder named *ansible*:

*\$ sudo mkdir ansible*

For VS Code to edit files in the Ansible directory,

*\$ sudo chown -R azureuser: ansible*

Create a directory named *playbooks*. This will be used to store all the
playbook files:

*\$ sudo mkdir ansible/playbooks*

Create a directory named *inventory*. This will be used to keep the host
servers organized:

*\$ sudo mkdir ansible/inventory*

Within the *playbooks* folder, create a playbook, and name it
*common.yml*

*\$ sudo touch ansible/playbooks/common.yml*

Within the inventory folder, create an inventory file for each
environment (Development, Staging, Testing and Production) *dev*,
*staging*, *uat*, and *prod* respectively.

*\$ sudo touch ansible/inventory/dev*

*\$ sudo touch ansible/inventory/staging*

*\$ sudo touch ansible/inventory/uat*

*\$ sudo touch ansible/inventory/prod*

Open the *dev* file with an editor and place the below inventory
structure file to start configuring the development servers (ensure to
replace the IP addresses according to your own setup):

\[nfs\]

10.0.0.4

\[webservers\]

10.0.0.6

10.0.0.7

10.0.0.8

\[db\]

10.0.0.5

\[jenkins\]

10.0.0.9

\[lb\]

10.0.0.11

The above inventory structure will work if the username of the nodes
(servers) in the inventory are the same as the username of the Ansible
host (Bastion server). Ansible would attempt to connect to the servers
using the Bastion server\'s username.

Attach the username of the server if it is a different name from the
Bastion server's name. The IP entry for a server with a different
username will look like:

10.0.0.11 ansible_user=\<username\>

For example:

10.0.0.11 ansible_user=ubuntu

Also, the above inventory structure will work if all the servers in the
inventory use the same *.ssh/id_rsa* SSH private key in the Bastion
server. Ansible would attempt to connect to the remote servers using the
*id_rsa* private key in its *.ssh* folder.

Attach the name of the private SSH key of the server (including its file
path) if it has a different key from the *id_rsa* key in the Bastion
server. The IP entry for a server with a different private SSH key will
look like:

10.0.0.9 ansible_ssh_private_key_file=/*file_path*/\<*private_key*\>

For example:

10.0.0.9 ansible_ssh_private_key_file=\~/.ssh/privatekey

If a server has a different username from the Bastion server and a
different SSH private key from the *id_rsa* key in the Bastion server,
the IP entry for that server will look like:

10.0.0.6 ansible_user=myuser
ansible_ssh_private_key_file=\~/.ssh/myprivatekey

Change the file permission of the private key(s) to be used to connect
to the servers from the Ansible host to limit access:

*\$ sudo chmod 400 \~/.ssh/id_rsa*

Disable Authenticity of host (Host key checking) in
/etc/ansible/ansible.cfg. Type in a new line:

*host_key_checking = False*

Or scroll down the config file and uncomment the line
*\#host_key_checking = False*

![](https://github.com/osygroup/Images/blob/main/Bastion-Ansible-Demo/image3.jpeg)

Test connection to the servers in the development servers in the *dev*
file with a 'ping' test that returns 'pong' if successful:

\$ ansible all -i ansible/inventory/dev -m ping

![](https://github.com/osygroup/Images/blob/main/Bastion-Ansible-Demo/image4.jpeg)

## Step 3 -- Test Ansible with a Playbook

Open the Ansible playbook *common.yml* with a text editor:

*\$ sudo nano ansible/playbooks/common.yml*

Below is a playbook to install *git* in all the servers in the *dev*
inventory file. Copy and insert it into the *common.yml* file.

*\-\--*

*- name: test*

*hosts: all*

*become: true*

*tasks:*

*- name: install git*

*package:*

*name: git*

*state: latest*

Save the playbook and install *git* in all the servers:

*\$* *ansible-playbook -i ansible/inventory/dev
ansible/playbooks/common.yml*

![](https://github.com/osygroup/Images/blob/main/Bastion-Ansible-Demo/image5.jpeg)

![](https://github.com/osygroup/Images/blob/main/Bastion-Ansible-Demo/image6.jpeg)

![](https://github.com/osygroup/Images/blob/main/Bastion-Ansible-Demo/image7.jpeg)

As seen in the first screenshot, Ansible 2.5 and above work with Python
3. Ansible will automatically detect and use Python 3 on many platforms
that ship with it. Set the python version to python3 on any server with
python deprecation warning.

In the last screenshot, \'changed=0\' in the PLAY RECAP for a server
means that the module to be installed in the task (*git*) is already
installed and therefore there was no changes made, while \'changed=1\'
in the PLAY RECAP for a server means that the *git* module in the task
was successfully installed.

To connect Visual Studio Code to the Bastion server for creating and
editing playbooks and inventories, follow the instructions in this
[documentation](https://code.visualstudio.com/docs/remote/ssh).

## Step 4 - Push Ansible files to GitHub repository

Install Git in the Bastion server:

*\$ sudo apt install git*

Change directory into the *ansible* directory and start a local git
repository:

*\$ cd ansible && sudo git init*

Add the *inventory* and *playbook* directories to the repository

*\$ sudo git add inventory*

*\$ sudo git add playbooks*

Commit the added repositories

*\$ sudo git commit -m \"first commit\"*

Rename the \"master\" branch in the local Git repository to "main":

*\$ sudo git branch -m main*

Create a new branch *feature-001* (same name with the branch created in
the GitHub repository) and checkout into it:

*\$ sudo git checkout -b feature-001*

Files can be created in the *ansible* directory and changes can be made
to files in *inventory* and *playbooks* directories. To check for
changes to add and commit in the current branch (*feature-001*), run:

*\$ sudo git status*

If there are files in red colour, they are yet to be added to the
branch. If there are files in green colour, they are yet to be
committed. Add the necessary files/folders and commit them.

*\$ sudo git add \<file\>*

*\$ sudo git commit -m \"comment here\"*

Confirm if there is anything left to add and commit:

*\$ sudo git status*

To view the files in the branch:

*\$ git ls-tree -r \--name-only feature-001*

Add a remote repository (in this case, the repository created in
GitHub):

*\$ sudo git remote add origin
https://github.com/osygroup/ansible-config-mgt.git*

Push the local *feature-001* branch to the remote *feature-001* branch:

*\$ sudo git push -u origin feature-001*

![](https://github.com/osygroup/Images/blob/main/Bastion-Ansible-Demo/image8.jpeg)

![](https://github.com/osygroup/Images/blob/main/Bastion-Ansible-Demo/image9.jpeg)

In case there are issues with pushing to the remote GitHub branch, pull
first from the remote branch, then push back to the remote branch.

To pull from GitHub:

*\$ git pull \<remote\> \<branch\>*

Or:

*\$ git pull \<remote\> \<branch\> \--rebase*

For example:

*\$ sudo git pull https://github.com/osygroup/ansible-config-mgt
feature-001 \--rebase*

## Step 5 -- Create Pull Request (PR)

Pull requests let you tell others about changes you\'ve pushed to a
branch in a repository on GitHub. Once a pull request is opened, you can
discuss and review the potential changes with collaborators and add
follow-up commits before your changes are merged into the base (*main*)
branch.

After successfully pushing to the GitHub *feature-001* branch, create a
pull request to merge the f*eature-001* branch to the *main* branch:

![](https://github.com/osygroup/Images/blob/main/Bastion-Ansible-Demo/image10.jpeg)

You can add a comment to the pull request before creating it.

![](https://github.com/osygroup/Images/blob/main/Bastion-Ansible-Demo/image11.png)

Act as a reviewer and review the pull request of the new feature
development.

![](https://github.com/osygroup/Images/blob/main/Bastion-Ansible-Demo/image12.jpeg)

Merge the code to the *main* branch and close the pull request:

![](https://github.com/osygroup/Images/blob/main/Bastion-Ansible-Demo/image13.jpeg)

![](https://github.com/osygroup/Images/blob/main/Bastion-Ansible-Demo/image14.jpeg)

![](https://github.com/osygroup/Images/blob/main/Bastion-Ansible-Demo/image15.jpeg)

Back to the Bastion server, switch to the local *main* branch:

*\$ sudo git checkout main*

Pull the remote *main* branch into the local *main* branch

*\$ sudo git pull https://github.com/osygroup/ansible-config-mgt main*

![](https://github.com/osygroup/Images/blob/main/Bastion-Ansible-Demo/image16.jpeg)

To view the files in the branch:

*\$ sudo git ls-tree -r \--name-only main*

![](https://github.com/osygroup/Images/blob/main/Bastion-Ansible-Demo/image17.png)

## Conclusion

A bastion host is a standard element of network security that provides
secure access to private networks over SSH.

Some of the advantages of Ansible are:

-   Dead-simple setup process with a minimal learning curve.

-   Manage machines very quickly and in parallel.

-   Avoid custom-agents and additional open ports, be agentless by
    leveraging the existing SSH daemon.

-   Describes infrastructure in a language that is both machine and
    human friendly.

-   Focus on security and easy auditability/review/rewriting of content.

-   Manage new remote machines instantly, without bootstrapping any
    software.

-   Allows module development in any dynamic language, not just Python.

-   Usable as non-root.

## Credits

<https://stackoverflow.com/questions/32297456/how-to-ignore-ansible-ssh-authenticity-checking>

<https://requestmetrics.com/building/episode-3_5-basic-ansible-with-ssh-keys>

<https://zepel.io/blog/how-to-merge-branches-in-github/>

<https://aws.amazon.com/blogs/security/how-to-record-ssh-sessions-established-through-a-bastion-host/>

<https://www.simplilearn.com/tutorials/ansible-tutorial/what-is-ansible>

<https://github.com/ansible/ansible>
