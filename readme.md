Opencast Documentation Builder
==============================

These scripts are used to automatically build and publish the Opencast
documentation.


### receptor.py

React to BitBucket Webhooks and flag the documentation as to be rebuild.


### build.sh

Check out the repository and build the Opencast documentation if necessary.


Installation
------------

- Configure the message file location in both scripts
- Configure the output directory in `build.sh`
- Start up the `receptor.py`
    - Preferebly use gunicorn
    - Use Nginx as proxy
- Set cronjobs
- Set-up Nginx to deliver output files
