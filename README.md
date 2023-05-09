# install

```
sudo pip install git+https://github.com/cirrascalecloudservices/scripts
```

# sanity test aws credentials

```
python3 -c "import boto3; boto3.client('sts').get_caller_identity()"
```
