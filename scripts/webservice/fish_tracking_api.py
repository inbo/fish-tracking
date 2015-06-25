from flask import Flask, g, request, url_for
from werkzeug.utils import secure_filename
import sys
import os
import json
from IPython import embed
src_path = os.path.dirname(os.path.dirname(os.path.realpath(__file__)))
sys.path.append(src_path)
from fish_tracking import Aggregator, DataStore


#================
# initial setup
#================
# config
CONNECTION_TYPE = 'local'
DEBUG = True
ALLOWED_EXTENSIONS = {'csv'}
UPLOAD_FOLDER = os.path.dirname(os.path.realpath(__file__)) + '/uploaded_files'
MINUTES_DELTA = 30
# create app
app = Flask(__name__)
app.config.from_object(__name__)


#================
# helper methods
#================
def allowed_file(filename):
    return '.' in filename and filename.rsplit('.', 1)[1] in ALLOWED_EXTENSIONS


#================
# before and teardown
#================
@app.before_request
def before_request():
    g.ds = DataStore(mode=app.config['CONNECTION_TYPE'])
    g.agg = Aggregator()


@app.teardown_request
def teardown_request(exception):
    ds = getattr(g, 'ds', None)
    if ds is not None:
        ds = None


#================
# endpoints
#================
@app.route('/')
def apiDoc():
    """
    <p>Show API documentation</p>
    """
    doc = '<!doctype html>'
    possibles = globals().copy()
    possibles.update(locals())
    for rule in app.url_map.iter_rules():
        try:
            method = possibles.get(rule.endpoint)
            endpoint_title = rule.endpoint.capitalize()
            url = url_for(str(rule.endpoint))
            mdoc = method.__doc__
            doc += '<h2>{0}</h2> <p>url: <a href="{1}">{1}</a></p>{2}\n'.format(endpoint_title, url, mdoc)
        except:
            pass
    return doc

@app.route('/add', methods=['GET', 'POST'])
def add():
    """
    <p>Add new detections. The new detections will be validated and aggregated,
    and stored in the data store.</p>

        <ul>
        <li>GET: get a form where you can upload the new file</li>
        <li>POST: post a file that contains detections.</li>
        </ul>

        <p>Parameters: None</p>
    """
    if request.method == 'POST':
        try:
            f = request.files['file']
        except:
            return 'No data'
        print 'file found'
        if f and allowed_file(f.filename):
            filename = secure_filename(f.filename)
            full_filename = os.path.join(app.config['UPLOAD_FOLDER'], filename)
            f.save(full_filename)
            detections = g.agg.parse_detections(full_filename)
            intervals_df = g.agg.aggregate(detections, minutes_delta=app.config['MINUTES_DELTA'])
            intervals = intervals_df.T
            print intervals
            try:
                g.ds.saveIntervals([intervals[x].to_dict() for x in intervals], app.config['MINUTES_DELTA'])
                print 'intervals saved'
            except RuntimeError, e:
                print 'failed to save intervals'
                print e.message
                return 'Could not load detections in database. Possible duplicate keys.'
            return intervals.to_json()
    return '''
    <!doctype html>
    <title>Upload detections data</title>
    <h1>Upload detections data</h1>
    <form action="" method=post enctype=multipart/form-data>
      <p><input type=file name=file>
         <input type=submit value=Upload>
    </form>
    '''

@app.route('/intervals')
def view():
    """
    <p>view detection intervals for a given transmitter</p>

        <ul>
        <li>GET: get a list of detection intervals for a transmitter</li>
        </ul>

        <p>Parameters: <ul><li>transmitter = transmitter id</li></ul></p>
    """
    transmitterid = request.args.get('transmitter', 'transm2')
    results = g.ds.getTransmitterData(transmitterid)
    return json.dumps(results)

if __name__ == '__main__':
    app.run()
