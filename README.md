# Install

```
sudo pip install git+https://github.com/cirrascalecloudservices/scripts
```

# Sanity test aws credentials

```
sudo python3 -c "import boto3; boto3.client('sts').get_caller_identity()"
```
