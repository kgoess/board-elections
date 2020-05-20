#!/bin/sh

make install
cp cgi-bin/elections.cgi /var/www/cgi-bin/elections.cgi
sudo rsync -avzh  --exclude *.sw? /home/kevin/perl5 /usr/share/httpd/
sudo rsync -avzh  --exclude *.sw? /home/kevin/git/elections/templates/ /var/lib/elections/templates/
sudo rsync -azvh  --exclude *.sw? /home/kevin/git/elections/static/ /var/www/html/elections-static/
sudo systemctl reload httpd.service
