🗺️ AWS Architecture Connection Flow
The Terraform code sets up a standard three-tier architecture simplified into a single public tier. The primary connection flow is as follows:

1. The Environment (The Container)
VPC (aws_vpc): A logically isolated virtual network (the entire box) with a CIDR range of 10.0.0.0/16.

Public Subnet (aws_subnet): A subsection of the VPC (10.0.1.0/24) where all resources are launched. This subnet is accessible from the internet due to the Internet Gateway.

Internet Gateway (IGW): Allows all traffic originating from the internet (0.0.0.0/0) to route into the public subnet via a route table.

2. The SSH Connection Path (TCP Port 22)
The connection starts with the user's SSH client and terminates at the EC2 instance.

|--------------------|-------------------------------------|----------------------|-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| 1. Client Request  | User's SSH Client                   | Initiates Connection | The user executes the SSH command targeting the NLB's DNS Name on TCP Port 22.                                                                                                            |
| 2. Public Entry    | Network Load Balancer (aws_lb)      | Receives Traffic     | The NLB is listening on the public internet. Because it is a Network Load Balancer, it receives the raw TCP packets.                                                                      |
| 3. Listener Action | NLB Listener (aws_lb_listener)      | Forwards Request     | The listener checks the incoming connection (TCP Port 22) and is configured to forward it to the designated Target Group.                                                                 |
| 4. Routing         | Target Group (aws_lb_target_group)  | Selects Target       | The Target Group, configured for TCP Port 22, checks its registered targets and forwards the packet to any healthy EC2 instance.                                                          |
| 5. Security Check  | Security Group (aws_security_group) | Allows Ingress       | The EC2 instance's Security Group receives the packet. Crucially, because NLB preserves the client's source IP address, the SG must allow Port 22 traffic from the client's public IP (or |
| 6. Target Arrival  | EC2 Instance (aws_instance)         | Handles Connection   | The Ubuntu operating system on the EC2 instance receives the packet on Port 22, verifies the SSH key, and establishes the secure connection.                                              |


In this configuration, the NLB acts as a simple TCP proxy, passing the raw SSH connection directly to the EC2 target without inspecting the content or changing the source IP address.