"""
Django settings for invilso_scripts project.

Generated by 'django-admin startproject' using Django 3.2.7.

For more information on this file, see
https://docs.djangoproject.com/en/3.2/topics/settings/

For the full list of settings and their values, see
https://docs.djangoproject.com/en/3.2/ref/settings/
"""

import logging
from pathlib import Path
import config
import os

# Build paths inside the project like this: BASE_DIR / 'subdir'.
BASE_DIR = Path(__file__).resolve().parent.parent


# Quick-start development settings - unsuitable for production
# See https://docs.djangoproject.com/en/3.2/howto/deployment/checklist/

# SECURITY WARNING: keep the secret key used in production secret!
SECRET_KEY = config.SECRET_KEY

# SECURITY WARNING: don't run with debug turned on in production!
DEBUG = True

ALLOWED_HOSTS = []
MEDIA_ROOT = 'uploads/'
LOGIN_REDIRECT_URL = '/'

LIQPAY_PUBLIC_KEY = config.Payment.PUBLIC_KEY
LIQPAY_PRIVATE_KEY = config.Payment.PRIVATE_KEY

# Application definition

INSTALLED_APPS = [
    'django.contrib.admin',
    'django.contrib.auth',
    'django.contrib.contenttypes',
    'django.contrib.sessions',
    'django.contrib.messages',
    'django.contrib.staticfiles',
    'information',
    'account',
    'comments',
    'messanger',
    'categoryes',
    'photos',
    'files',
    'posts',
    'djoser',
    'rest_framework',
    'rest_framework.authtoken',
    'authentication',
    'main',
    'payments'
]

LOGGING = {
    'version': 1,
    'disable_existing_loggers': False,
    'formatters': {
        'verbose': {
            'format': '{levelname}[{asctime}]: {name} > {funcName} || {message}',
            'style': '{',
        },
        'simple': {
            'format': '{levelname}[{asctime}]: {message}',
            'style': '{',
        },
    },
    'handlers': {
        'console': {
            'level': 'INFO',
            'class': 'logging.StreamHandler',
            'formatter': 'simple'
        },
        'console_dbg': {
            'level': 'DEBUG',
            'class': 'logging.StreamHandler',
            'formatter': 'simple'
        },
        'file_warning': { 
            'level': 'WARNING',
            'class': 'logging.FileHandler',
            'filename': 'logs/warning.log',
            'formatter': 'verbose'
        },
        'file_error': { 
            'level': 'ERROR',
            'class': 'logging.FileHandler',
            'filename': 'logs/error.log',
            'formatter': 'verbose'
        },
        'file': { 
            'level': 'INFO',
            'class': 'logging.FileHandler',
            'filename': 'logs/info.log',
            'formatter': 'simple'
        },
        'mail_admins': {
            'level': 'ERROR',
            'class': 'django.utils.log.AdminEmailHandler',
        }
    },
    'loggers': {
        'django': {
            'handlers': ['console', 'file_warning', 'file', 'file_error'],
            'propagate': True,
        },
        'django.db.backends': {
            'level': 'INFO',
            'handlers': ['console_dbg'],
        },
        'django.request': {
            'handlers': ['console', 'file_warning', 'file', 'file_error'],
            'level': 'ERROR',
            'propagate': False,
        },
        'messanger': {
            'level': 'INFO',
            'handlers': ['console', 'file_warning', 'file', 'file_error']
        },
        'exception_handler': {
            'level': 'INFO',
            'handlers': ['console', 'file_warning', 'file', 'file_error']
        },
        'account': {
            'level': 'WARNING',
            'handlers': ['console', 'file_warning', 'file', 'file_error']
        },
        'authentication': {
            'level': 'INFO',
            'handlers': ['console', 'file_warning', 'file', 'file_error']
        },
        'categoryes': {
            'level': 'WARNING',
            'handlers': ['console', 'file_warning', 'file', 'file_error']
        },
        'comments': {
            'level': 'WARNING',
            'handlers': ['console', 'file_warning', 'file', 'file_error']
        },
        'files': {
            'level': 'WARNING',
            'handlers': ['console', 'file_warning', 'file', 'file_error']
        },
        'main': {
            'level': 'INFO',
            'handlers': ['console', 'file_warning', 'file', 'file_error']
        },
        'photos': {
            'level': 'WARNING',
            'handlers': ['console', 'file_warning', 'file', 'file_error']
        },
        'posts': {
            'level': 'INFO',
            'handlers': ['console', 'file_warning', 'file', 'file_error']
        }
    }
}

REST_FRAMEWORK = {
    'DEFAULT_AUTHENTICATION_CLASSES': [
        'rest_framework_simplejwt.authentication.JWTAuthentication',
        'rest_framework.authentication.TokenAuthentication',
        # 'rest_framework.authentication.SessionAuthentication',
    ]
}

MIDDLEWARE = [
    'django.middleware.security.SecurityMiddleware',
    'django.contrib.sessions.middleware.SessionMiddleware',
    'django.middleware.common.CommonMiddleware',
    'django.middleware.csrf.CsrfViewMiddleware',
    'django.contrib.auth.middleware.AuthenticationMiddleware',
    'django.contrib.messages.middleware.MessageMiddleware',
    'django.middleware.clickjacking.XFrameOptionsMiddleware',
    'invilso_scripts.middleware.exception.ExceptionMiddleware',
]

ROOT_URLCONF = 'invilso_scripts.urls'

TEMPLATES = [
    {
        'BACKEND': 'django.template.backends.django.DjangoTemplates',
        'DIRS': [os.path.join(BASE_DIR, 'templates')],
        'APP_DIRS': True,
        'OPTIONS': {
            'context_processors': [
                'django.template.context_processors.debug',
                'django.template.context_processors.request',
                'django.contrib.auth.context_processors.auth',
                'django.contrib.messages.context_processors.messages',
                'django.template.context_processors.media'
            ],
        },
    },
]

WSGI_APPLICATION = 'invilso_scripts.wsgi.application'


# Database
# https://docs.djangoproject.com/en/3.2/ref/settings/#databases

DATABASES = {
    'default': {
        'ENGINE': config.Database.ENGINE,
        'NAME': config.Database.NAME,
        'USER' : config.Database.USER,
        'PASSWORD' : config.Database.PASSWORD,
        'HOST' : config.Database.HOST,
        'PORT' : config.Database.PORT,
        'ATOMIC_REQUESTS': True
    }
}


# Password validation
# https://docs.djangoproject.com/en/3.2/ref/settings/#auth-password-validators

AUTH_PASSWORD_VALIDATORS = [
    {
        'NAME': 'django.contrib.auth.password_validation.UserAttributeSimilarityValidator',
    },
    {
        'NAME': 'django.contrib.auth.password_validation.MinimumLengthValidator',
    },
    {
        'NAME': 'django.contrib.auth.password_validation.CommonPasswordValidator',
    },
    {
        'NAME': 'django.contrib.auth.password_validation.NumericPasswordValidator',
    },
]


# Internationalization
# https://docs.djangoproject.com/en/3.2/topics/i18n/

LANGUAGE_CODE = 'ru-ru'

TIME_ZONE = 'Europe/Moscow'

USE_I18N = True

USE_L10N = True

USE_TZ = True


# Static files (CSS, JavaScript, Images)
# https://docs.djangoproject.com/en/3.2/howto/static-files/

STATIC_URL = '/static/'

STATICFILES_DIRS = [
    os.path.join(BASE_DIR, "static"),
]

# Default primary key field type
# https://docs.djangoproject.com/en/3.2/ref/settings/#default-auto-field

DEFAULT_AUTO_FIELD = 'django.db.models.BigAutoField'
