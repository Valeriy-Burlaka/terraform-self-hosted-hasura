## Helpful Links

- https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/secretsmanager_secret_version
- https://repost.aws/knowledge-center/ecs-cpu-allocation
- https://www.youtube.com/watch?v=yduHaOj3XMg
- https://docs.aws.amazon.com/prescriptive-guidance/latest/secure-sensitive-data-secrets-manager-terraform/using-secrets-manager-and-terraform.html

## Making VPC Public?

Amazon Q-Bot answer:

"""
To make a VPC the default VPC, you can use either the AWS Management Console or AWS CLI.

To do it via the console:

1. Open the Amazon VPC console and go to the "Your VPCs" page [(link)](https://console.aws.amazon.com/vpc/home).

2. Choose "Actions" and then select "Create Default VPC".

3. Click on "Create" to make the selected VPC the new default.

To do it via the CLI:

```
aws ec2 modify-vpc-attribute --vpc-id vpc-123456789 --enable-dns-support --enable-dns-hostnames
```

This will modify the specified VPC to enable DNS support and DNS hostname support, making it a suitable candidate to be the default VPC.

You can then use the `modify-vpc-attribute` command again to set the VPC attribute `isDefault` to true, which will make it the default VPC for that AWS account.

The default VPC is automatically created by AWS when you first provision EC2 instances without specifying a VPC. You can create a new custom VPC and make it the default instead to have more control over the networking settings.
Sources
[1] [How do I create, delete, or restore a default VPC in Amazon VPC?] (https://repost.aws/knowledge-center/deleted-default-vpc)
[2] [Amazon VPC FAQs | What is a default VPC?] (https://aws.amazon.com/vpc/faqs/)
[3] [Managing a default VPC connection for a space - Amazon CodeCatalyst] (https://docs.aws.amazon.com/codecatalyst/latest/adminguide/managing-vpcs.default.html)
"""

aws ec2 modify-vpc-attribute --vpc-id vpc-03e36b2efc53378be --enable-dns-hostnames --enable-dns-support
