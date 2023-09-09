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
sudo wget -P /home/adminuser https://raw.githubusercontent.com/omriyan01/terraform-fastapi-/main/Terraform/app/python.py
sudo wget -P python.py /home/adminuser https://raw.githubusercontent.com/omriyan01/terraform-fastapi-/main/Terraform/app/python.py
sudo wget -P /home/adminuser https://raw.githubusercontent.com/omriyan01/terraform-fastapi-/main/Terraform/app/init_db.py
sudo wget -P init_db.py https://raw.githubusercontent.com/omriyan01/terraform-fastapi-/main/Terraform/app/init_db.py
sudo mv /var/lib/waagent/custom-script/download/0/python.py /home/adminuser/
wget init_db.py https://raw.githubusercontent.com/omriyan01/terraform-fastapi-/main/Terraform/app/init_db.py
wget index.html https://raw.githubusercontent.com/omriyan01/terraform-fastapi-/main/Terraform/templates/index.html
wget create.html https://raw.githubusercontent.com/omriyan01/terraform-fastapi-/main/Terraform/templates/create.html
wget base.html https://github.com/omriyan01/terraform-fastapi-/blob/main/Terraform/templates/base.html
