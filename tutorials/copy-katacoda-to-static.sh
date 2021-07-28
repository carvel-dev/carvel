#!/bin/zsh

cat > combo.md << EOF
## Package Management Tutorial

### Get Started With Katacoda
Make a katacoda account and take our interactive tutorial [here](https://katacoda.com/carvel/scenarios/kapp-controller-package-management)
### Or Follow Our Tutorial Below
You can spin up your favorite playground and follow the steps below.
Note the below steps are from the linked katacoda tutorial so your environment may differ slightly.

EOF


for file in `find $(dirname $0)/katacoda/kapp-controller-package-management/*md | grep -v step01 | grep -v intro | sort`; do
    # echo $file | grep -v intro | grep -v finish | sed 's/.*step\([0-9]*\).*/##### Step \1/' >> combo.md
    cat $file | sed 's/{{.*}}//' | sed 's/^## /### /' | sed 's/^# /## /' | >> combo.md
done

