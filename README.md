# Install

```
sudo apt install python3-pip
sudo pip install git+https://github.com/cirrascalecloudservices/scripts --force-reinstall
```

# Sanity test aws credentials

```
sudo python3 -c "import boto3; print(boto3.client('sts').get_caller_identity())"
```
