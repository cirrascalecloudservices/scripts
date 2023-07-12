# Install

<pre>
sudo apt install git python3-pip
sudo pip3 install git+https://github.com/cirrascalecloudservices/scripts --force-reinstall
</pre>

# Sanity test aws credentials

<pre>
sudo python3 -c "import boto3; print(boto3.client('sts').get_caller_identity())"
</pre>
