#!/bin/bash

# Update package lists
sudo apt update
sudo apt install nano

sudo apt install -y python3 python3-pip
pip install flask 
pip psycopg2-binary
 

sudo apt-get update 
sudo apt install git -y  
git clone https://github.com/omriyan01/terraform-fastapi-.git
python3 /var/lib/waagent/custom-script/download/0/terraform-fastapi-/connect.py
