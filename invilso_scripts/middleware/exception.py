import sys
from django.shortcuts import render
import traceback
import logging
logger = logging.getLogger('exception_handler')

class ExceptionMiddleware():
    def __init__(self, get_response):
        self.get_response = get_response

    def __call__(self, request):
        return self.get_response(request)
        
    def process_exception(self, request, exception):
        try:
            _, _, stacktrace = sys.exc_info()
            logger.error("""Processing exception %s at %s.\nGET %s\nTraceback %s""", exception, request.path, request.GET, ''.join(traceback.format_tb(stacktrace)))
            return render(request, 'error.html', {'exception': exception})
        except Exception:
            pass
        return None