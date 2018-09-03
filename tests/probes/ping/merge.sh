#!/bin/bash
#fulljson=`cat detail.json`
graphs=`cat request.json | jq .graphs`

cat detail.json | jq ". | .graphs += $graphs"

