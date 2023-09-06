#!/bin/bash

#!/bin/bash

# Update package lists
sudo apt-get update 

sudo apt install -y python3 python3-pip
pip install flask 
pip install psycopg2-binary
 

sudo apt install git -y  
git clone https://github.com/omriyan01/terraform-fastapi-.git
sudo python3 /var/lib/waagent/custom-script/download/0/terraform-fastapi-/connect.py
