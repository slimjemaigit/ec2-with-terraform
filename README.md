# ec2-with-terraform
This repository contains terraform script that lunches an AWS EC2 instance to host a web server following these steps:  
1-Create VPC  
2-Create an Internet Gateway  
3-Create Custom Route Table  
4-Create a Subnet  
5-Associate subnet with Route Table  
6-Create Security Group to allow port 22, 80, 443  
7-Create a network interface with an IP in the subnet that was created in step 4  
8-Assign an elastic IP to the network interface created in step 7  
9-Create Ubuntu server and install/enable apache2  
