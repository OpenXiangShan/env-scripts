from django.shortcuts import render

from django.http import HttpResponse
from django.template import loader
from django.views.decorators.csrf import csrf_exempt

from . import parser

filename = ""

def index(request):
    template = loader.get_template('index.html')
    return HttpResponse(template.render({}, request))


def debug(request):
    global filename
    template = loader.get_template('debug.html')
    ll = ['ALL', 'DEBUG', 'INFO', 'WARN', 'ERROR']
    ctx = {
        'll' : ll,
        'filename' : filename
    }
    return HttpResponse(template.render(ctx, request))

def readfile(request):
    global filename
    if request.method == "GET":
        filename = request.GET.get("filename")
        modules, start, end = loadLogFile(filename)
        template = loader.get_template('modules.html')
        ctx = {
            'modules': modules,
            'startTime' : start,
            'endTime' : end
        }
        #print(start)
        #print(end)
        return HttpResponse(template.render(ctx, request))
    else:
        return HttpResponse("")


@csrf_exempt
def viewLog(request):
    if request.method == "POST":
        startTime = request.POST.get("startTime")
        endTime = request.POST.get("endTime")
        modules = request.POST.getlist("modules")
        logLevels = request.POST.getlist("lls")

        template = loader.get_template('logs.html')

        logs = getLog(modules, logLevels, int(startTime), int(endTime))

        #print(logs)
        context = {
            'logs': logs
        }
        return HttpResponse(template.render(context, request))
    else:
        return HttpResponse("")


logparser = -1

def loadLogFile(filename):
    global logparser
    logparser = parser.XSLogParser(filename)
    if not logparser.is_good():
        return [], 0, 0
    print(logparser.modules, logparser.cycles)
    return logparser.modules, logparser.cycles[0], logparser.cycles[-1]

def getLog(modules, ll, start, end):
    return logparser.get_logs(start, end, modules, ll)
