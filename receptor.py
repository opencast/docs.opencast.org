#!/usr/bin/env python
# -*- coding: utf-8 -*-

from flask import Flask, request
app = Flask(__name__)

REPOSITORY = 'opencast-community/matterhorn'
MSGFILE = 'update'


@app.route("/update", methods=['POST'])
def update():
    content = request.json or {}

    # Check if the request comes from the correct repository
    if content.get('repository', {}).get('full_name') != REPOSITORY:
        return '', 400

    # Check target branch:
    targets = []
    for change in content.get('push', {}).get('changes', []):
        if change.get('new', {}).get('type') != 'branch':
            continue
        cname = change.get('new', {}).get('name')
        if cname == 'develop' or (
                cname.startswith('r/') and not cname.startswith('r/1.')):
            targets.append(cname)

    # Check if we need an update
    if targets:
        with open(MSGFILE, 'w') as f:
            f.write('\n'.join(targets))
        return '', 202

    return '', 204


if __name__ == "__main__":
    app.run(debug=True)
