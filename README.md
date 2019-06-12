# exist-docker
EXIST(web application for aggregating and analyzing cyber threat intelligence of NICT) for Docker

## Usage
On Host Machine:  
```
$ git clone https://github.com/serverboujin/exist-docker.git
$ cd ./exist-docker
$ sudo docker build -t exist .
$ sudo docker run --name=exist -d -p 8000:8000 --privileged exist /sbin/init
$ sudo docker exec -it exist /bin/bash
```

On EXIST Container:
```
# cd /EXIST
# python3.5 manage.py makemigrations exploit reputation threat threat_hunter twitter twitter_hunter
# python3.5 manage.py migrate
# python3.5 manage.py runserver 0.0.0.0:8000 &
```

Then, Access with your favorite browser to http://{{EXIST container's IP}}:8000

## LICENCE
MIT Licence
