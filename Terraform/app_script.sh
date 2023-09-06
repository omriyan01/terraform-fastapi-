#!/bin/bash

# Update package lists
sudo apt update

# Install Python 3 and pip
sudo apt install -y python3 python3-pip

# Install Flask using pip
sudo apt install libpq-dev -y
pip3 install fastapi
pip3 install uvicorn
pip3 install psycopg2 

wget -O connect.py https://raw.githubusercontent.com/omriyan01/terraform-fastapi-/main/connect.py
sudo python3 ./connect.py