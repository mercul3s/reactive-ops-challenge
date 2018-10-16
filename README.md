## ReactiveOps Tech Challenge Solution

### About the solution
I wrote a terraform script that provisions a security group and aws t2.micro
  instance. The security group restricts ports to only allow web and ssh
  traffic. The t2.micro instance is configured with a `null resource` that
  installs docker, downloads a pre-built webserver container, and then runs the
  docker container. The docker container is configured to build a super simple
  go http application, and then run it on start.

### How to run the sample 
To get up and running, you'll need to clone or fork this repository, and then
install Docker and Terraform. Both have builds available for mac, linux, and
windows:
* [Terraform](https://www.terraform.io/intro/getting-started/install.html)
* [AWS CLI](https://docs.aws.amazon.com/cli/latest/userguide/installing.html)
(or brew install if using a mac)

#### Optional:
* setup environment variables with [direnv](https://direnv.net/) in a `.envrc` file to allow for using multiple aws
accounts, and to avoid typing in your username and keypath for terraform:
```
$ cat .envrc
export AWS_ACCESS_KEY_ID={access key id}
export AWS_SECRET_ACCESS_KEY={secret key id}
export AWS_DEFAULT_REGION=eu-west-1
export TF_VAR_key_path="./me@mercedescoyle.com.pem"
export TF_VAR_user_name=me@mercedescoyle.com
export TF_VAR_region=eu-west-1
```

### AWS configuration:
* create a keypair:
  * `$ aws ec2 create-key-pair --key-name me@mercedescoyle.com --query
'KeyMaterial' --output text > me@mercedescoyle.com.pem`
* create a vpc if you don't already have one setup:
  * `$ aws ec2 create-default-vpc`

### Run the plan
`$ terraform apply --auto-approve`

### Check that the server is running
```
$ curl http://$(terraform state show "aws_instance.webserver" | awk '/^public_ip/ {print $3}')
Hello World!
```
