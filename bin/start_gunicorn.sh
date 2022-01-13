#!/bin/bash
source /root/site/env/bin/activate
source /root/site/env/bin/postactivate
exec gunicorn  -c "/root/site/invilso_scripts/gunicorn_config.py" invilso_scripts.wsgi
