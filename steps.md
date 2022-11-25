##### 

March 17, 2018

Samba – Set up CIFS Server on RHEL/CentOS 7
===========================================

If you have directories on your machine that you want to share out to other machines then you can do this by [setting up your machine as an NFS server](http://sherc.sg-host.com/tutorials/rhce/nfs-set-up-an-nfs-server-on-centos-rhel-7). However with NFS you can only share out folders to machine that are also in the same private network. If you want share folders to other machines over the public internet, then that’s where you need to use the Samba/CIFS protocol. You can follow along this article using this [Samba vagrant project on Github](https://github.com/Sher-Chowdhury/CentOS7-Samba-demo).


Walking through the following example:

+--------------------------+              +--------------------------+
|                          |              |                          |
|      samba-storage       |              |       samba-client       |
|     (IP: 10.0.4.10)      |              |                          |
|                          |              |                          |
|                          |              |                          |
|                          |              |                          |
|  +------------------+    |              |     +---------------+    |
|  | /samba/export\_rw |<----------------------->| /mnt/backups  |    |
|  +------------------+    |              |     +---------------+    |
|                          |              |                          |
|                          |              |                          |
+--------------------------+              +--------------------------+

This article only covers setting up the samba server (which in this example is called samba-storage). We created a separate article on [how to set up a samba client](https://sherc.sg-host.com/tutorials/rhce/samba-how-to-set-up-a-samba-client-on-centos-rhel-7-2).

First you need to install:

$ yum install samba samba-client

For SELinux, we need to enable a few SEBoolean settings:

$ getsebool -a | grep samba | grep export
samba\_export\_all\_ro --> off
samba\_export\_all\_rw --> off
$ getsebool -a | grep samba | grep share | grep nfs
samba\_share\_nfs --> off

To (p)ersistantly enable these settings we do:

$ setsebool -P samba\_export\_all\_ro on
$ setsebool -P samba\_export\_all\_rw on
$ setsebool -P samba\_share\_nfs on

Next we create a folder that will get shared out (aka exported):

$ mkdir -p /samba/export\_rw
$ ll -dZ /samba/export\_rw
drwx**r-x**r-x. **root root** unconfined\_u:object\_r:**default\_t**:s0 /samba/export\_rw

There’s a few things we need to fix for this folder:

1.  need to change the owner and group owner
2.  need to give full permissions to the group
3.  SELinux type attribute needs to be set to samba\_share\_t

Let’s create a new user which will access this samba share:

$ useradd samba\_user1

Next we give this owner of this folder:

chown samba\_user1:samba\_user1 /samba/export\_rw

Next the SELinux type attribute needs to be set to **samba\_share\_t**, so in our case we do:

$ semanage fcontext -at samba\_share\_t "/samba/export\_rw(/.\*)?"

Then apply this new rule to our export:

$ restorecon -R /samba/export\_rw
$ ll -dZ /samba/export\_rw
drwxrwxr-x. samba\_user1 samba\_user1 unconfined\_u:object\_r:samba\_share\_t:s0 /samba/export\_rw

Next we need allow samba traffic through firewalld:

$ firewall-cmd --permanent --add-service=samba
$ systemctl restart firewalld

Next we need to configure the main samba config file, `/etc/samba/smb.conf`. To help with understanding how to configure this file, you should take a look at:

$ cat /etc/samba/smb.conf.example   
# also see:
$ man smb.conf    # this is a really long man page!

Before we start editing this file, let’s first create a backup:

$ cp /etc/samba/smb.conf /etc/samba/smb.conf.orig

There’s two things we need to do in this file, first we edit the global section so it contains the following entries:

\[global\]
        workgroup = SAMBA
        **security = user
        server string = Samba server %h
        hosts allow = 127. 10.0.4.
        interfaces = lo enp0s3 enp0s8
        passdb backend = smbpasswd:/etc/samba/smbpasswd.txt**
        printing = cups
        printcap name = cups
        load printers = yes
        cups options = raw

At the very end of your `/etc/samba/smb.conf`, we need to add a section for our exported folder:

\[bckp\_storage\]
  comment = Folder for storing backups
  read only = no
  available = yes
  path = /samba/export\_rw
  public = yes
  valid users = samba\_user1
  write list = samba\_user1
  writable = yes
  browseable = yes

Descriptions for these settings are given in the man page for smb.conf. These are pretty much self explanatory, but you can find more info in the smb.conf man page. Note, in the man page all the parameters are labelled as either (G)lobal or (S)hares depending on which section they are allowed to be used in.

Next you can run the following to do a quick configtest:

$ testparm
Load smb config files from /etc/samba/smb.conf
rlimit\_max: increasing rlimit\_max (1024) to minimum Windows limit (16384)
Processing section "\[homes\]"
Processing section "\[printers\]"
Processing section "\[print$\]"
Processing section "\[bckp\_storage\]"
Loaded services file OK.
Server role: ROLE\_STANDALONE

Next we need to (a)dd our user to the samba user database and give it a samba specific password. We do this by running:

$ smbpasswd -a samba\_user1
New SMB password:
Retype new SMB password:
startsmbfilepwent\_internal: file /etc/samba/smbpasswd.txt did not exist. File successfully created.
Added user samba\_user1.

Note, smbpasswd command only works for existing machine level user accounts. If the OS level user doesn’t exist then you get a ‘Failed to add entry for user xxxxxx’ error message. Also this machine level user only needs to exist on the Samba server itself, and not the Samba client.

To confirm this user now exists in the samba database, you can run the following command to (v)erbosely (L)ist all users:

$ pdbedit -Lv
---------------
Unix username:        samba\_user1
NT username:
Account Flags:        \[U          \]
User SID:             S-1-5-21-1438882573-2886693097-939080548-3004
Primary Group SID:    S-1-5-21-1438882573-2886693097-939080548-513
Full Name:
Home Directory:       \\\\samba-storage\\samba\_user1
HomeDir Drive:
Logon Script:
Profile Path:         \\\\samba-storage\\samba\_user1\\profile
Domain:               SAMBA-STORAGE
Account desc:
Workstations:
Munged dial:
Logon time:           0
Logoff time:          never
Kickoff time:         never
Password last set:    Sat, 17 Mar 2018 12:20:58 UTC
Password can change:  Sat, 17 Mar 2018 12:20:58 UTC
Password must change: never
Last bad password   : 0
Bad password count  : 0
Logon hours         : FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF

Now we can go ahead and start the samba daemon:

$ systemctl enable smb
ln -s '/usr/lib/systemd/system/smb.service' '/etc/systemd/system/multi-user.target.wants/smb.service'
$ systemctl start smb      

Now you can locally test whether your new export is now available:

\[root@samba-storage samba\]# smbclient -L //localhost -U samba\_user1
Enter SAMBA\\samba\_user1's password:
Domain=\[SAMBA-STORAGE\] OS=\[Windows 6.1\] Server=\[Samba 4.6.2\]

	Sharename       Type      Comment
	---------       ----      -------
	print$          Disk      Printer Drivers
	**bckp\_storage    Disk      Folder for storing backups**
	IPC$            IPC       IPC Service (Samba server samba-storage)
	samba\_user1     Disk      Home Directories
Domain=\[SAMBA-STORAGE\] OS=\[Windows 6.1\] Server=\[Samba 4.6.2\]

	Server               Comment
	---------            -------

	Workgroup            Master
	---------            -------

This shows that the Samba share ‘bckp\_storage’ is now ready to be shared out. The next thing to do is to [set up a Samba Client to access this share](http://sherc.sg-host.com/tutorials/rhcsa/samba-how-to-set-up-a-samba-client-on-centos-rhel-7).

Summary
-------

There’s a lot of steps involved in setting up a samba server. So let’s summarise all these steps:

01\. install rpms  
02\. enable 3 sebool settings.  
03\. create the Linux user that will access the samba share.  
04\. create folder to share  
05\. change folders ownership to samba user  
06\. change folder chmod perms  
07\. update selinux file context for the folder  
08\. update the main samba config file – global settings a  
09\. update the main samba config file – by adding new stanza  
10\. do config test of updated samba config file.  
11\. create samba password for the samba user.  
12\. check samba password database to confirm the samba user now exists.  
13\. update firewall  
14\. start and enable the samba daemon.  
15\. Check if samba share is now available.

\[post-content post\_name=rhsca-quiz\]

In this quiz, we’ll assume the folder we want to share is /samba/export\_rw.  

  

What are the steps to setting up the samba server?

  
01\. install rpms  
02\. enable 3 sebool settings.  
03\. create the Linux user that will access the samba share.  
04\. create folder to share  
05\. change folders ownership to samba user  
06\. change folder chmod perms  
07\. update selinux file context for the folder  
08\. update the main samba config file – global settings a  
09\. update the main samba config file – by adding new stanza  
10\. do config test of updated samba config file.  
11\. create samba password for the samba user.  
12\. check samba password database to confirm the samba user now exists.  
13\. update firewall  
14\. start and enable the samba daemon.  
15\. Check if samba share is now available.  

  

What rpms do you need to install?

  
$ yum install samba samba-client  

  

What SE booleans do you need to set?

  
$ setsebool -P samba\_export\_all\_ro on  
$ setsebool -P samba\_export\_all\_rw on  
$ setsebool -P samba\_share\_nfs on  

  

What is the command to create the samba user samba\_user1?

  
$ useradd samba\_user1  

  

What tasks needs to be done in order for /samba/export\_rw folder to be exported?

  
– need to change ownership so that the samba user owns and groups owns this folder.  
– need to change ugo permissions  
– need to apply the correct SELinux settings  

  

What are the commands to achieve these settings?

  
$ semanage fcontext -at samba\_share\_t “/samba/export\_rw(/.\*)?”  
$ restorecon -Rv /samba/export\_rw  
$ chown samba\_user1:samba\_user1 /samba/export\_rw  
$ chmod 775 /samba/export\_rw  

  

What settings needs to exist under the global section of /etc/samba/smb.conf?

  
– security = user  
– server string = samba server %h  
– hosts allow = 127. 192.10.10  
– interfaces = lo enp0s8  
– passdb backend = smbpasswd:/etc/samba/smbpasswd.txt  

  

What additional stanza needs to created for our share?

  
\[meaningful\_name\]  
– comment = this is a samba share  
– read only = no  
– available = yes  
– path = /samba/export\_rw  
– public = yes  
– valid users = samba\_user1  
– writable = yes  
– write list = samba\_user1  
– browsable = yes  

  

What is the command to do a config test?

  
$ testparm  

  

What is the command to create samba password for the samba\_user?

  
$ smbpasswd -a samba\_user1  
\# this ends up creating the file that’s defined in the smb.conf  

  

What is the command to check whether this user is now registered in the smbpasswd database?

  
$ pdbedit -Lv  

What firewalls needs to be opened?

  
$ firewall-cmd –permanent –add-service=samba  
$ systemctl restart firewalld  

Now what is the command to start and enable the samba service?

  
$ systemctl status smb  
$ systemctl start smb  

  

What is the command to do a quick sanity check to see if our Samba share is now available?

  
$ smbclient -L //localhost -U samba\_user1  
\# you will get prompted to enter the smbpasswd.  

  

March 17, 2018 [sher](https://codingbee.net/author/sher "View all posts by sher") [RHCE](https://codingbee.net/category/rhce "View all posts in RHCE") [CIFS](https://codingbee.net/tag/cifs "View all posts tagged CIFS"), [Samba](https://codingbee.net/tag/samba "View all posts tagged Samba")
