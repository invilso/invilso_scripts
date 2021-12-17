from files.models import File

def getFile(id):
    return File.objects.get(id=id).file.open()