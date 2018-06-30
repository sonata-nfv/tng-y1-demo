from flask import Flask, Response, request, jsonify
from jinja2 import Environment, FileSystemLoader
from flask_restful import Api, Resource
import json

app = Flask(__name__)
api = Api(app)


@app.route('/', methods=['GET'])
def getfile():
    file = read_haproxy_cfg()
    return Response(file, mimetype='text/plain')

@app.route('/', methods=['POST'])
def post():
    data = str(json.dumps(request.json))
    file = render_haproxy_cfg(data)
    return Response(file, mimetype='text/plain')

def render_haproxy_cfg(services):
    env = Environment(loader=FileSystemLoader('.'), trim_blocks=True)
    templ = env.get_template('haproxy.jinja2.cfg')
    outp = templ.render(services=json.loads(services))
    print("Service:"+services)
    #print("File: "+outp)
    with open('/etc/haproxy/haproxy.cfg', 'w') as f:
        f.write(outp)
    f = open('/etc/haproxy/haproxy.cfg', 'r')
    file = f.read()
    f.close()
    return file


def read_haproxy_cfg():
    f = open('/etc/haproxy/haproxy.cfg', 'r')
    file = f.read()
    f.close()
    return file


if __name__ == '__main__':
    app.run(host='0.0.0.0', debug=True)
