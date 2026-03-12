&nbsp;					**\***Ansible works on the **Control Node (Ansible Node)** and **Managed Node (Target Nodes)** Model**\***



**Day-1**

**Password less Authentication** - ASetup Password less Authentication - ssh-copy-id -f "-o IdentifyFile <PATH to .PEM FILE> ubuntu@pubicIP.



**Day-2**

**Ansible inventory -** Where we defined the Details of the Managed Nodes, Like Username and the IP address.

&nbsp;		    We have file call **Inventory.ini File**, We just need to edit the **Inventory.ini File**, with Username and IP Address ubuntu@pubicIP.

&nbsp;		    **Inventory is the heart of the Ansible**, Because it will tell the ansible Control Node which server it has to talk (Managed Node).

&nbsp;		    As per the Project user can **create multiple Inventory.ini file** and pass to the ansible execution.

&nbsp;		    If we want to perform the task on the group of the server, we can do that with the grouping \[App] \[DB].



**Adhoc Commands -** In ansible 2 ways of providing the instructions 1st, **is with Ansible playbooks (yaml)**. 2nd, **Adhoc Commands.**

&nbsp;		 Playbooks are reusable, and Adhoc commands we use for the simple task Ex. Check Network or some small Troubleshooting task.

&nbsp;		 Syntax - ansible \[inventory file ] -m \[shell] -a \[Tareget server].	-m = Modules.

&nbsp;		 #Need to check the Adhoc Commands for the day to day use. Ex. Shell Module, 



**Day-3**

**YAML -**  Human readable data serialization file.

&nbsp;

**Ansible Playbooks** - Combination of plays, list of play Ex, Install DB or Install APP. 

&nbsp;		    Its a YAML file, 

&nbsp;		    Host:	Remote\_user:	Task:

&nbsp;	



&nbsp;		   

&nbsp;		    

&nbsp;		

&nbsp;		    

