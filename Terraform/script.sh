#!/bin/bash

# Update package lists
sudo apt-get update

# Install PostgreSQL and its dependencies
sudo apt-get install -y postgresql postgresql-contrib

# Start the PostgreSQL service
sudo systemctl start postgresql.service

# Create a PostgreSQL database
sudo -u postgres psql -c "CREATE DATABASE fastapi_db;"

# Create a PostgreSQL user and grant privileges on the database
sudo -u postgres psql -c "CREATE USER omri WITH PASSWORD 'Hapoe_l6984';"
sudo -u postgres psql -c "GRANT ALL PRIVILEGES ON DATABASE fastapi_db TO moshe;"


echo "listen_addresses = '*'" | sudo tee -a /etc/postgresql/*/main/postgresql.conf
echo "host   all    all 10.0.0.4/24     md5" | sudo tee -a /etc/postgresql/*/main/pg_hba.conf
sudo ufw allow 5432/tcp
sudo service postgresql restart

#go into fastapi_db 
sudo -u postgres psql -d fastapi_db




