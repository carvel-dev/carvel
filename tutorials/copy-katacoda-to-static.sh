#!/bin/zsh

export DESTFILE="$(dirname $0)/../site/content/kapp-controller/docs/latest/packaging-tutorial.md"

cat > $DESTFILE << EOF
---
title: "Tutorial: Create and Install a Package"
---

[//]: # (Generated from katacoda content using 'carvel/tutorials/copy-katacoda-to-static.sh')

## Get Started With Katacoda
Make a katacoda account and take our interactive tutorial [here](https://katacoda.com/carvel/scenarios/kapp-controller-package-management)
## Or Follow Our Tutorial Below
You can spin up your favorite [playground](https://www.katacoda.com/courses/kubernetes/playground) and follow the steps below.
Note the below steps are from the linked katacoda tutorial so your environment may differ slightly.

EOF


for file in `find $(dirname $0)/katacoda/kapp-controller-package-management/*md | grep -v step01 | grep -v intro | sort`; do
    # echo $file | grep -v intro | grep -v finish | sed 's/.*step\([0-9]*\).*/##### Step \1/' >> $DESTFILE
    cat $file | sed 's/{{.*}}//' >> $DESTFILE
done

