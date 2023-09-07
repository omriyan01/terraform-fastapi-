#!/bin/bash
apt-get update
apt install postgresql postgresql-contrib -y
# Start and enable the PostgreSQL service
sudo systemctl start postgresql.service

# Set a password for the default PostgreSQL user (postgres)
sudo -u postgres psql -c "CREATE DATABASE omridb;"
sudo -u postgres psql -c "CREATE USER omri PASSWORD 'Hapoe_l6984';"
sudo -u postgres psql -c "GRANT ALL PRIVILEGES ON DATABASE omridb TO omri;"
sudo -u postgres psql
\c omridb
CREATE TABLE clients (id SERIAL PRIMARY KEY, first_name VARCHAR, last_name VARCHAR, role VARCHAR);
INSERT INTO clients (first_name, last_name, role) VALUES ('John', 'Smith', 'CEO');

# Replace '0.0.0.0/0' with your specific IP range or remove/comment this line for local access only
echo "host all all 10.0.0.4/16 md5" | sudo tee -a /etc/postgresql/*/main/pg_hba.conf

# Update listen_addresses to allow all incoming connections
sudo sed -i "s/#listen_addresses = 'localhost'/listen_addresses = '*'/g" /etc/postgresql/*/main/postgresql.conf

# Update port to 5432
 sudo sed -i "s/port = 5434/port = 5432/g" /etc/postgresql/*/main/postgresql.conf

# Reload PostgreSQL for changes to take effect
sudo service postgresql restart



