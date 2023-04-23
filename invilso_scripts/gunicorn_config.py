command = '/usr/bin/gunicorn'
pythonpath = '/root/site/invilso_scripts'
bind = '127.0.0.1:8000'
workers = 9
user = 'root'
limit_request_fields = 32000
limit_request_field_size = 0
raw_env = 'DJANGO_SETTINGS_MODULE=invilso_scripts.settings'
