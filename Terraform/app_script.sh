#!/bin/bash

# Install necessary packages
sudo apt-get update
apt install nano

apt install python3
apt install python3-pip -y
pip install flask
pip install psycopg2-binary

# Clone repo and run scripts
sudo apt install git -y  
git clone https://github.com/omriyan01/terraform-fastapi-.git
sudo python3 /var/lib/waagent/custom-script/download/0/terraform-fastapi-/blob/main/Terraform/app/python.py
sudo python3 /var/lib/waagent/custom-script/download/0/terraform-fastapi-/blob/main/Terraform/app/init_db.py
